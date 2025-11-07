class PreventPackageInPackage < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL.squish
      CREATE OR REPLACE FUNCTION check_package_not_in_package_f() 
      RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        IF ( ( NEW.parent_id IS NOT NULL ) AND (
          SELECT is_package
          FROM models
          WHERE models.id = NEW.model_id 
        ) = TRUE )
        THEN
          RAISE EXCEPTION 'A package cannot be added to another package';
        ELSIF ( ( NEW.parent_id IS NOT NULL ) AND (
          SELECT is_package
          FROM models
          WHERE models.id = NEW.parent_id
        ) = FALSE )
        THEN
          RAISE EXCEPTION 'Parent item model must be of type package';
        END IF;
        
        RETURN NEW;
      END;
      $$;
    SQL

    execute <<-SQL.squish
      CREATE CONSTRAINT TRIGGER check_package_not_in_package_t
      AFTER INSERT OR UPDATE ON items
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE FUNCTION check_package_not_in_package_f();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS check_package_not_in_package_t ON items;"
    execute "DROP FUNCTION IF EXISTS check_package_not_in_package_f();"
  end
end
