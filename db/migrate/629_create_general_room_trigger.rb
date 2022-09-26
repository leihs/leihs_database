class CreateGeneralRoomTrigger < ActiveRecord::Migration[5.0]

  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION buildings_on_insert_f()
      RETURNS TRIGGER AS $$
      BEGIN
        INSERT INTO rooms(name, building_id, general)
          VALUES ('general room', NEW.id, TRUE);
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER buildings_on_insert_t
      AFTER INSERT
      ON buildings
      FOR EACH ROW
      EXECUTE PROCEDURE buildings_on_insert_f()
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER buildings_on_insert_t ON buildings;
      DROP FUNCTION buildings_on_insert_f();
    SQL
  end

end
