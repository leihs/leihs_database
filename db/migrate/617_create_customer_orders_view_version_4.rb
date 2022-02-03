class CreateCustomerOrdersViewVersion4 < ActiveRecord::Migration[5.0]
  def up
    execute IO.read(
      Pathname(__FILE__).dirname.join("617_create_customer_orders_view_version_4_up.sql")
    )
  end
end
