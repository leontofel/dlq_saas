class AuthController < BaseController
 skip_before_action :authenticate_user!, only: [ :sign_up, :login ]

      def login
        result = Auth::Login.call(**login_params)

        if result.success?
          render json: {
            access_token: result.token,
            token_type: "Bearer",
            expires_in: JwtService::EXPIRATION.to_i,
            user: {
              id: result.user.id,
              name: result.user.name,
              email: result.user.email
            }
          }, status: :ok
        else
          render json: {
            error: result.error
          }, status: :unauthorized
        end
      end

      def sign_up
        Auth::SignUp.call(**sign_up_params).then do |result|
          if result.success?
            render json: {
              id: result.user.id,
              name: result.user.name,
              email: result.user.email
            }, status: :created
          else
            render json: {
              error: result.error
            }, status: :unprocessable_entity
          end
        end
      end

      private

      def normalized_email
        params[:email].to_s.strip.downcase
      end

      def login_params
        params
          .expect(login: %i[email password])
          .to_h
          .symbolize_keys
      end

      def sign_up_params
        params
          .expect(sign_up: %i[email password name])
          .to_h
          .symbolize_keys
      end
end
