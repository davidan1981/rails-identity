class AddResetTokenToUsers < ActiveRecord::Migration
  def change
    add_column :rails_identity_users, :reset_token, :string
  end
end
