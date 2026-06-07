class BaseController < ActionController::API
      before_action :authenticate_user!

      attr_reader :current_user

      private

      def authenticate_user!
        payload = JwtService.decode(bearer_token!)
        @current_user = User.find_by!(
          id: payload.fetch("sub"),
          status: "active"
        )
      rescue JWT::DecodeError,
             ActiveRecord::RecordNotFound,
             KeyError
        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def bearer_token!
        scheme, token = request.authorization.to_s.split(" ", 2)

        unless scheme == "Bearer" && token.present?
          raise JWT::DecodeError, "Missing Bearer token"
        end

        token
      end
end
