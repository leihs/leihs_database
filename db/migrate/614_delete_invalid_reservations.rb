class DeleteInvalidReservations < ActiveRecord::Migration[5.0]
  def up
    # delete reservations 
    execute <<~SQL
      DELETE FROM reservations
      WHERE model_id IS NULL AND option_id IS NULL AND status NOT IN ('signed', 'closed')
    SQL

    # delete empty orders
    execute <<~SQL
      DELETE FROM orders
      WHERE NOT EXISTS (SELECT TRUE FROM reservations WHERE order_id = orders.id)
    SQL

    # delete empty customer orders
    execute <<~SQL
      DELETE FROM customer_orders
      WHERE NOT EXISTS (
        SELECT TRUE
        FROM orders
        WHERE customer_order_id = customer_orders.id
      )
    SQL
    
    ########################################################################################

    execute <<-SQL
      CREATE OR REPLACE FUNCTION delete_empty_customer_order_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (
          NOT EXISTS (
            SELECT 1
            FROM orders
            WHERE orders.customer_order_id = OLD.customer_order_id
        ))
        THEN
          DELETE FROM customer_orders WHERE customer_orders.id = OLD.customer_order_id;
        END IF;

        RETURN OLD;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER trigger_delete_empty_customer_order_t
      AFTER DELETE ON orders
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE delete_empty_customer_order_f()
    SQL
  end
end
