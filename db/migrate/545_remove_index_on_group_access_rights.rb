class RemoveIndexOnGroupAccessRights < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    remove_index :group_access_rights,  column: [:group_id, :role], unique: true
  end
end
