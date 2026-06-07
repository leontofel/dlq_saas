class CreateIncidentGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :incident_groups do |t|
      t.references :project, null: false, foreign_key: true
      t.string :fingerprint, null: false
      t.string :title, null: false
      t.string :status, null: false, default: "open"
      t.string :source_name
      t.string :queue_name
      t.string :event_type
      t.string :failure_type
      t.text :normalized_failure_message
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false
      t.integer :message_count, null: false, default: 0
      t.integer :open_message_count, null: false, default: 0
      t.text :consumer_versions_text

      t.timestamps

      t.index [ :project_id, :fingerprint ], unique: true
      t.index [ :project_id, :status, :last_seen_at ]
      t.index [ :project_id, :queue_name ]
      t.index [ :project_id, :failure_type ]
    end
  end
end
