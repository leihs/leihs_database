class UnaccentFieldsIdPart2 < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION fields_validate_id_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.id !~ '^[a-z0-9_]+$' THEN
          RAISE EXCEPTION 'ID must contain only lowercase letters without accents; numbers or underscores';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end
end
