class CancelOrderStuff < ActiveRecord::Migration[5.0]
  def up
    execute IO.read(
      Pathname(__FILE__).dirname.join("609_cancel_order_stuff_up.sql"))
  end

  def down
  end
end
