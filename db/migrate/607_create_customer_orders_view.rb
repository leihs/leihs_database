class CreateCustomerOrdersView < ActiveRecord::Migration[5.0]
  def up
    execute IO.read(
      Pathname(__FILE__).dirname.join("607_create_customer_orders_view_up.sql"))
  end

  def down
    execute 'DROP VIEW unified_customer_orders'
  end
end
