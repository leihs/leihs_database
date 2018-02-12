class FieldsDeleteCheckTrigger < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION field_delete_check_function()
      RETURNS TRIGGER AS $$
      BEGIN

        IF (
          NOT OLD.dynamic
        )
        THEN
          RAISE EXCEPTION 'Cannot delete field which is not editable.';
          RETURN OLD;
        END IF;


        IF (
          EXISTS (
            SELECT 1
            FROM items
            WHERE items.properties::jsonb ? (OLD.data::json#>>'{attribute,1}')
          )
        )
        THEN
          RAISE EXCEPTION 'Cannot delete field which is still in use.';
          RETURN OLD;
        END IF;

        RETURN OLD;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER trigger_field_delete_check_function
      BEFORE DELETE
      ON fields
      FOR EACH ROW
      EXECUTE PROCEDURE field_delete_check_function();
    SQL
  end

  def down
    execute <<-SQL.strip_heredoc
      DROP TRIGGER IF EXISTS trigger_field_delete_check_function ON fields;
      DROP FUNCTION IF EXISTS field_delete_check_function();
    SQL
  end
end
