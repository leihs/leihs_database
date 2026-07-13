class AddPickupLocationSettingsToInventoryPools < ActiveRecord::Migration[7.2]
  def up
    add_column :inventory_pools, :transfer_buffer_before_pick_up, :integer
    add_column :inventory_pools, :transfer_buffer_after_drop_off, :integer
    add_column :inventory_pools, :default_pickup_location_name, :text
  end

  def down
    remove_column :inventory_pools, :transfer_buffer_before_pick_up
    remove_column :inventory_pools, :transfer_buffer_after_drop_off
    remove_column :inventory_pools, :default_pickup_location_name
  end
end
