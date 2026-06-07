class ReplayAttempt < ApplicationRecord
  belongs_to :replay_batch
  belongs_to :failed_message
end
