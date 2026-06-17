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
      result = Auth::Authenticate.call(email: @email, password: @password)

      return failure(result.error) unless result.success?

      Result.new(
        success?: true,
        user: result.user,
        token: JwtService.encode(user_id: result.user.id)
      )
    end

    private

    def failure(message)
      Result.new(
        success?: false,
        error: message
      )
    end
  end
end
