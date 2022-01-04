class AddOrderStatusFields < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE TYPE order_status_enum AS ENUM (
        'not_procured',
        'in_progress',
        'procured',
        'alternative_procured'
      );
        
      ALTER TABLE procurement_requests
      ADD COLUMN order_status order_status_enum DEFAULT 'not_procured';

      CREATE OR REPLACE FUNCTION ensure_not_noll_order_status_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF ( NEW.order_status IS NULL )
        THEN
          RAISE 'Order status for new or existing procurement requests can''t be null.';
        END IF;

        RETURN NEW;
      END;
      $$ language 'plpgsql';

      CREATE CONSTRAINT TRIGGER ensure_not_noll_order_status_t
      AFTER INSERT OR UPDATE
      ON procurement_requests
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_not_noll_order_status_f();

      -- 

      ALTER TABLE procurement_requests
      ADD COLUMN order_comment text;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE procurement_requests DROP COLUMN order_status;
      DROP TYPE order_status_enum;
      DROP TRIGGER ensure_not_noll_order_status_t ON procurement_requests;
      DROP FUNCTION IF EXISTS ensure_not_noll_order_status_f();
      --
      ALTER TABLE procurement_requests DROP COLUMN order_comment;
    SQL
  end
end
