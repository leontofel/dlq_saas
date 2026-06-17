class User < ApplicationRecord
  has_secure_password

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :created_project_api_keys,
           class_name: "ProjectApiKey",
           foreign_key: :created_by_user_id,
           inverse_of: :created_by_user,
           dependent: :restrict_with_exception

  before_validation :normalize_email

  validates :name, presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false }

  validates :password,
            length: { minimum: 12 },
            allow_nil: true

  validates :status,
            inclusion: { in: %w[active disabled] }

  scope :active, -> { where(status: "active") }

  def membership_for(organization)
    organization_memberships.find_by(organization: organization)
  end

  def role_for(organization)
    membership_for(organization)&.role
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
