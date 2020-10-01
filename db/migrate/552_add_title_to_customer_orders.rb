class AddTitleToCustomerOrders < ActiveRecord::Migration[5.0]
  def change
    add_column(:customer_orders, :title, :text)
    
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE customer_orders SET title = purpose
        SQL

        change_column(:customer_orders, :title, :text, null: false)
      end
    end
  end
end
