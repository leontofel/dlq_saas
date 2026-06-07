class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :source_type, null: false, default: "http"
      t.string :environment
      t.text :description
      t.string :status, null: false, default: "active"

      t.timestamps

      t.index [ :project_id, :name ], unique: true
      t.index [ :project_id, :slug ], unique: true
      t.index [ :project_id, :status ]
      t.index [ :project_id, :source_type ]
    end
  end
end
