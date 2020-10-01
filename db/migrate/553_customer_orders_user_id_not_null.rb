class CustomerOrdersUserIdNotNull < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        change_column(:customer_orders, :user_id, :uuid, null: false)
      end

      dir.down do
        change_column(:customer_orders, :user_id, :uuid, null: true)
      end
    end
  end
end
