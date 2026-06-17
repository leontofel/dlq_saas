require "test_helper"

class OrganizationsFlowTest < ActionDispatch::IntegrationTest
  fixtures :users, :organizations, :organization_memberships, :projects

  test "signed in user can create an organization and becomes owner" do
    sign_in_as(users(:viewer_user))

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
    membership = OrganizationMembership.find_by!(organization: organization, user: users(:viewer_user))

    assert_equal "owner", membership.role
    assert_redirected_to organization_path(organization)
  end

  test "admin can add an existing member" do
    sign_in_as(users(:owner_user))

    assert_difference("OrganizationMembership.count", 1) do
      post organization_organization_memberships_path(organizations(:acme)),
           params: {
             organization_membership: {
               email: users(:outsider_user).email,
               role: "viewer"
             }
           },
           headers: modern_browser_headers
    end

    assert_redirected_to organization_path(organizations(:acme))
    assert_equal "viewer", OrganizationMembership.find_by!(organization: organizations(:acme), user: users(:outsider_user)).role
  end

  test "viewer cannot add a member" do
    sign_in_as(users(:viewer_user))

    assert_no_difference("OrganizationMembership.count") do
      post organization_organization_memberships_path(organizations(:acme)),
           params: {
             organization_membership: {
               email: users(:outsider_user).email,
               role: "viewer"
             }
           },
           headers: modern_browser_headers
    end

    assert_response :forbidden
  end
end
