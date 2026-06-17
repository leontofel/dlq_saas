require "test_helper"

class ProjectsFlowTest < ActionDispatch::IntegrationTest
  fixtures :users, :organizations, :organization_memberships, :projects, :project_api_keys

  test "owner can create a project inside their organization" do
    sign_in_as(users(:owner_user))

    assert_difference("Project.count", 1) do
      post organization_projects_path(organizations(:acme)),
           params: {
             project: {
               name: "Replay Hub",
               slug: "replay-hub",
               environment: "staging",
               status: "active",
               default_retention_days: "15",
               max_payload_size_bytes: "500000",
               default_replay_policy: "manual_allowed",
               allowed_source_identifiers: "replayer\nsettlements"
             }
           },
           headers: modern_browser_headers
    end

    project = Project.find_by!(slug: "replay-hub")

    assert_redirected_to project_path(project)
    assert_equal organizations(:acme), project.organization
    assert_equal %w[replayer settlements], project.allowed_source_identifiers
  end

  test "viewer cannot create a project" do
    sign_in_as(users(:viewer_user))

    assert_no_difference("Project.count") do
      post organization_projects_path(organizations(:acme)),
           params: {
             project: {
               name: "Blocked Project",
               slug: "blocked-project",
               environment: "production",
               status: "active",
               default_retention_days: "30",
               max_payload_size_bytes: "1000",
               default_replay_policy: "manual_allowed"
             }
           },
           headers: modern_browser_headers
    end

    assert_response :forbidden
  end

  test "user cannot access another organizations project" do
    sign_in_as(users(:owner_user))

    get project_path(projects(:beta_dispatch)), headers: modern_browser_headers

    assert_response :not_found
  end

  test "operator can create and revoke a project api key" do
    sign_in_as(users(:operator_user))

    assert_difference("ProjectApiKey.count", 1) do
      post project_project_api_keys_path(projects(:acme_orders)),
           params: {
             project_api_key: {
               name: "Queue writer",
               scopes: [ "messages:write" ]
             }
           },
           headers: modern_browser_headers
    end

    created_key = ProjectApiKey.order(:created_at).last

    assert_redirected_to project_path(projects(:acme_orders))
    follow_redirect!
    assert_response :success
    assert_match "Copy once", response.body
    assert_match "dlq_live_", response.body
    assert_no_match created_key.key_digest, response.body

    patch revoke_project_api_key_path(created_key), headers: modern_browser_headers

    assert_redirected_to project_path(projects(:acme_orders))
    assert created_key.reload.revoked?
  end
end
