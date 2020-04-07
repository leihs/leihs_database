class InventoryPoolWorkdayConstraint < ActiveRecord::Migration[5.0]
  class Workday < ActiveRecord::Base
  end

  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_presence_of_workday_for_inventory_pool()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT true
          FROM workdays
          WHERE inventory_pool_id = NEW.id
        ) THEN
          RAISE EXCEPTION 'An inventory pool must have a workday.';
        END IF;

        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER trigger_check_presence_of_workday_for_inventory_pool
      AFTER INSERT OR UPDATE
      ON inventory_pools
      INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_presence_of_workday_for_inventory_pool()
    SQL

    remove_index :workdays, :inventory_pool_id
    add_index :workdays, :inventory_pool_id, unique: true
  end

  def down
    execute 'DROP TRIGGER trigger_check_presence_of_workday_for_inventory_pool ON inventory_pools'
    execute 'DROP FUNCTION IF EXISTS check_presence_of_workday_for_inventory_pool()'
    remove_index :workdays, :inventory_pool_id
    add_index :workdays, :inventory_pool_id, unique: false
  end
end
