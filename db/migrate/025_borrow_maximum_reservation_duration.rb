class BorrowMaximumReservationDuration < ActiveRecord::Migration[7.2]
  def up
    add_column :inventory_pools, :borrow_maximum_reservation_duration, :integer
    execute <<~SQL
      UPDATE inventory_pools
      SET borrow_maximum_reservation_duration = settings.maximum_reservation_time
      FROM settings
    SQL
    remove_column :settings, :maximum_reservation_time
  end
end
