module Api
  class BaseController < ActionController::API
    before_action :authenticate_identity!

    attr_reader :current_principal

    def current_user
      current_principal&.user
    end

    private

    def authenticate_identity!
      @current_principal = RequestIdentity.resolve(
        credentials: request.authorization,
        adapter: identity_adapter
      )
    rescue RequestIdentity::Unauthorized
      render_error("Unauthorized", :unauthorized)
    end

    def identity_adapter
      RequestIdentity::Adapters::Jwt.new
    end

    def render_error(message, status, details = nil)
      payload = { error: message }
      payload[:details] = details if details.present?

      render json: payload, status: status
    end
  end
end
