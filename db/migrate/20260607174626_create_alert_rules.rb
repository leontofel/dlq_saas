class CreateAlertRules < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_rules do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :trigger_type, null: false
      t.text :conditions_text, null: false
      t.string :channel_type, null: false
      t.text :channel_configuration_encrypted, null: false
      t.text :escalation_configuration_text
      t.string :status, null: false, default: "active"

      t.timestamps

      t.index [ :project_id, :name ], unique: true
      t.index [ :project_id, :status ]
      t.index [ :project_id, :trigger_type ]
    end
  end
end
