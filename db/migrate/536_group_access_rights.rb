class GroupAccessRights < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    create_table :group_access_rights, id: :uuid do |t|
      t.uuid :group_id
      t.index :group_id
      t.uuid :inventory_pool_id
      t.index :inventory_pool_id
      t.index [:inventory_pool_id, :group_id], unique: true
      t.text :role, null: false
      t.index [:group_id, :role], unique: true
    end
    add_foreign_key :group_access_rights, :groups
    add_foreign_key :group_access_rights, :inventory_pools
    add_auto_timestamps :group_access_rights

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          ALTER TABLE group_access_rights
            ADD CONSTRAINT check_allowed_roles
            CHECK (
              role IN ('customer', 'group_manager', 'lending_manager', 'inventory_manager')
            );
        SQL
      end
    end

  end
end
