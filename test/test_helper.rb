ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end

module BrowserTestHelpers
  MODERN_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36".freeze

  def modern_browser_headers
    { "User-Agent" => MODERN_USER_AGENT }
  end
end

class ActionDispatch::IntegrationTest
  include BrowserTestHelpers

  def sign_in_as(user, password: "password-1234")
    post login_path,
         params: {
           login: {
             email: user.email,
             password: password
           }
         },
         headers: modern_browser_headers
  end
end
