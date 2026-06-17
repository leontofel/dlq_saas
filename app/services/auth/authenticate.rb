module Auth
  class Authenticate < ApplicationService
    Result = Struct.new(
      :success?,
      :user,
      :error,
      keyword_init: true
    )

    def initialize(email:, password:)
      @email = email
      @password = password
    end

    def call
      user = User.authenticate_by(
        email: normalized_email,
        password: @password
      )

      return failure("Invalid email or password") unless user&.status == "active"

      user.update_column(:last_sign_in_at, Time.current)

      Result.new(success?: true, user: user)
    end

    private

    def normalized_email
      @email.to_s.strip.downcase
    end

    def failure(message)
      Result.new(success?: false, error: message)
    end
  end
end
