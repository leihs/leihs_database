class DeleteEmptyOrdersTrigger < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      DELETE FROM orders
      WHERE NOT EXISTS (
        SELECT TRUE
        FROM reservations
        WHERE reservations.order_id = orders.id
      );
    SQL
      
    execute <<~SQL
      DELETE FROM customer_orders co
      WHERE NOT EXISTS (
        SELECT TRUE
        FROM orders o
        WHERE o.customer_order_id = co.id
      );
    SQL

    execute <<~SQL
      DROP TRIGGER IF EXISTS trigger_delete_empty_order ON reservations;

      CREATE CONSTRAINT TRIGGER trigger_delete_empty_order
      AFTER DELETE OR UPDATE
      ON reservations
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE FUNCTION public.delete_empty_order();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS trigger_delete_empty_order ON reservations;
    SQL
  end
end
