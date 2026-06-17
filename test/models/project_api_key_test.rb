require "test_helper"

class ProjectApiKeyTest < ActiveSupport::TestCase
  fixtures :users, :organizations, :organization_memberships, :projects, :project_api_keys

  test "parses scopes from JSON" do
    assert_equal [ "messages:write" ], project_api_keys(:active_orders_key).scopes
  end

  test "digests raw keys deterministically" do
    digest = ProjectApiKey.digest("dlq_live_secret")

    assert_equal digest, ProjectApiKey.digest("dlq_live_secret")
    assert_not_equal digest, ProjectApiKey.digest("dlq_live_other")
  end
end
