class CreateProjectApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :project_api_keys do |t|
      t.references :project, null: false, foreign_key: true
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :key_prefix, null: false
      t.string :key_digest, null: false
      t.text :scopes_text, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps

      t.index [ :project_id, :key_prefix ], unique: true
      t.index [ :project_id, :revoked_at ]
    end
  end
end
