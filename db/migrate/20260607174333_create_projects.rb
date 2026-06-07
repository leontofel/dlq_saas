class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :environment, null: false, default: "production"
      t.string :status, null: false, default: "active"
      t.integer :default_retention_days, null: false, default: 30
      t.integer :max_payload_size_bytes, null: false, default: 262_144
      t.string :default_replay_policy, null: false, default: "manual_allowed"
      t.text :allowed_source_identifiers_text

      t.timestamps

      t.index [ :organization_id, :name ], unique: true
      t.index [ :organization_id, :slug ], unique: true
      t.index [ :organization_id, :status ]
    end
  end
end
