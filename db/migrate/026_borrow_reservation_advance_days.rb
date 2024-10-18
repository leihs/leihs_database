class BorrowReservationAdvanceDays < ActiveRecord::Migration[7.2]
  def change
    rename_column :inventory_pools, :reservation_advance_days, :borrow_reservation_advance_days
  end
end
