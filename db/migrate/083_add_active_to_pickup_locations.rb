class AddActiveToPickupLocations < ActiveRecord::Migration[7.2]
  def up
    add_column :pickup_locations, :active, :boolean, null: false, default: true
  end

  def down
    remove_column :pickup_locations, :active
  end
end
