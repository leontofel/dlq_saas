class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.string :actor_type, null: false
      t.integer :actor_id
      t.string :action, null: false
      t.string :target_type, null: false
      t.integer :target_id
      t.text :metadata_text
      t.string :ip_address
      t.string :user_agent

      t.datetime :created_at, null: false

      t.index [ :project_id, :created_at ]
      t.index [ :organization_id, :created_at ]
      t.index [ :actor_type, :actor_id, :created_at ]
      t.index [ :action, :created_at ]
    end
  end
end
