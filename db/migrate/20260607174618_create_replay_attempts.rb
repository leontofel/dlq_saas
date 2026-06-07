class CreateReplayAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :replay_attempts do |t|
      t.references :replay_batch, null: false, foreign_key: true
      t.references :failed_message, null: false, foreign_key: true
      t.references :payload_version, foreign_key: { to_table: :message_payload_versions }
      t.references :destination, null: false, foreign_key: { to_table: :replay_destinations }
      t.string :status, null: false, default: "pending"
      t.integer :http_status_code
      t.text :response_headers_text
      t.text :response_body_truncated
      t.string :error_type
      t.text :error_message
      t.integer :duration_ms
      t.datetime :scheduled_at
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps

      t.index [ :replay_batch_id, :failed_message_id ], unique: true
      t.index [ :replay_batch_id, :status ]
      t.index [ :failed_message_id, :created_at ]
      t.index [ :destination_id, :created_at ]
    end
  end
end
