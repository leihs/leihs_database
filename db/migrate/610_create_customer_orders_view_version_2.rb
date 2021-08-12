class CreateCustomerOrdersViewVersion2 < ActiveRecord::Migration[5.0]
  def up
    execute IO.read(
      Pathname(__FILE__).dirname.join("610_create_customer_orders_view_version_2_up.sql")
    )
  end

  def down
    execute 'DROP VIEW unified_customer_orders'
  end
end
