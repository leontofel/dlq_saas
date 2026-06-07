class CreateRedactionRules < ActiveRecord::Migration[8.1]
  def change
    create_table :redaction_rules do |t|
      t.references :project, null: false, foreign_key: true
      t.string :json_path, null: false
      t.string :replacement, null: false, default: "[REDACTED]"
      t.string :status, null: false, default: "active"

      t.timestamps

      t.index [ :project_id, :json_path ], unique: true
      t.index [ :project_id, :status ]
    end
  end
end
