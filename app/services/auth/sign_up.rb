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
      user = User.new(
        email: normalized_email,
        password: @password,
        name: @name,
        status: "active"
      )

      return failure(user.errors.full_messages.to_sentence) unless user.save

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
