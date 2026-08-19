class Project < ApplicationRecord
  belongs_to :organization
  has_many :project_api_keys, dependent: :destroy
  has_many :failed_messages, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :redaction_rules, dependent: :destroy

  ENVIRONMENTS = %w[production staging development].freeze
  STATUSES = %w[active archived].freeze
  REPLAY_POLICIES = %w[manual_allowed blocked].freeze

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :slug, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :environment, inclusion: { in: ENVIRONMENTS }
  validates :status, inclusion: { in: STATUSES }
  validates :default_replay_policy, inclusion: { in: REPLAY_POLICIES }
  validates :default_retention_days, numericality: { greater_than: 0 }
  validates :max_payload_size_bytes, numericality: { greater_than: 0 }

  before_validation :normalize_slug

  scope :active, -> { where(status: "active") }

  def source_identifier_allowed?(identifier)
    allowed_source_identifiers.empty? || allowed_source_identifiers.include?(identifier.to_s)
  end

  def allowed_source_identifiers
    allowed_source_identifiers_text.to_s.lines.map(&:strip).reject(&:blank?).uniq
  end

  def allowed_source_identifiers=(value)
    identifiers = Array(value)
    identifiers = value.lines if value.is_a?(String)

    self.allowed_source_identifiers_text = identifiers.map(&:to_s).map(&:strip).reject(&:blank?).uniq.join("\n")
  end

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize
  end
end
