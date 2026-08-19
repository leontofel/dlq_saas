module FailedMessages
  class Investigation
    FILTER_COLUMNS = {
      status: :status,
      source_id: :source_id,
      queue_name: :queue_name,
      event_type: :event_type,
      failure_type: :failure_type_latest,
      fingerprint: :fingerprint,
      correlation_id: :correlation_id,
      latest_replay_status: :latest_replay_status
    }.freeze

    Detail = Data.define(:failed_message, :failure_attempts, :message_notes, :message_note)

    def initialize(project:, actor:)
      @project = project
      @actor = actor
    end

    def inbox(filters = {})
      scope = @project.failed_messages.includes(:source).recent_first

      FILTER_COLUMNS.each do |filter, column|
        value = filters[filter]
        scope = scope.where(column => value) if value.present?
      end

      scope = scope.where("last_failed_at >= ?", date_from.beginning_of_day) if (date_from = parsed_date(filters[:date_from]))
      scope = scope.where("last_failed_at <= ?", date_to.end_of_day) if (date_to = parsed_date(filters[:date_to]))
      scope
    end

    def detail(id, message_note: nil)
      failed_message = @project.failed_messages.includes(:source).find(id)

      Detail.new(
        failed_message: failed_message,
        failure_attempts: failed_message.failure_attempts.order(occurred_at: :desc, attempt_number: :desc),
        message_notes: failed_message.message_notes.includes(:author_user).order(created_at: :desc),
        message_note: message_note || failed_message.message_notes.new
      )
    end

    def change_status(id:, status:)
      failed_message = @project.failed_messages.find(id)
      failed_message.update!(status: status)

      detail(id)
    end

    def add_note(id:, body:)
      failed_message = @project.failed_messages.find(id)
      failed_message.message_notes.create!(author_user: @actor, body: body)

      detail(id)
    end

    private

    def parsed_date(value)
      return if value.blank?

      Date.iso8601(value)
    rescue Date::Error
      nil
    end
  end
end
