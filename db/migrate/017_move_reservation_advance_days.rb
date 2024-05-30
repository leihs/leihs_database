class MoveReservationAdvanceDays < ActiveRecord::Migration[6.1]
  def up
    add_column(:inventory_pools, :reservation_advance_days, :integer, null: false, default: 0)
    execute <<~SQL
      UPDATE inventory_pools
      SET reservation_advance_days = workdays.reservation_advance_days
      FROM workdays
      WHERE inventory_pools.id = workdays.inventory_pool_id;
    SQL
    remove_column(:workdays, :reservation_advance_days)
  end

  def down
    add_column(:workdays, :reservation_advance_days, :integer, null: false, default: 0)
    execute <<~SQL
      UPDATE workdays
      SET reservation_advance_days = inventory_pools.reservation_advance_days
      FROM inventory_pools
      WHERE inventory_pools.id = workdays.inventory_pool_id;
    SQL
    remove_column(:inventory_pools, :reservation_advance_days)
  end
end
