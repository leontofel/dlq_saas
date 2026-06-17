require "test_helper"

class OrganizationMembershipTest < ActiveSupport::TestCase
  fixtures :users, :organizations, :organization_memberships

  test "role hierarchy supports minimum checks" do
    assert organization_memberships(:acme_owner).at_least?(:admin)
    assert organization_memberships(:acme_operator).at_least?(:viewer)
    assert_not organization_memberships(:acme_viewer).at_least?(:operator)
  end
end
