class FailedMessage < ApplicationRecord
  belongs_to :project
  belongs_to :source
  belongs_to :incident_group, optional: true
  has_many :failure_attempts, dependent: :destroy
  has_many :message_notes, dependent: :destroy
  has_many :message_payload_versions, dependent: :destroy

  STATUSES = %w[open investigating resolved ignored].freeze

  validates :dedup_identity_key, :queue_name, :event_type, :payload_original_text,
            :payload_size_bytes, :fingerprint, :failure_type_latest,
            :failure_message_latest, :first_failed_at, :last_failed_at, presence: true
  validates :attempt_count, numericality: { greater_than: 0 }
  validates :payload_size_bytes, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(last_failed_at: :desc, id: :desc) }

  def payload_original
    parse_json(payload_original_text)
  end

  def metadata
    parse_json(metadata_text)
  end

  def pretty_payload_original_text
    pretty_json(payload_original_text)
  end

  def pretty_metadata_text
    pretty_json(metadata_text)
  end

  private

  def parse_json(value)
    return if value.blank?

    JSON.parse(value)
  rescue JSON::ParserError
    nil
  end

  def pretty_json(value)
    return if value.blank?

    JSON.pretty_generate(JSON.parse(value))
  rescue JSON::ParserError
    value
  end
end
