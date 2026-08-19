require "test_helper"

class ApiBaselineTest < ActionDispatch::IntegrationTest
  test "api login returns jwt payload" do
    user = create_user

    post "/api/login",
         params: {
           login: {
             email: user.email,
             password: "password-1234"
           }
         },
         as: :json

    assert_response :success

    payload = JSON.parse(response.body)
    assert payload["access_token"].present?
    assert_equal user.email, payload.dig("user", "email")
  end

  test "ready endpoint returns ok" do
    get "/api/ready", as: :json

    assert_response :success
    assert_equal true, JSON.parse(response.body)["ready"]
  end
end
