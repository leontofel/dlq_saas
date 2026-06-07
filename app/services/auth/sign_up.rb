module Auth
  class SignUp < ApplicationService
    Result = Struct.new(
      :success?,
      :user,
      :error,
      keyword_init: true
    )

    def initialize(email:, password:, name:)
      @email = email
      @password = password
      @name = name
    end

    def call
      password_digest = BCrypt::Password.create(@password)

      user = User.create(
        email: normalized_email,
        password_digest: password_digest,
        name: @name,
        status: "active"
      )

      return failure("Error creating user") unless user.persisted?

      Result.new(
        success?: true,
        user: user,
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
