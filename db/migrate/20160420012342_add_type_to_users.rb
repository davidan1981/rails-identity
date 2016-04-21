class AddTypeToUsers < ActiveRecord::Migration
  def change
    add_column :rails_identity_users, :type, :string

    # Change the type if necessary!
    RailsIdentity::User.update_all(type: "User")
  end
end
