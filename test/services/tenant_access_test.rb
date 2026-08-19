require "test_helper"

class TenantAccessTest < ActiveSupport::TestCase
  test "resolves visible project context when the member has the required role" do
    tenant = create_tenant(role: "owner")

    context = TenantAccess.new(user: tenant.fetch(:user)).project(
      tenant.fetch(:project).id,
      minimum_role: :operator
    )

    assert_equal tenant.fetch(:organization), context.organization
    assert_equal tenant.fetch(:project), context.project
    assert_equal "owner", context.membership.role
  end

  test "raises forbidden when the member role is too low" do
    tenant = create_tenant(role: "viewer")

    assert_raises(TenantAccess::Forbidden) do
      TenantAccess.new(user: tenant.fetch(:user)).project(
        tenant.fetch(:project).id,
        minimum_role: :operator
      )
    end
  end

  test "hides projects outside the users organizations" do
    tenant = create_tenant
    outsider = create_user

    assert_raises(ActiveRecord::RecordNotFound) do
      TenantAccess.new(user: outsider).project(tenant.fetch(:project).id)
    end
  end

  test "resolves organization context without a project" do
    tenant = create_tenant(role: "admin")

    context = TenantAccess.new(user: tenant.fetch(:user)).organization(
      tenant.fetch(:organization).id,
      minimum_role: :admin
    )

    assert_equal tenant.fetch(:organization), context.organization
    assert_nil context.project
    assert_equal "admin", context.membership.role
  end
end
