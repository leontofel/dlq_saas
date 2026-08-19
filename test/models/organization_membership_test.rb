require "test_helper"

class OrganizationMembershipTest < ActiveSupport::TestCase
  test "role hierarchy supports minimum checks" do
    organization = create_organization
    owner = add_membership(user: create_user, organization: organization, role: "owner")
    operator = add_membership(user: create_user, organization: organization, role: "operator")
    viewer = add_membership(user: create_user, organization: organization, role: "viewer")

    assert owner.at_least?(:admin)
    assert operator.at_least?(:viewer)
    assert_not viewer.at_least?(:operator)
  end
end
