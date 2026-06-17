require "test_helper"

class UserTest < ActiveSupport::TestCase
  fixtures :users

  test "normalizes email before validation" do
    user = User.new(
      email: "  MIXED@Example.COM ",
      password: "password-1234",
      name: "Mixed User",
      status: "active"
    )

    assert user.valid?
    assert_equal "mixed@example.com", user.email
  end

  test "requires a minimum password length" do
    user = User.new(
      email: "short@example.com",
      password: "short",
      name: "Short Password",
      status: "active"
    )

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 12 characters)"
  end
end
