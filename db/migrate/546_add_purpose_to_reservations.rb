class AddPurposeToReservations < ActiveRecord::Migration[5.0]
  def change
    add_column :reservations, :line_purpose, :text
  end
end
