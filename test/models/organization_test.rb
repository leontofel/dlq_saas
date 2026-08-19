require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "visible_to scopes organizations by membership" do
    tenant = create_tenant
    organizations = Organization.visible_to(tenant.fetch(:user))

    assert_equal [ tenant.fetch(:organization) ], organizations.to_a
  end

  test "normalizes slug" do
    organization = Organization.new(name: "Gamma Systems", slug: "Gamma Systems", status: "active")

    assert organization.valid?
    assert_equal "gamma-systems", organization.slug
  end
end
