class CreateCustomerOrdersForLooseOrders < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  class MigrationOrder < ActiveRecord::Base
    self.table_name = 'orders'
  end

  class MigrationCustomerOrder < ActiveRecord::Base
    self.table_name = 'customer_orders'
  end

  def change
    MigrationOrder.where(customer_order_id: nil).each do |o|
      co = MigrationCustomerOrder.create!(user_id: o.user_id,
                                          purpose: o.purpose,
                                          title: o.purpose,
                                          created_at: o.created_at,
                                          updated_at: o.updated_at)
      o.update!(customer_order_id: co.id)
    end

    change_column(:orders, :customer_order_id, :uuid, null: false)
  end
end
