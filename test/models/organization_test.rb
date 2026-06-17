require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  fixtures :users, :organizations, :organization_memberships

  test "visible_to scopes organizations by membership" do
    organizations = Organization.visible_to(users(:owner_user))

    assert_equal [ organizations(:acme) ], organizations.to_a
  end

  test "normalizes slug" do
    organization = Organization.new(name: "Gamma Systems", slug: "Gamma Systems", status: "active")

    assert organization.valid?
    assert_equal "gamma-systems", organization.slug
  end
end
