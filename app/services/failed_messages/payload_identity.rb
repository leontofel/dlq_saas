require "json"
require "openssl"

module FailedMessages
  class PayloadIdentity
    ENV_KEY = "PAYLOAD_IDENTITY_HMAC_KEYS".freeze

    class << self
      def digest(payload)
        key_id, key = keyring.first
        "#{key_id}:#{hmac(key, canonical_json(payload))}"
      end

      def matches?(stored_digest, payload)
        key_id, expected_digest = stored_digest.to_s.split(":", 2)
        key = keyring[key_id]

        if expected_digest.nil?
          key = Rails.application.secret_key_base
          expected_digest = key_id
        end

        return false unless key && expected_digest.present?

        actual_digest = hmac(key, canonical_json(payload))
        ActiveSupport::SecurityUtils.secure_compare(expected_digest, actual_digest)
      end

      private

      def keyring
        configured = ENV[ENV_KEY].presence ||
                     Rails.application.credentials.payload_identity_hmac_keys.presence
        return { "default" => Rails.application.secret_key_base } unless configured

        configured.to_s.split(",").to_h do |entry|
          key_id, key = entry.split("=", 2)
          raise ArgumentError, "#{ENV_KEY} entries must use key_id=secret" if key_id.blank? || key.blank?

          [ key_id, key ]
        end
      end

      def canonical_json(payload)
        JSON.generate(canonicalize(JSON.parse(JSON.generate(payload))))
      end

      def canonicalize(value)
        case value
        when Hash
          value.sort.to_h.transform_values { |child| canonicalize(child) }
        when Array
          value.map { |child| canonicalize(child) }
        else
          value
        end
      end

      def hmac(key, value)
        OpenSSL::HMAC.hexdigest("SHA256", key, value)
      end
    end
  end
end
