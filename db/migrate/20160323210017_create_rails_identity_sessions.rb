class CreateRailsIdentitySessions < ActiveRecord::Migrationa[4.2]
  def change
    create_table :rails_identity_sessions do |t|
      t.string :uuid, primary_key: true, null: false
      t.string :user_uuid, null: false
      t.string :token, null: false
      t.string :secret, null: false
      t.string :metadata
      t.timestamps null: false
    end
  end
end
