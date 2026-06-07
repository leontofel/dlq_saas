class CreateOrganizationMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps

      t.index [ :organization_id, :user_id ], unique: true
      t.index [ :organization_id, :role ]
      t.index [ :user_id, :role ]
    end
  end
end
