class AddEnableAlternativePickupLocationsToInventoryPools < ActiveRecord::Migration[7.2]
  def up
    add_column :inventory_pools, :enable_alternative_pickup_locations, :boolean, null: false, default: false
  end

  def down
    remove_column :inventory_pools, :enable_alternative_pickup_locations
  end
end
