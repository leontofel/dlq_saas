class FailedMessage < ApplicationRecord
  belongs_to :project
  belongs_to :source
end
