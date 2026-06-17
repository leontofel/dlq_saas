require "test_helper"

class ApiBaselineTest < ActionDispatch::IntegrationTest
  fixtures :users

  test "api login returns jwt payload" do
    post "/api/login",
         params: {
           login: {
             email: users(:owner_user).email,
             password: "password-1234"
           }
         },
         as: :json

    assert_response :success

    payload = JSON.parse(response.body)
    assert payload["access_token"].present?
    assert_equal users(:owner_user).email, payload.dig("user", "email")
  end

  test "ready endpoint returns ok" do
    get "/api/ready", as: :json

    assert_response :success
    assert_equal true, JSON.parse(response.body)["ready"]
  end
end
