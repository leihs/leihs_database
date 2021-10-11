class CreateCustomerOrdersViewVersion3 < ActiveRecord::Migration[5.0]
  def up
    execute IO.read(
      Pathname(__FILE__).dirname.join("613_create_customer_orders_view_version_3_up.sql")
    )
  end

  def down
    execute 'DROP VIEW unified_customer_orders'
  end
end
