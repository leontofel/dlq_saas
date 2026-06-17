class Organization < ApplicationRecord
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :projects, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :status, inclusion: { in: %w[active disabled] }

  before_validation :normalize_slug

  scope :active, -> { where(status: "active") }
  scope :visible_to, lambda { |user|
    joins(:organization_memberships)
      .where(organization_memberships: { user_id: user.id })
      .distinct
  }

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize
  end
end
