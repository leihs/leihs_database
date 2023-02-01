class EnsureWorkdaysForInventoryPoolsConstraint < ActiveRecord::Migration[6.1]

  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_inventory_pools_workdays_entry_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT TRUE
          FROM workdays
          WHERE workdays.inventory_pool_id = NEW.id
          )
          THEN RAISE EXCEPTION
            'Inventory pool must have an entry in workdays table.';
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER check_inventory_pools_workdays_entry_t
      AFTER INSERT OR UPDATE
      ON inventory_pools
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_inventory_pools_workdays_entry_f()
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_workdays_entry_for_inventory_pools_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF EXISTS (
          SELECT TRUE
          FROM inventory_pools
          WHERE inventory_pools.id = OLD.inventory_pool_id
          )
          THEN RAISE EXCEPTION
            'Inventory pool must have an entry in workdays table.';
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER check_workdays_entry_for_inventory_pools_t
      AFTER DELETE
      ON workdays
      FOR EACH ROW
      EXECUTE PROCEDURE check_workdays_entry_for_inventory_pools_f()
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS check_inventory_pools_workdays_entry_t ON inventory_pools;
      DROP FUNCTION IF EXISTS check_inventory_pools_workdays_entry_f();
      DROP TRIGGER IF EXISTS check_workdays_entry_for_inventory_pools_t ON workdays;
      DROP FUNCTION IF EXISTS check_workdays_entry_for_inventory_pools_f();
    SQL
  end

end

