require "openssl"
require "securerandom"

module ProjectApiKeys
  class Lifecycle
    Issued = Data.define(:project_api_key, :raw_key)

    class << self
      def issue(project:, actor:, name:, scopes:)
        raw_key = "dlq_live_#{SecureRandom.hex(24)}"
        project_api_key = project.project_api_keys.new(
          created_by_user: actor,
          name: name,
          key_prefix: raw_key.first(18),
          key_digest: digest(raw_key)
        )
        project_api_key.scopes = scopes
        project_api_key.save!

        Issued.new(project_api_key:, raw_key:)
      end

      def authenticate(raw_key:, required_scope: nil)
        prefix = raw_key.to_s.first(18)
        return if prefix.blank?

        credential = ProjectApiKey.active.where(key_prefix: prefix).detect do |candidate|
          ActiveSupport::SecurityUtils.secure_compare(candidate.key_digest, digest(raw_key))
        end

        credential if credential && (required_scope.blank? || credential.includes_scope?(required_scope))
      end

      def record_usage(project_api_key)
        project_api_key.update_column(:last_used_at, Time.current)
      end

      def revoke(project_api_key)
        project_api_key.update!(revoked_at: Time.current)
      end

      private

      def digest(raw_key)
        OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw_key)
      end
    end
  end
end
