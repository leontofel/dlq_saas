class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.datetime :last_sign_in_at

      t.timestamps

      t.index :status
    end
  end
end
