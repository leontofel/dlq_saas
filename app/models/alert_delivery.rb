class AlertDelivery < ApplicationRecord
  belongs_to :project
  belongs_to :alert_rule
end
