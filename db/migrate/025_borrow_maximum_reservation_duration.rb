class BorrowMaximumReservationDuration < ActiveRecord::Migration[7.2]
  def up
    add_column :inventory_pools, :borrow_maximum_reservation_duration, :integer unless column_exists?(:inventory_pools, :borrow_maximum_reservation_duration)
    if column_exists?(:settings, :maximum_reservation_time)
      execute <<~SQL
        UPDATE inventory_pools
        SET borrow_maximum_reservation_duration = settings.maximum_reservation_time
        FROM settings
      SQL
      remove_column :settings, :maximum_reservation_time
    end
  end

  def down
    add_column :settings, :maximum_reservation_time, :integer unless column_exists?(:settings, :maximum_reservation_time)
    if column_exists?(:inventory_pools, :borrow_maximum_reservation_duration)
      execute <<~SQL
        UPDATE settings
        SET maximum_reservation_time = source.borrow_maximum_reservation_duration
        FROM (
          SELECT borrow_maximum_reservation_duration
          FROM inventory_pools
          WHERE borrow_maximum_reservation_duration IS NOT NULL
          ORDER BY id
          LIMIT 1
        ) AS source
        WHERE settings.id = 0
      SQL
      remove_column :inventory_pools, :borrow_maximum_reservation_duration
    end
  end
end
