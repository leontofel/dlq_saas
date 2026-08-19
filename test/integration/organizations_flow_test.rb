require "test_helper"

class OrganizationsFlowTest < ActionDispatch::IntegrationTest
  test "signed in user can create an organization and becomes owner" do
    user = create_user
    sign_in_as(user)

    assert_difference("Organization.count", 1) do
      assert_difference("OrganizationMembership.count", 1) do
        post organizations_path,
             params: {
               organization: {
                 name: "Gamma Systems",
                 slug: "gamma-systems"
               }
             },
             headers: modern_browser_headers
      end
    end

    organization = Organization.find_by!(slug: "gamma-systems")
    membership = OrganizationMembership.find_by!(organization: organization, user: user)

    assert_equal "owner", membership.role
    assert_redirected_to organization_path(organization)
  end

  test "admin can add an existing member" do
    tenant = create_tenant(role: "admin")
    new_member = create_user
    sign_in_as(tenant.fetch(:user))

    assert_difference("OrganizationMembership.count", 1) do
      post organization_organization_memberships_path(tenant.fetch(:organization)),
           params: {
             organization_membership: {
               email: new_member.email,
               role: "viewer"
             }
           },
           headers: modern_browser_headers
    end

    assert_redirected_to organization_path(tenant.fetch(:organization))
    membership = OrganizationMembership.find_by!(organization: tenant.fetch(:organization), user: new_member)
    assert_equal "viewer", membership.role
  end

  test "viewer cannot add a member" do
    tenant = create_tenant(role: "viewer")
    outsider = create_user
    sign_in_as(tenant.fetch(:user))

    assert_no_difference("OrganizationMembership.count") do
      post organization_organization_memberships_path(tenant.fetch(:organization)),
           params: {
             organization_membership: {
               email: outsider.email,
               role: "viewer"
             }
           },
           headers: modern_browser_headers
    end

    assert_response :forbidden
  end
end
