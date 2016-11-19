class RemoveIdFromAllTables < ActiveRecord::Migration[4.2]
  def change
    remove_column :rails_identity_users, :id, :integer
    remove_column :rails_identity_sessions, :id, :integer
  end
end
