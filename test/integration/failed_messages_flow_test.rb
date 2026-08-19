require "test_helper"

class FailedMessagesFlowTest < ActionDispatch::IntegrationTest
  test "operator can filter inbox, inspect a message, update status, and add a note" do
    tenant = create_tenant(role: "operator")
    project = tenant.fetch(:project)
    source = create_source(project: project, name: "Orders Worker", slug: "orders-worker")
    failed_message = create_failed_message(project: project, source: source)
    create_failure_attempt(failed_message: failed_message)
    create_message_note(
      failed_message: failed_message,
      author: tenant.fetch(:user),
      body: "Investigating downstream retries."
    )
    sign_in_as(tenant.fetch(:user))

    get project_failed_messages_path(project, status: "open", queue_name: "orders"),
        headers: modern_browser_headers

    assert_response :success
    assert_match "Failed message inbox", response.body
    assert_match "Orders Worker", response.body
    assert_no_match "dispatch-service", response.body

    get project_failed_message_path(project, failed_message),
        headers: modern_browser_headers

    assert_response :success
    assert_match "Investigating downstream retries.", response.body
    assert_match "TimeoutError", response.body

    patch status_project_failed_message_path(project, failed_message),
          params: { status: "resolved" },
          headers: modern_browser_headers

    assert_redirected_to project_failed_message_path(project, failed_message)
    assert_equal "resolved", failed_message.reload.status

    assert_difference("MessageNote.count", 1) do
      post project_failed_message_message_notes_path(project, failed_message),
           params: {
             message_note: {
               body: "Fixed after retry budget increase."
             }
           },
           headers: modern_browser_headers
    end

    assert_redirected_to project_failed_message_path(project, failed_message)
  end

  test "outsider cannot access another organizations failed messages" do
    tenant = create_tenant
    outsider = create_user
    sign_in_as(outsider)

    get project_failed_messages_path(tenant.fetch(:project)), headers: modern_browser_headers

    assert_response :not_found
  end

  test "viewer can investigate but cannot change message status" do
    tenant = create_tenant(role: "viewer")
    project = tenant.fetch(:project)
    source = create_source(project: project)
    failed_message = create_failed_message(project: project, source: source)
    sign_in_as(tenant.fetch(:user))

    get project_failed_message_path(project, failed_message), headers: modern_browser_headers
    assert_response :success
    assert_no_match "Add note", response.body

    get project_failed_messages_path(project), headers: modern_browser_headers
    assert_response :success
    assert_no_match "Redaction rules", response.body

    patch status_project_failed_message_path(project, failed_message),
          params: { status: "resolved" },
          headers: modern_browser_headers

    assert_response :forbidden
    assert_equal "open", failed_message.reload.status
  end
end
