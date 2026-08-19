class MessagePayloadVersion < ApplicationRecord
  belongs_to :failed_message
  belongs_to :created_by_user, class_name: "User"

  validates :payload_text, :version_number, presence: true
end
