class MaximumOrderableDuration < ActiveRecord::Migration[7.2]
  def up
    add_column :inventory_pools, :maximum_order_duration_in_days, :integer
    execute <<~SQL
      UPDATE inventory_pools
      SET maximum_order_duration_in_days = settings.maximum_reservation_time
      FROM settings
    SQL
    remove_column :settings, :maximum_reservation_time
  end
end
