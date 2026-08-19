class RedactionRule < ApplicationRecord
  belongs_to :project

  STATUSES = %w[active disabled].freeze
  JSON_PATH_PATTERN = /\A(?:\$\.)?[a-zA-Z0-9_:-]+(?:\.[a-zA-Z0-9_:-]+|\[\d+\])*\z/

  validates :json_path,
            presence: true,
            uniqueness: { scope: :project_id, case_sensitive: false },
            format: {
              with: JSON_PATH_PATTERN,
              message: "must use dot keys and numeric indexes"
            }
  validates :replacement, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
end
