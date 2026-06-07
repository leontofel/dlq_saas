class CreateIncidentNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :incident_notes do |t|
      t.references :incident_group, null: false, foreign_key: true
      t.references :author_user, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps

      t.index [ :incident_group_id, :created_at ]
      t.index [ :author_user_id, :created_at ]
    end
  end
end
