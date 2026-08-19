require "test_helper"

class ApiFailedMessagesTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create_tenant
    @project = @tenant.fetch(:project)
    create_source(project: @project, name: "Orders Worker", slug: "orders-worker")
    create_source(project: @project, name: "Billing Consumer", slug: "billing-consumer", status: "disabled")
    create_redaction_rule(project: @project)
    create_redaction_rule(project: @project, json_path: "$.items[0].secret", replacement: "[MASKED]")
    @issued_key = issue_project_api_key(project: @project, actor: @tenant.fetch(:user))
  end

  test "ingests a failed message with redaction" do
    assert_difference("FailedMessage.count", 1) do
      assert_difference("FailureAttempt.count", 1) do
        ingest(
          valid_payload(
            dedup_identity_key: "order-999",
            payload: {
              customer: { email: "secret@example.com" },
              items: [ { secret: "token-123", sku: "A1" } ]
            }
          )
        )
      end
    end

    assert_response :created

    failed_message = FailedMessage.order(:id).last
    payload = JSON.parse(failed_message.payload_original_text)

    assert_equal "[FILTERED]", payload.dig("customer", "email")
    assert_equal "[MASKED]", payload.dig("items", 0, "secret")
    assert_equal "open", failed_message.status
    assert_equal 1, failed_message.attempt_count
    assert_equal "us-east-1", failed_message.metadata["region"]
    assert_equal "created", JSON.parse(response.body)["status"]
  end

  test "rejects a revoked api key" do
    revoked = issue_project_api_key(project: @project, actor: @tenant.fetch(:user), name: "Revoked")
    ProjectApiKeys::Lifecycle.revoke(revoked.project_api_key)

    ingest({ source: "orders-worker" }, raw_key: revoked.raw_key)

    assert_response :unauthorized
  end

  test "rejects an unknown source" do
    ingest(valid_payload(source: "missing-source", dedup_identity_key: "order-404"))

    assert_response :unprocessable_entity
    assert_match "Unknown source", response.body
  end

  test "rejects a disabled source" do
    ingest(valid_payload(source: "billing-consumer", dedup_identity_key: "order-405"))

    assert_response :unprocessable_entity
    assert_match "Source is disabled", response.body
  end

  test "rejects a payload that exceeds the project limit" do
    ingest(
      valid_payload(
        dedup_identity_key: "order-too-big",
        payload: { body: "x" * 300_000 }
      )
    )

    assert_response :unprocessable_entity
    assert_match "Payload too large", response.body
  end

  test "adds a new attempt and ignores that attempt when submitted again" do
    identity = "order-retried"
    ingest(valid_payload(dedup_identity_key: identity))
    ingest(
      valid_payload(
        dedup_identity_key: identity,
        attempt_number: 2,
        occurred_at: "2026-07-02T12:00:00Z"
      )
    )

    message = FailedMessage.find_by!(dedup_identity_key: identity)
    assert_equal 2, message.reload.attempt_count

    assert_no_difference([ "FailedMessage.count", "FailureAttempt.count" ]) do
      ingest(
        valid_payload(
          dedup_identity_key: identity,
          attempt_number: 2,
          occurred_at: "2026-07-02T12:00:00Z"
        )
      )
    end

    assert_response :success
    assert_equal "duplicate", JSON.parse(response.body)["status"]
    assert_equal 2, message.reload.attempt_count
  end

  private

  def ingest(payload, raw_key: @issued_key.raw_key)
    post "/api/failed_messages",
         params: { failed_message: payload },
         as: :json,
         headers: { "Authorization" => "Bearer #{raw_key}" }
  end

  def valid_payload(overrides = {})
    {
      source: "orders-worker",
      dedup_identity_key: "order-1000",
      external_message_id: "order-1000",
      idempotency_key: "idem-1000",
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
end
