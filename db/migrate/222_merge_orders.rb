class MergeOrders < ActiveRecord::Migration[5.0]
  class ::MigrationOrder < ActiveRecord::Base
    self.table_name = 'orders'
    has_many(:reservations,
             class_name: 'MigrationReservation',
             foreign_key: 'order_id')
  end

  class ::MigrationReservation < ActiveRecord::Base
    self.table_name = 'reservations'
    self.inheritance_column = nil
    belongs_to :order, class_name: 'MigrationOrder'
  end

  def up
    merged_orders = ::MigrationOrder.find_by_sql <<-SQL
      SELECT user_id,
             inventory_pool_id,
             array_agg(id) AS ids,
             min(created_at) AS created_at_min,
             max(created_at) AS created_at_max,
             max(updated_at) AS updated_at_max
      FROM orders
      GROUP BY user_id,
               inventory_pool_id,
               state,
               purpose,
               created_at
      HAVING count(id) > 1
    SQL

    merged_orders.each do |mo|
      order_to_keep = ::MigrationOrder.find(mo.ids.first)
      order_to_keep.update_attributes!(created_at: mo.created_at_min,
                                       updated_at: mo.updated_at_max)
      ::MigrationReservation
        .where(order_id: mo.ids)
        .update_all(order_id: order_to_keep.id)
      ::MigrationOrder
        .where(id: mo.ids.reject { |id| id == order_to_keep.id })
        .delete_all
    end
  end
end
