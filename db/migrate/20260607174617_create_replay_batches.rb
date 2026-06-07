class CreateReplayBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :replay_batches do |t|
      t.references :project, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: { to_table: :replay_destinations }
      t.references :requested_by_user, null: false, foreign_key: { to_table: :users }
      t.references :approved_by_user, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.integer :requests_per_second, null: false
      t.integer :max_concurrency, null: false
      t.integer :stop_after_failures
      t.integer :stop_after_window_seconds
      t.string :payload_selection_mode, null: false, default: "original"
      t.integer :total_messages, null: false, default: 0
      t.integer :pending_count, null: false, default: 0
      t.integer :success_count, null: false, default: 0
      t.integer :failure_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :paused_at
      t.datetime :completed_at

      t.timestamps

      t.index [ :project_id, :status, :created_at ]
      t.index [ :destination_id, :status ]
      t.index [ :requested_by_user_id, :created_at ]
    end
  end
end
