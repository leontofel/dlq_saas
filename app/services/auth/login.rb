module Auth
  class Login < ApplicationService
    Result = Struct.new(
      :success?,
      :token,
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

      Result.new(
        success?: true,
        user: user,
        token: JwtService.encode(user_id: user.id)
      )
    end

    private

    def normalized_email
      @email.to_s.strip.downcase
    end

    def failure(message)
      Result.new(
        success?: false,
        error: message
      )
    end
  end
end
