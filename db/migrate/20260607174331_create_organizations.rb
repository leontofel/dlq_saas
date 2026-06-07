class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "active"

      t.timestamps

      t.index :name, unique: true
      t.index :slug, unique: true
      t.index :status
    end
  end
end
