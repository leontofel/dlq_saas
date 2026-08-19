require "test_helper"

class ProjectApiKeys::LifecycleTest < ActiveSupport::TestCase
  test "issues, authenticates, records use, and revokes a project API key" do
    tenant = create_tenant

    issued = ProjectApiKeys::Lifecycle.issue(
      project: tenant.fetch(:project),
      actor: tenant.fetch(:user),
      name: "Ingestion",
      scopes: [ "messages:write" ]
    )

    credential = issued.project_api_key

    assert issued.raw_key.start_with?("dlq_live_")
    assert_not_equal issued.raw_key, credential.key_digest
    assert_equal credential,
                 ProjectApiKeys::Lifecycle.authenticate(
                   raw_key: issued.raw_key,
                   required_scope: "messages:write"
                 )

    ProjectApiKeys::Lifecycle.record_usage(credential)
    assert credential.reload.last_used_at.present?

    ProjectApiKeys::Lifecycle.revoke(credential)
    assert credential.reload.revoked?
    assert_nil ProjectApiKeys::Lifecycle.authenticate(
      raw_key: issued.raw_key,
      required_scope: "messages:write"
    )
  end
end
