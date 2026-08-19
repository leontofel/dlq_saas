module Api
  class FailedMessagesController < BaseController
    REQUIRED_SCOPE = "messages:write".freeze

    def create
      result = FailedMessages::Intake.call(
        principal: current_principal,
        submission: FailedMessages::Intake::Submission.from(ingestion_params)
      )

      if result.success?
        render json: {
          id: result.failed_message.id,
          status: response_status(result),
          attempt_count: result.failed_message.attempt_count
        }, status: result.created ? :created : :ok
      else
        render_error(result.error, result.status || :unprocessable_entity, result.details)
      end
    end

    private

    def response_status(result)
      return "created" if result.created
      return "duplicate" if result.duplicate

      "updated"
    end

    def identity_adapter
      RequestIdentity::Adapters::ProjectApiKey.new(required_scope: REQUIRED_SCOPE)
    end

    def ingestion_params
      params.require(:failed_message).to_unsafe_h.symbolize_keys.slice(
        :source,
        :dedup_identity_key,
        :external_message_id,
        :idempotency_key,
        :queue_name,
        :event_type,
        :payload,
        :metadata,
        :failure_type,
        :failure_message,
        :fingerprint,
        :correlation_id,
        :tenant_identifier,
        :consumer_version,
        :stack_trace,
        :attempt_number,
        :occurred_at
      )
    end
  end
end
