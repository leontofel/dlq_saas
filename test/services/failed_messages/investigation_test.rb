require "test_helper"

class FailedMessages::InvestigationTest < ActiveSupport::TestCase
  test "filters a projects inbox and returns recent failures first" do
    tenant = create_tenant(role: "operator")
    source = create_source(project: tenant.fetch(:project), name: "Orders Worker", slug: "orders-worker")
    older = create_failed_message(
      project: tenant.fetch(:project),
      source: source,
      dedup_identity_key: "older",
      failed_at: Time.zone.parse("2026-07-01T12:00:00Z")
    )
    newer = create_failed_message(
      project: tenant.fetch(:project),
      source: source,
      dedup_identity_key: "newer",
      failed_at: Time.zone.parse("2026-07-02T12:00:00Z")
    )
    create_failed_message(
      project: tenant.fetch(:project),
      source: source,
      dedup_identity_key: "ignored",
      queue_name: "billing"
    )

    inbox = FailedMessages::Investigation.new(
      project: tenant.fetch(:project),
      actor: tenant.fetch(:user)
    ).inbox(queue_name: "orders")

    assert_equal [ newer, older ], inbox.to_a
  end

  test "loads coherent detail state with ordered attempts and notes" do
    tenant = create_tenant(role: "operator")
    source = create_source(project: tenant.fetch(:project))
    failed_message = create_failed_message(project: tenant.fetch(:project), source: source)
    first_attempt = create_failure_attempt(failed_message: failed_message, attempt_number: 1)
    second_attempt = create_failure_attempt(
      failed_message: failed_message,
      attempt_number: 2,
      occurred_at: failed_message.last_failed_at + 1.minute
    )
    note = create_message_note(failed_message: failed_message, author: tenant.fetch(:user))

    detail = FailedMessages::Investigation.new(
      project: tenant.fetch(:project),
      actor: tenant.fetch(:user)
    ).detail(failed_message.id)

    assert_equal failed_message, detail.failed_message
    assert_equal [ second_attempt, first_attempt ], detail.failure_attempts.to_a
    assert_equal [ note ], detail.message_notes.to_a
    assert detail.message_note.new_record?
  end

  test "changes status and attributes a note through the investigation interface" do
    tenant = create_tenant(role: "operator")
    source = create_source(project: tenant.fetch(:project))
    failed_message = create_failed_message(project: tenant.fetch(:project), source: source)
    investigation = FailedMessages::Investigation.new(
      project: tenant.fetch(:project),
      actor: tenant.fetch(:user)
    )

    investigation.change_status(id: failed_message.id, status: "resolved")
    detail = investigation.add_note(id: failed_message.id, body: "Recovered downstream.")

    assert_equal "resolved", failed_message.reload.status
    assert_equal "Recovered downstream.", detail.message_notes.first.body
    assert_equal tenant.fetch(:user), detail.message_notes.first.author_user
  end
end
