class CreateCustomerOrdersViewVersion5 < ActiveRecord::Migration[5.0]
  def up
    execute IO.read(
      Pathname(__FILE__).dirname.join("619_create_customer_orders_view_version_5_up.sql")
    )
  end
end
