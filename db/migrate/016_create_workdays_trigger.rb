class CreateWorkdaysTrigger < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      CREATE FUNCTION insert_workdays_for_new_inventory_pool_f() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        INSERT INTO workdays ( inventory_pool_id ) VALUES ( NEW.id );
        RETURN NEW;
      END;
      $$;

      CREATE TRIGGER insert_workdays_for_new_inventory_pool_t
      AFTER INSERT ON inventory_pools
      FOR EACH ROW
      EXECUTE FUNCTION insert_workdays_for_new_inventory_pool_f();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS insert_workdays_for_new_inventory_pool_t ON inventory_pools;
      DROP FUNCTION IF EXISTS insert_workdays_for_new_inventory_pool_f();
    SQL
  end
end
