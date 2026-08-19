require "digest"
require "json"

module FailedMessages
  class Intake < ApplicationService
    REQUIRED_SCOPE = "messages:write".freeze
    FIELDS = %i[
      source
      dedup_identity_key
      external_message_id
      idempotency_key
      queue_name
      event_type
      payload
      metadata
      failure_type
      failure_message
      fingerprint
      correlation_id
      tenant_identifier
      consumer_version
      stack_trace
      attempt_number
      occurred_at
    ].freeze
    REQUIRED_FIELDS = %i[
      source
      dedup_identity_key
      queue_name
      event_type
      payload
      failure_type
      failure_message
      attempt_number
      occurred_at
    ].freeze

    class PayloadConflict < StandardError; end

    class Submission
      def self.from(attributes)
        new(attributes.to_h.symbolize_keys.slice(*FIELDS))
      end

      def initialize(attributes)
        @attributes = attributes.freeze
      end

      def [](key)
        @attributes[key]
      end
    end

    Result = Struct.new(
      :success?,
      :failed_message,
      :created,
      :duplicate,
      :error,
      :details,
      :status,
      keyword_init: true
    )

    def initialize(principal:, submission:)
      @principal = principal
      @submission = submission
      @project_api_key = principal&.project_api_key
      @project = @project_api_key&.project
    end

    def call
      return failure("Unauthorized", [], :unauthorized) unless authorized?
      return failure("Project is inactive", [ "project must be active" ]) unless @project.status == "active"

      missing_fields = REQUIRED_FIELDS.select { |field| blank_value?(@submission[field]) }
      return failure("Validation failed", missing_fields.map { |field| "#{field} is required" }) if missing_fields.any?

      source = @project.sources.find_by(slug: @submission[:source].to_s.parameterize)
      return failure("Unknown source", [ "source is not configured for this project" ]) if source.blank?
      return failure("Source is disabled", [ "source is disabled" ]) unless source.status == "active"
      unless @project.source_identifier_allowed?(source.slug)
        return failure("Source is not allowed", [ "source is not in the project allowlist" ])
      end

      payload_text = JSON.generate(@submission[:payload])
      return failure("Payload too large", [ "payload exceeds project limit" ]) if payload_text.bytesize > @project.max_payload_size_bytes

      identity_digest = PayloadIdentity.digest(@submission[:payload])
      redacted_payload, redacted_metadata = apply_redaction_rules(
        payload: @submission[:payload],
        metadata: @submission[:metadata]
      )
      redacted_payload_text = canonical_json(redacted_payload)
      redacted_metadata_text = canonical_json(redacted_metadata) if redacted_metadata
      occurred_at = parse_occurred_at
      return failure("Validation failed", [ "occurred_at is invalid" ]) if occurred_at.blank?
      unless attempt_number&.positive?
        return failure("Validation failed", [ "attempt_number must be greater than 0" ])
      end

      persist(source:, identity_digest:, redacted_payload_text:, redacted_metadata_text:, occurred_at:)
    rescue JSON::GeneratorError
      failure("Validation failed", [ "payload must be valid JSON" ])
    rescue ActiveRecord::RecordInvalid => error
      failure("Validation failed", error.record.errors.full_messages)
    rescue PayloadConflict
      failure("Payload conflict", [ "payload differs from the original failed message" ], :conflict)
    end

    private

    def authorized?
      @principal&.type == :project_api_key && @project_api_key&.includes_scope?(REQUIRED_SCOPE)
    end

    def persist(source:, identity_digest:, redacted_payload_text:, redacted_metadata_text:, occurred_at:)
      duplicate_retries = 0

      begin
        created = false
        failed_message = nil
        existing_attempt = false

        FailedMessage.transaction do
          failed_message = @project.failed_messages.lock.find_or_initialize_by(
            source: source,
            dedup_identity_key: @submission[:dedup_identity_key].to_s
          )
          created = failed_message.new_record?

          ensure_payload_matches!(
            failed_message,
            identity_digest,
            redacted_payload_text
          ) unless created

          existing_attempt = failed_message.persisted? &&
                             failed_message.failure_attempts.exists?(attempt_number: attempt_number)

          if created
            assign_original_message(
              failed_message,
              source,
              identity_digest,
              redacted_payload_text,
              redacted_metadata_text,
              occurred_at
            )
            failed_message.save!
          elsif !existing_attempt
            assign_latest_failure(failed_message, occurred_at)
            failed_message.save!
          elsif failed_message.changed?
            failed_message.save!
          end

          save_failure_attempt(failed_message, occurred_at) unless existing_attempt
          ProjectApiKeys::Lifecycle.record_usage(@project_api_key)
        end

        Result.new(
          success?: true,
          failed_message: failed_message,
          created: created,
          duplicate: existing_attempt
        )
      rescue ActiveRecord::RecordNotUnique
        duplicate_retries += 1
        retry if duplicate_retries == 1

        failure("Duplicate conflict", [ "message identity could not be resolved" ], :conflict)
      end
    end

    def assign_original_message(failed_message, source, identity_digest, payload_text, metadata_text, occurred_at)
      failed_message.assign_attributes(
        {
          project: @project,
          source: source,
          external_message_id: @submission[:external_message_id].presence,
          idempotency_key: @submission[:idempotency_key].presence,
          queue_name: @submission[:queue_name].to_s,
          event_type: @submission[:event_type].to_s,
          metadata_text: metadata_text,
          fingerprint: @submission[:fingerprint].presence || default_fingerprint,
          correlation_id: @submission[:correlation_id].presence,
          tenant_identifier: @submission[:tenant_identifier].presence,
          payload_identity_digest: identity_digest,
          payload_original_text: payload_text,
          payload_size_bytes: payload_text.bytesize,
          first_failed_at: occurred_at,
          attempt_count: 1
        }.merge(latest_failure_attributes(occurred_at))
      )
    end

    def assign_latest_failure(failed_message, occurred_at)
      attributes = {
        attempt_count: failed_message.attempt_count + 1,
        first_failed_at: [ failed_message.first_failed_at, occurred_at ].min
      }

      if occurred_at >= failed_message.last_failed_at
        attributes.merge!(latest_failure_attributes(occurred_at))
      end

      failed_message.assign_attributes(attributes)
    end

    def latest_failure_attributes(occurred_at)
      {
        failure_type_latest: @submission[:failure_type].to_s,
        failure_message_latest: @submission[:failure_message].to_s,
        latest_consumer_version: @submission[:consumer_version].presence,
        last_failed_at: occurred_at,
        payload_expires_at: occurred_at + @project.default_retention_days.days,
        status: "open"
      }
    end

    def ensure_payload_matches!(failed_message, identity_digest, redacted_payload_text)
      if failed_message.payload_identity_digest.present?
        matches = PayloadIdentity.matches?(
          failed_message.payload_identity_digest,
          @submission[:payload]
        )
        raise PayloadConflict unless matches
      else
        raise PayloadConflict unless legacy_payload_matches?(failed_message, redacted_payload_text)

        failed_message.payload_identity_digest = identity_digest
      end
    end

    def legacy_payload_matches?(failed_message, redacted_payload_text)
      canonical_json(JSON.parse(failed_message.payload_original_text)) == redacted_payload_text
    rescue JSON::ParserError
      false
    end

    def save_failure_attempt(failed_message, occurred_at)
      failed_message.failure_attempts.create!(
        attempt_number: attempt_number,
        failure_type: @submission[:failure_type].to_s,
        failure_message: @submission[:failure_message].to_s,
        stack_trace_text: @submission[:stack_trace].presence,
        consumer_version: @submission[:consumer_version].presence,
        occurred_at: occurred_at
      )
    end

    def attempt_number
      return @attempt_number if defined?(@attempt_number)

      @attempt_number = Integer(@submission[:attempt_number].to_s, exception: false)
    end

    def parse_occurred_at
      Time.zone.parse(@submission[:occurred_at].to_s)
    rescue ArgumentError
      nil
    end

    def default_fingerprint
      Digest::SHA256.hexdigest([
        @submission[:source],
        @submission[:queue_name],
        @submission[:event_type],
        @submission[:failure_type],
        @submission[:failure_message]
      ].join(":"))
    end

    def blank_value?(value)
      value.respond_to?(:blank?) ? value.blank? : value.nil?
    end

    def failure(message, details, status = :unprocessable_entity)
      Result.new(success?: false, error: message, details: details, status: status)
    end

    def apply_redaction_rules(payload:, metadata:)
      redacted_payload = json_copy(payload)
      redacted_metadata = json_copy(metadata) if metadata

      @project.redaction_rules.active.order(:id).each do |rule|
        target, path = redaction_target(
          redacted_payload: redacted_payload,
          redacted_metadata: redacted_metadata,
          json_path: rule.json_path
        )
        redact_path!(target, path, rule.replacement) if target && path
      end

      [ redacted_payload, redacted_metadata ]
    end

    def json_copy(value)
      JSON.parse(JSON.generate(value))
    end

    def redaction_target(redacted_payload:, redacted_metadata:, json_path:)
      path = json_path.to_s.delete_prefix("$.")

      if path.start_with?("metadata.")
        [ redacted_metadata, path.delete_prefix("metadata.") ]
      elsif path.start_with?("payload.")
        [ redacted_payload, path.delete_prefix("payload.") ]
      else
        [ redacted_payload, path ]
      end
    end

    def canonical_json(value)
      JSON.generate(canonicalize(value))
    end

    def canonicalize(value)
      case value
      when Hash
        value.to_h.transform_keys(&:to_s).sort.to_h.transform_values { |child| canonicalize(child) }
      when Array
        value.map { |child| canonicalize(child) }
      else
        value
      end
    end

    def redact_path!(value, json_path, replacement)
      normalized_path = json_path.to_s.start_with?("$") ? json_path.to_s : "$.#{json_path}"
      tokens = normalized_path.scan(/\.([a-zA-Z0-9_:-]+)|\[(\d+)\]/).flat_map(&:compact)
      return if tokens.empty?

      parent = value
      tokens[0...-1].each do |token|
        parent =
          if parent.is_a?(Array) && token.match?(/\A\d+\z/)
            parent[token.to_i]
          elsif parent.is_a?(Hash)
            parent[token]
          else
            return
          end
        return if parent.nil?
      end

      last_token = tokens.last
      if parent.is_a?(Array) && last_token.match?(/\A\d+\z/)
        index = last_token.to_i
        parent[index] = replacement if index < parent.length
      elsif parent.is_a?(Hash) && parent.key?(last_token)
        parent[last_token] = replacement
      end
    end
  end
end
