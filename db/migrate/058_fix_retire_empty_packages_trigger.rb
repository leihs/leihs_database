class FixRetireEmptyPackagesTrigger < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      DROP TRIGGER IF EXISTS retire_empty_package_t ON items;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION retire_empty_package_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM items WHERE parent_id = OLD.parent_id
        ) THEN
          UPDATE items
          SET retired = COALESCE(retired, CURRENT_DATE),
              retired_reason = CASE
                WHEN retired_reason IS NULL OR retired_reason = '' THEN 'package dissolved'
                ELSE retired_reason
              END
          WHERE id = OLD.parent_id;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      CREATE CONSTRAINT TRIGGER retire_empty_package_t
      AFTER UPDATE OF parent_id ON items
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      WHEN (OLD.parent_id IS NOT NULL AND OLD.parent_id IS DISTINCT FROM NEW.parent_id)
      EXECUTE FUNCTION retire_empty_package_f();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS retire_empty_package_t ON items;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION retire_empty_package_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM items WHERE parent_id = OLD.parent_id
        ) THEN
          UPDATE items
          SET retired = CURRENT_DATE,
              retired_reason = 'package dissolved'
          WHERE id = OLD.parent_id
            AND retired IS NULL;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      CREATE TRIGGER retire_empty_package_t
      AFTER UPDATE OF parent_id ON items
      FOR EACH ROW
      WHEN (OLD.parent_id IS NOT NULL AND OLD.parent_id IS DISTINCT FROM NEW.parent_id)
      EXECUTE FUNCTION retire_empty_package_f();
    SQL
  end
end
