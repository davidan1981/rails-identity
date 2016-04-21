class RemoveIdFromAllTables < ActiveRecord::Migration
  def change
    remove_index :rails_identity_users, :id
    remove_index :rails_identity_sessions, :id
    remove_column :rails_identity_users, :id, :integer
    remove_column :rails_identity_sessions, :id, :integer
  end
end
