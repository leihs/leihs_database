class OrdersForeignKeyConstraints < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      DELETE FROM orders
      WHERE NOT EXISTS (
        SELECT true
        FROM users
        WHERE users.id = orders.user_id
      )
    SQL

    add_foreign_key(:orders, :users)

    execute <<-SQL
      DELETE FROM orders
      WHERE NOT EXISTS (
        SELECT true
        FROM inventory_pools
        WHERE inventory_pools.id = orders.inventory_pool_id
      )
    SQL

    add_foreign_key(:orders, :inventory_pools)
  end
end
