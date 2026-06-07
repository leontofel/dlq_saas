class CreateMessagePayloadVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :message_payload_versions do |t|
      t.references :failed_message, null: false, foreign_key: true
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.integer :version_number, null: false
      t.text :payload_text, null: false
      t.text :change_note

      t.timestamps

      t.index [ :failed_message_id, :version_number ], unique: true
      t.index [ :failed_message_id, :created_at ]
    end
  end
end
