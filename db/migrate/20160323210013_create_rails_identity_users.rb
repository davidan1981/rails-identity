class CreateRailsIdentityUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :rails_identity_users do |t|
      t.string :uuid, primary_key: true, null: false
      t.string :username
      t.string :password_digest
      t.integer :role
      t.string :metadata
      t.datetime :deleted_at, index: true
      t.timestamps null: false
    end
  end
end
