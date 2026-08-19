require "test_helper"

class ProjectApiKeyTest < ActiveSupport::TestCase
  test "parses scopes from JSON" do
    tenant = create_tenant
    issued = issue_project_api_key(project: tenant.fetch(:project), actor: tenant.fetch(:user))

    assert_equal [ "messages:write" ], issued.project_api_key.scopes
  end

  test "authenticates only active keys" do
    tenant = create_tenant
    issued = issue_project_api_key(project: tenant.fetch(:project), actor: tenant.fetch(:user))

    assert_equal issued.project_api_key,
                 ProjectApiKeys::Lifecycle.authenticate(raw_key: issued.raw_key, required_scope: "messages:write")

    ProjectApiKeys::Lifecycle.revoke(issued.project_api_key)

    assert_nil ProjectApiKeys::Lifecycle.authenticate(raw_key: issued.raw_key)
    assert_nil ProjectApiKeys::Lifecycle.authenticate(raw_key: "dlq_live_missing_secret")
  end
end
