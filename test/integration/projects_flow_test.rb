require "test_helper"

class ProjectsFlowTest < ActionDispatch::IntegrationTest
  test "owner can create a project inside their organization" do
    tenant = create_tenant
    sign_in_as(tenant.fetch(:user))

    assert_difference("Project.count", 1) do
      post organization_projects_path(tenant.fetch(:organization)),
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
    assert_equal tenant.fetch(:organization), project.organization
    assert_equal %w[replayer settlements], project.allowed_source_identifiers
  end

  test "viewer cannot create a project" do
    tenant = create_tenant(role: "viewer")
    sign_in_as(tenant.fetch(:user))

    assert_no_difference("Project.count") do
      post organization_projects_path(tenant.fetch(:organization)),
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
    user = create_user
    other_tenant = create_tenant
    sign_in_as(user)

    get project_path(other_tenant.fetch(:project)), headers: modern_browser_headers

    assert_response :not_found
  end

  test "admin can create and revoke a project api key" do
    tenant = create_tenant(role: "admin")
    project = tenant.fetch(:project)
    sign_in_as(tenant.fetch(:user))

    assert_difference("ProjectApiKey.count", 1) do
      post project_project_api_keys_path(project),
           params: {
             project_api_key: {
               name: "Queue writer",
               scopes: [ "messages:write" ]
             }
           },
           headers: modern_browser_headers
    end

    created_key = ProjectApiKey.order(:created_at).last

    assert_redirected_to project_path(project)
    follow_redirect!
    assert_response :success
    assert_match "Copy once", response.body
    assert_match "dlq_live_", response.body
    assert_no_match created_key.key_digest, response.body

    patch revoke_project_project_api_key_path(project, created_key), headers: modern_browser_headers

    assert_redirected_to project_path(project)
    assert created_key.reload.revoked?
  end

  test "operator cannot manage API keys and viewer does not see management controls" do
    operator_tenant = create_tenant(role: "operator")
    sign_in_as(operator_tenant.fetch(:user))

    assert_no_difference("ProjectApiKey.count") do
      post project_project_api_keys_path(operator_tenant.fetch(:project)),
           params: { project_api_key: { name: "Blocked", scopes: [ "messages:write" ] } },
           headers: modern_browser_headers
    end
    assert_response :forbidden

    viewer_tenant = create_tenant(role: "viewer")
    sign_in_as(viewer_tenant.fetch(:user))
    get project_path(viewer_tenant.fetch(:project)), headers: modern_browser_headers

    assert_response :success
    assert_no_match "Create API key", response.body
    assert_no_match "Manage sources", response.body
  end
end
