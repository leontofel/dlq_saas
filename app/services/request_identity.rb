module RequestIdentity
  class Unauthorized < StandardError; end

  Principal = Data.define(:type, :user, :project_api_key)

  def self.resolve(credentials:, adapter:)
    adapter.call(credentials)
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError, KeyError
    raise Unauthorized
  end

  module Adapters
    module BearerToken
      def bearer_token(authorization)
        scheme, token = authorization.to_s.split(" ", 2)
        raise Unauthorized unless scheme == "Bearer" && token.present?

        token
      end
    end

    class Session
      def call(session)
        user_id = session[:user_id] || session["user_id"]
        user = User.active.find(user_id)

        Principal.new(type: :user, user: user, project_api_key: nil)
      end
    end

    class Jwt
      include BearerToken

      def call(authorization)
        payload = JwtService.decode(bearer_token(authorization))
        user = User.active.find(payload.fetch("sub"))

        Principal.new(type: :user, user: user, project_api_key: nil)
      end
    end

    class ProjectApiKey
      include BearerToken

      def initialize(required_scope:)
        @required_scope = required_scope
      end

      def call(authorization)
        project_api_key = ProjectApiKeys::Lifecycle.authenticate(
          raw_key: bearer_token(authorization),
          required_scope: @required_scope
        )
        raise Unauthorized unless project_api_key

        Principal.new(type: :project_api_key, user: nil, project_api_key: project_api_key)
      end
    end
  end
end
