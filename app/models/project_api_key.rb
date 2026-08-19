class ProjectApiKey < ApplicationRecord
  AVAILABLE_SCOPES = %w[messages:write].freeze

  belongs_to :project
  belongs_to :created_by_user,
             class_name: "User",
             inverse_of: :created_project_api_keys

  validates :name, presence: true
  validates :key_prefix, presence: true, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :key_digest, presence: true
  validates :scopes_text, presence: true
  validate :validate_scopes

  scope :active, -> { where(revoked_at: nil) }

  def scopes
    JSON.parse(scopes_text.presence || "[]")
  rescue JSON::ParserError
    []
  end

  def scopes=(value)
    normalized = Array(value).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    self.scopes_text = JSON.generate(normalized)
  end

  def revoked?
    revoked_at.present?
  end

  def includes_scope?(scope)
    scopes.include?(scope.to_s)
  end

  private

  def validate_scopes
    invalid_scopes = scopes - AVAILABLE_SCOPES
    errors.add(:scopes_text, "contains unsupported scopes") if invalid_scopes.any?
  end
end
