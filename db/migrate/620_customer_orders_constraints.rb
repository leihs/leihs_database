class CustomerOrdersConstraints < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION check_customer_orders_user_id_is_same_as_orders_user_id_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (
          NEW.user_id != ( SELECT user_id FROM customer_orders WHERE id = NEW.customer_order_id )
        ) THEN
          RAISE 'User ID of respective customer order differs.';
        END IF;

        RETURN NEW;
      END;
      $$ language 'plpgsql';

      CREATE CONSTRAINT TRIGGER check_customer_orders_user_id_is_same_as_orders_user_id_t
      AFTER INSERT OR UPDATE
      ON orders
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_customer_orders_user_id_is_same_as_orders_user_id_f();
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION check_consistent_user_id_for_all_contained_orders_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF EXISTS (
          SELECT 1
          FROM orders
          WHERE orders.customer_order_id = NEW.id
            AND orders.user_id != NEW.user_id
        ) THEN
          RAISE 'User ID of some of the contained orders differs.';
        END IF;

        RETURN NEW;
      END;
      $$ language 'plpgsql';

      CREATE CONSTRAINT TRIGGER check_consistent_user_id_for_all_contained_orders_t
      AFTER INSERT OR UPDATE
      ON customer_orders
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_consistent_user_id_for_all_contained_orders_f();
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION IF EXISTS check_customer_orders_user_id_is_same_as_orders_user_id_f()
      DROP TRIGGER check_customer_orders_user_id_is_same_as_orders_user_id_t
      DROP FUNCTION IF EXISTS check_consistent_user_id_for_all_contained_orders_f()
      DROP TRIGGER check_consistent_user_id_for_all_contained_orders_t
    SQL
  end
end
