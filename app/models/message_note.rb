class MessageNote < ApplicationRecord
  belongs_to :failed_message
  belongs_to :author_user, class_name: "User"

  validates :body, presence: true
end
