require "test_helper"

class RequestIdentityTest < ActiveSupport::TestCase
  test "resolves an active user from a session adapter" do
    user = create_user

    principal = RequestIdentity.resolve(
      credentials: { user_id: user.id },
      adapter: RequestIdentity::Adapters::Session.new
    )

    assert_equal :user, principal.type
    assert_equal user, principal.user
    assert_nil principal.project_api_key
  end

  test "resolves an active user from a JWT adapter" do
    user = create_user
    authorization = "Bearer #{JwtService.encode(user_id: user.id)}"

    principal = RequestIdentity.resolve(
      credentials: authorization,
      adapter: RequestIdentity::Adapters::Jwt.new
    )

    assert_equal :user, principal.type
    assert_equal user, principal.user
  end

  test "resolves a scoped project API key from its adapter" do
    tenant = create_tenant
    issued = ProjectApiKeys::Lifecycle.issue(
      project: tenant.fetch(:project),
      actor: tenant.fetch(:user),
      name: "Ingestion",
      scopes: [ "messages:write" ]
    )

    principal = RequestIdentity.resolve(
      credentials: "Bearer #{issued.raw_key}",
      adapter: RequestIdentity::Adapters::ProjectApiKey.new(required_scope: "messages:write")
    )

    assert_equal :project_api_key, principal.type
    assert_nil principal.user
    assert_equal issued.project_api_key, principal.project_api_key
  end

  test "raises unauthorized for invalid credentials" do
    assert_raises(RequestIdentity::Unauthorized) do
      RequestIdentity.resolve(
        credentials: "Bearer invalid",
        adapter: RequestIdentity::Adapters::ProjectApiKey.new(required_scope: "messages:write")
      )
    end
  end
end
