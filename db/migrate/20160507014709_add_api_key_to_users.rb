class AddApiKeyToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :rails_identity_users, :api_key, :string
    add_index :rails_identity_users, :api_key

    RailsIdentity::User.find_each do |user|
      user.update(api_key: SecureRandom.hex(32))
    end
  end
end
