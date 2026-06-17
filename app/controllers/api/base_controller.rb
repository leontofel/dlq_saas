module Api
  class BaseController < ActionController::API
    before_action :authenticate_user!

    attr_reader :current_user

    private

    def authenticate_user!
      payload = JwtService.decode(bearer_token!)
      @current_user = User.active.find(payload.fetch("sub"))
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound, KeyError
      render_error("Unauthorized", :unauthorized)
    end

    def bearer_token!
      scheme, token = request.authorization.to_s.split(" ", 2)

      raise JWT::DecodeError, "Missing Bearer token" unless scheme == "Bearer" && token.present?

      token
    end

    def render_error(message, status, details = nil)
      payload = { error: message }
      payload[:details] = details if details.present?

      render json: payload, status: status
    end
  end
end
