class CreateFailedMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :failed_messages do |t|
      t.references :project, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true
      t.references :incident_group, foreign_key: true
      t.string :external_message_id
      t.string :idempotency_key
      t.string :dedup_identity_key, null: false
      t.string :queue_name, null: false
      t.string :event_type, null: false
      t.string :status, null: false, default: "open"
      t.string :latest_replay_status
      t.text :payload_original_text, null: false
      t.integer :payload_size_bytes, null: false
      t.text :metadata_text
      t.string :fingerprint, null: false
      t.string :failure_type_latest, null: false
      t.text :failure_message_latest, null: false
      t.string :latest_consumer_version
      t.string :correlation_id
      t.string :tenant_identifier
      t.integer :attempt_count, null: false, default: 1
      t.datetime :first_failed_at, null: false
      t.datetime :last_failed_at, null: false
      t.datetime :payload_expires_at

      t.timestamps

      t.index [ :project_id, :source_id, :dedup_identity_key ], unique: true
      t.index [ :project_id, :status, :last_failed_at ]
      t.index [ :project_id, :queue_name ]
      t.index [ :project_id, :event_type ]
      t.index [ :project_id, :fingerprint ]
      t.index [ :project_id, :correlation_id ]
      t.index [ :project_id, :tenant_identifier ]
      t.index [ :project_id, :latest_replay_status ]
      t.index [ :incident_group_id, :status ]
      t.index [ :project_id, :external_message_id ]
    end
  end
end
