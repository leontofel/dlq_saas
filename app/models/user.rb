class User < ApplicationRecord
  has_secure_password

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

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end