class RemoveInventoryPoolIdFromEntitlements < ActiveRecord::Migration[5.0]
  def change
    remove_column :entitlements, :inventory_pool_id
  end
end
