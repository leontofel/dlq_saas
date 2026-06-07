class CreateReplayDestinations < ActiveRecord::Migration[8.1]
  def change
    create_table :replay_destinations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :destination_type, null: false, default: "http"
      t.string :url, null: false
      t.string :http_method, null: false, default: "POST"
      t.text :headers_text
      t.string :authentication_type, null: false, default: "none"
      t.text :authentication_secret_encrypted
      t.text :allowed_success_statuses_text
      t.integer :timeout_seconds, null: false, default: 10
      t.integer :max_requests_per_second
      t.string :status, null: false, default: "active"

      t.timestamps

      t.index [ :project_id, :name ], unique: true
      t.index [ :project_id, :status ]
    end
  end
end
