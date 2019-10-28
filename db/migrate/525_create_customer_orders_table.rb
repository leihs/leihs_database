class CreateCustomerOrdersTable < ActiveRecord::Migration[5.0]
  def change
    create_table(:customer_orders, id: :uuid) do |t|
      t.uuid(:user_id)
      t.text(:purpose, null: false)
      t.timestamps(null: false, default: -> { 'now()' })
    end

    add_foreign_key(:customer_orders, :users)

    add_column(:orders, :customer_order_id, :uuid)

    add_foreign_key(:orders, :customer_orders)

    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION orders_insert_check_function()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (NEW.customer_order_id IS NULL) THEN
          RAISE EXCEPTION 'customer_order_id cannot be null for a new order.';
          RETURN NEW;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER orders_insert_check_function_trigger
      BEFORE INSERT
      ON orders
      FOR EACH ROW
      EXECUTE PROCEDURE orders_insert_check_function();
    SQL
  end
end
