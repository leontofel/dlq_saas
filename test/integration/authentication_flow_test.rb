require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "anonymous users are redirected to login for the dashboard" do
    get root_path, headers: modern_browser_headers

    assert_redirected_to login_page_path
  end

  test "user can sign up and reach the dashboard" do
    assert_difference("User.count", 1) do
      post signup_path,
           params: {
             sign_up: {
               name: "New Owner",
               email: "new-owner@example.com",
               password: "password-1234"
             }
           },
           headers: modern_browser_headers
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_match "Foundation sprint control room", response.body
  end

  test "user can sign in and sign out" do
    sign_in_as(create_user)

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_match "Signed in successfully.", response.body

    delete logout_path, headers: modern_browser_headers
    assert_redirected_to login_page_path
  end
end
