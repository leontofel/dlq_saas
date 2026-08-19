class FailureAttempt < ApplicationRecord
  belongs_to :failed_message

  validates :attempt_number, numericality: { greater_than: 0 }
  validates :failure_type, :failure_message, :occurred_at, presence: true
  validates :attempt_number, uniqueness: { scope: :failed_message_id }
end
