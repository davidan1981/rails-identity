class AddResetTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :rails_identity_users, :reset_token, :string
  end
end
