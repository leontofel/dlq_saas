class OrganizationMembership < ApplicationRecord
  ROLES = %w[viewer operator admin owner].freeze

  belongs_to :organization
  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }

  delegate :name, :email, to: :user, prefix: true

  def at_least?(minimum_role)
    ROLES.index(role) >= ROLES.index(minimum_role.to_s)
  end

  def owner_or_admin?
    at_least?(:admin)
  end
end
