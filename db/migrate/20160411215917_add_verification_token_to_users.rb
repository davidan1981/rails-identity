class AddVerificationTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :rails_identity_users, :verification_token, :string
    add_column :rails_identity_users, :verified, :boolean, default: false

    # Assign true for existing accounts since they existed without
    # a verification token.
    users = RailsIdentity::User.update_all(verified: true)
  end
end
