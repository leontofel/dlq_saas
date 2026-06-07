class CreateAlertDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_deliveries do |t|
      t.references :project, null: false, foreign_key: true
      t.references :alert_rule, null: false, foreign_key: true
      t.references :incident_group, foreign_key: true
      t.references :failed_message, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :attempt_count, null: false, default: 0
      t.text :last_error
      t.datetime :scheduled_at
      t.datetime :delivered_at

      t.timestamps

      t.index [ :project_id, :created_at ]
      t.index [ :incident_group_id, :created_at ]
      t.index [ :alert_rule_id, :status ]
    end
  end
end
