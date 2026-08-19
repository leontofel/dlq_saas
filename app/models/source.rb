class Source < ApplicationRecord
  belongs_to :project
  has_many :failed_messages, dependent: :restrict_with_exception

  SOURCE_TYPES = %w[http].freeze
  STATUSES = %w[active disabled].freeze

  validates :name, presence: true, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :slug, presence: true, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :status, inclusion: { in: STATUSES }

  before_validation :normalize_slug

  scope :active, -> { where(status: "active") }

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize
  end
end
