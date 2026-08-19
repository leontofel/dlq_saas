module DlqScenario
  DEFAULT_PASSWORD = "password-1234"

  def create_user(email: unique_email("user"), name: "Scenario User", status: "active")
    User.create!(email: email, password: DEFAULT_PASSWORD, name: name, status: status)
  end

  def create_organization(name: unique_name("Organization"), slug: nil, status: "active")
    Organization.create!(name: name, slug: slug || name.parameterize, status: status)
  end

  def add_membership(user:, organization:, role: "owner")
    OrganizationMembership.create!(user: user, organization: organization, role: role)
  end

  def create_project(organization:, name: unique_name("Project"), slug: nil, **overrides)
    Project.create!({
      organization: organization,
      name: name,
      slug: slug || name.parameterize,
      environment: "production",
      status: "active",
      default_retention_days: 30,
      max_payload_size_bytes: 262_144,
      default_replay_policy: "manual_allowed"
    }.merge(overrides))
  end

  def create_source(project:, name: unique_name("Source"), slug: nil, **overrides)
    Source.create!({
      project: project,
      name: name,
      slug: slug || name.parameterize,
      source_type: "http",
      environment: project.environment,
      status: "active"
    }.merge(overrides))
  end

  def create_redaction_rule(project:, json_path: "$.customer.email", replacement: "[FILTERED]", **overrides)
    RedactionRule.create!({
      project: project,
      json_path: json_path,
      replacement: replacement,
      status: "active"
    }.merge(overrides))
  end

  def issue_project_api_key(project:, actor:, name: "Ingestion", scopes: [ "messages:write" ])
    ProjectApiKeys::Lifecycle.issue(project: project, actor: actor, name: name, scopes: scopes)
  end

  def create_failed_message(project:, source:, dedup_identity_key: SecureRandom.uuid, **overrides)
    failed_at = overrides.delete(:failed_at) || Time.zone.parse("2026-07-01T12:00:00Z")
    payload_text = overrides.delete(:payload_original_text) || JSON.generate(order_id: dedup_identity_key)

    FailedMessage.create!({
      project: project,
      source: source,
      dedup_identity_key: dedup_identity_key,
      queue_name: "orders",
      event_type: "order.created",
      payload_original_text: payload_text,
      payload_size_bytes: payload_text.bytesize,
      fingerprint: "timeout-fingerprint",
      failure_type_latest: "TimeoutError",
      failure_message_latest: "downstream timed out",
      first_failed_at: failed_at,
      last_failed_at: failed_at,
      attempt_count: 1,
      status: "open"
    }.merge(overrides))
  end

  def create_failure_attempt(failed_message:, attempt_number: 1, **overrides)
    FailureAttempt.create!({
      failed_message: failed_message,
      attempt_number: attempt_number,
      failure_type: failed_message.failure_type_latest,
      failure_message: failed_message.failure_message_latest,
      occurred_at: failed_message.last_failed_at
    }.merge(overrides))
  end

  def create_message_note(failed_message:, author:, body: "Investigating failure.")
    MessageNote.create!(failed_message: failed_message, author_user: author, body: body)
  end

  def create_tenant(role: "owner")
    user = create_user
    organization = create_organization
    add_membership(user: user, organization: organization, role: role)
    project = create_project(organization: organization)

    { user: user, organization: organization, project: project }
  end

  private

  def unique_email(prefix)
    "#{prefix}-#{SecureRandom.hex(6)}@example.com"
  end

  def unique_name(prefix)
    "#{prefix} #{SecureRandom.hex(6)}"
  end
end

class ActiveSupport::TestCase
  include DlqScenario
end
