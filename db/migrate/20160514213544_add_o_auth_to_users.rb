class AddOAuthToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :rails_identity_users, :oauth_provider, :string
    add_column :rails_identity_users, :oauth_uid, :string
    add_column :rails_identity_users, :oauth_name, :string
    add_column :rails_identity_users, :oauth_token, :string
    add_column :rails_identity_users, :oauth_expires_at, :string
    add_index :rails_identity_users, [:oauth_provider, :oauth_uid]
  end
end
