class MakePickupLocationSettingsNotNullable < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      UPDATE inventory_pools
        SET default_pickup_location_name = 'Hauptlager'
        WHERE default_pickup_location_name IS NULL;
      UPDATE inventory_pools
        SET transfer_buffer_before_pick_up = 1
        WHERE transfer_buffer_before_pick_up IS NULL;
      UPDATE inventory_pools
        SET transfer_buffer_after_drop_off = 1
        WHERE transfer_buffer_after_drop_off IS NULL;
    SQL

    change_column_default :inventory_pools, :default_pickup_location_name, "Hauptlager"
    change_column_default :inventory_pools, :transfer_buffer_before_pick_up, 1
    change_column_default :inventory_pools, :transfer_buffer_after_drop_off, 1

    change_column_null :inventory_pools, :default_pickup_location_name, false
    change_column_null :inventory_pools, :transfer_buffer_before_pick_up, false
    change_column_null :inventory_pools, :transfer_buffer_after_drop_off, false
  end

  def down
    change_column_null :inventory_pools, :default_pickup_location_name, true
    change_column_null :inventory_pools, :transfer_buffer_before_pick_up, true
    change_column_null :inventory_pools, :transfer_buffer_after_drop_off, true

    change_column_default :inventory_pools, :default_pickup_location_name, nil
    change_column_default :inventory_pools, :transfer_buffer_before_pick_up, nil
    change_column_default :inventory_pools, :transfer_buffer_after_drop_off, nil
  end
end
