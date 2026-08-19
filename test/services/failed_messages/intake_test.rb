require "test_helper"

class FailedMessages::IntakeTest < ActiveSupport::TestCase
  test "returns unauthorized when no principal is provided" do
    result = FailedMessages::Intake.call(
      principal: nil,
      submission: FailedMessages::Intake::Submission.from(ingestion_attributes)
    )

    assert_not result.success?
    assert_equal :unauthorized, result.status
  end

  test "keeps the first redacted payload immutable and rejects a conflicting payload" do
    tenant = create_tenant
    create_source(project: tenant.fetch(:project), name: "Orders Worker", slug: "orders-worker")
    create_redaction_rule(project: tenant.fetch(:project))
    principal = project_key_principal(tenant)

    first = FailedMessages::Intake.call(
      principal: principal,
      submission: FailedMessages::Intake::Submission.from(
        ingestion_attributes(payload: { customer: { email: "first@example.com" } })
      )
    )
    original_payload = first.failed_message.payload_original_text

    conflicting = FailedMessages::Intake.call(
      principal: principal,
      submission: FailedMessages::Intake::Submission.from(
        ingestion_attributes(
          payload: { customer: { email: "second@example.com" }, changed: true },
          attempt_number: 2
        )
      )
    )

    assert first.success?
    assert_not conflicting.success?
    assert_equal :conflict, conflicting.status
    assert_equal original_payload, first.failed_message.reload.payload_original_text
    assert_equal 1, first.failed_message.attempt_count
    assert_equal 1, first.failed_message.failure_attempts.count
  end

  test "accepts the same raw payload after redaction rules change" do
    tenant = create_tenant
    project = tenant.fetch(:project)
    create_source(project: project, name: "Orders Worker", slug: "orders-worker")
    principal = project_key_principal(tenant)
    payload = { customer: { email: "secret@example.com" } }

    first = ingest(principal, payload: payload)
    create_redaction_rule(project: project)
    retried = ingest(principal, payload: payload, attempt_number: 2)

    assert first.success?
    assert retried.success?
    assert_equal 2, retried.failed_message.reload.attempt_count
    assert_equal "secret@example.com", retried.failed_message.payload_original.dig("customer", "email")
  end

  test "redacts metadata and treats reordered JSON objects as the same payload" do
    tenant = create_tenant
    create_source(project: tenant.fetch(:project), name: "Orders Worker", slug: "orders-worker")
    create_redaction_rule(project: tenant.fetch(:project), json_path: "metadata.secret")
    create_redaction_rule(project: tenant.fetch(:project), json_path: "headers.Authorization")
    principal = project_key_principal(tenant)

    first = ingest(
      principal,
      payload: { alpha: 1, beta: 2, headers: { Authorization: "Bearer secret" } },
      metadata: { secret: "metadata-token", region: "us-east-1" }
    )
    retried = ingest(
      principal,
      payload: { headers: { Authorization: "Bearer secret" }, beta: 2, alpha: 1 },
      metadata: nil,
      correlation_id: nil,
      attempt_number: 2
    )

    message = retried.failed_message.reload

    assert first.success?
    assert retried.success?
    assert_equal "[FILTERED]", message.metadata.fetch("secret")
    assert_equal "us-east-1", message.metadata.fetch("region")
    assert_equal "[FILTERED]", message.payload_original.dig("headers", "Authorization")
    assert_equal 2, message.attempt_count
  end

  test "fails closed when a legacy message has no payload identity digest" do
    tenant = create_tenant
    project = tenant.fetch(:project)
    source = create_source(project: project, name: "Orders Worker", slug: "orders-worker")
    message = create_failed_message(
      project: project,
      source: source,
      dedup_identity_key: "order-1000",
      payload_original_text: JSON.generate(expected: true),
      payload_identity_digest: nil
    )

    result = ingest(project_key_principal(tenant), payload: { unrelated: true }, attempt_number: 2)

    assert_not result.success?
    assert_equal :conflict, result.status
    assert_nil message.reload.payload_identity_digest
  end

  test "records a late attempt without replacing the latest failure summary" do
    tenant = create_tenant
    create_source(project: tenant.fetch(:project), name: "Orders Worker", slug: "orders-worker")
    principal = project_key_principal(tenant)

    first = ingest(
      principal,
      attempt_number: 2,
      occurred_at: "2026-07-02T12:00:00Z",
      failure_message: "latest failure"
    )
    late = ingest(
      principal,
      attempt_number: 1,
      occurred_at: "2026-07-01T12:00:00Z",
      failure_message: "late failure"
    )

    message = late.failed_message.reload

    assert first.success?
    assert late.success?
    assert_equal 2, message.attempt_count
    assert_equal Time.zone.parse("2026-07-01T12:00:00Z"), message.first_failed_at
    assert_equal Time.zone.parse("2026-07-02T12:00:00Z"), message.last_failed_at
    assert_equal "latest failure", message.failure_message_latest
  end

  test "rejects inactive projects and disallowed sources" do
    tenant = create_tenant
    project = tenant.fetch(:project)
    create_source(project: project, name: "Orders Worker", slug: "orders-worker")
    principal = project_key_principal(tenant)

    project.update!(status: "archived")
    inactive = ingest(principal)

    project.update!(status: "active", allowed_source_identifiers: [ "billing-worker" ])
    disallowed = ingest(principal)

    assert_not inactive.success?
    assert_equal "Project is inactive", inactive.error
    assert_not disallowed.success?
    assert_equal "Source is not allowed", disallowed.error
  end

  test "returns validation errors for a malformed attempt number" do
    tenant = create_tenant
    create_source(project: tenant.fetch(:project), name: "Orders Worker", slug: "orders-worker")

    result = ingest(project_key_principal(tenant), attempt_number: { invalid: true })

    assert_not result.success?
    assert_includes result.details, "attempt_number must be greater than 0"
  end

  private

  def project_key_principal(tenant)
    issued = ProjectApiKeys::Lifecycle.issue(
      project: tenant.fetch(:project),
      actor: tenant.fetch(:user),
      name: "Ingestion",
      scopes: [ "messages:write" ]
    )

    RequestIdentity::Principal.new(
      type: :project_api_key,
      user: nil,
      project_api_key: issued.project_api_key
    )
  end

  def ingestion_attributes(overrides = {})
    {
      source: "orders-worker",
      dedup_identity_key: "order-1000",
      queue_name: "orders",
      event_type: "order.created",
      payload: { customer: { email: "test@example.com" } },
      metadata: { region: "us-east-1" },
      failure_type: "TimeoutError",
      failure_message: "downstream timed out",
      attempt_number: 1,
      occurred_at: "2026-07-01T12:00:00Z"
    }.merge(overrides)
  end

  def ingest(principal, overrides = {})
    FailedMessages::Intake.call(
      principal: principal,
      submission: FailedMessages::Intake::Submission.from(ingestion_attributes(overrides))
    )
  end
end
