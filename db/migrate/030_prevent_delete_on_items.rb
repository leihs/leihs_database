class PreventDeleteOnItems < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      -- Step 1: Create the function
      CREATE OR REPLACE FUNCTION prevent_delete_on_items_f()
      RETURNS TRIGGER AS $$
      BEGIN
      RAISE EXCEPTION 'Deletion is forbidden on the items table. Update retired and retired_reason columns instead.';
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;

      -- Step 2: Create the trigger
      CREATE TRIGGER prevent_delete_on_items_t
      BEFORE DELETE ON items
      FOR EACH ROW
      EXECUTE FUNCTION prevent_delete_on_items_f();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS prevent_delete_on_items_t ON items;
      DROP FUNCTION IF EXISTS prevent_delete_on_items_f();
    SQL
  end
end
