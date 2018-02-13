class AddIndexToReservations < ActiveRecord::Migration[5.0]
  def change
    add_index :reservations, :order_id
    add_index :reservations, :user_id
  end
end
