class AddConstraintsToReservations < ActiveRecord::Migration[5.0]
  def up
    execute 'DROP VIEW visits;'

    change_column(:reservations, :start_date, :date, null: false)
    change_column(:reservations, :end_date, :date, null: false)
    change_column(:reservations, :quantity, :integer, null: false)

    execute IO.read(
      Pathname(__FILE__).dirname.join("215_create_visits_view.sql")
    )
  end

  def down
  end
end
