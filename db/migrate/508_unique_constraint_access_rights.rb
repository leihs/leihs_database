class UniqueConstraintAccessRights < ActiveRecord::Migration[5.0]
  def up
    add_index(:access_rights,
              [:user_id, :inventory_pool_id, :deleted_at],
              unique: true,
              name: 'index_user_id_inventory_pool_id_deleted_at')
  end

  def down
    remove_index :access_rights, name: 'index_user_id_inventory_pool_id_deleted_at'
  end
end
