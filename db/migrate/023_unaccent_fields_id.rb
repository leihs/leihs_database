class UnaccentFieldsId < ActiveRecord::Migration[6.1]
  class MigrationField < ActiveRecord::Base
    self.table_name = 'fields'
  end

  class MigrationItem < ActiveRecord::Base
    self.table_name = 'items'
  end

  ALLOWED_ID_REGEX = '^properties_[a-z0-9_]+$'

  def up
    MigrationField.where(dynamic: true).each do |field|
      if field.id !~ /#{ALLOWED_ID_REGEX}/
        _, old_attr = field.data["attribute"]
        new_attr = execute(<<-SQL).first['attr']
          SELECT lower(unaccent('#{old_attr}')) AS attr
        SQL

        old_data = field.data
        new_data = old_data.merge(attribute: ["properties", new_attr])

        new_field = MigrationField.create!(id: "properties_#{new_attr}",
                                           active: field.active,
                                           position: field.position,
                                           data: new_data,
                                           dynamic: true)

        execute(<<-SQL)
            UPDATE disabled_fields
            SET field_id = '#{new_field.id}'
            WHERE field_id = '#{field.id}'
        SQL

        MigrationItem.where("properties->'#{old_attr}' IS NOT NULL").each do |item|
          props = item.properties
          new_props = props.transform_keys { |k| k == old_attr ? new_attr : k }
          item.update!(properties: new_props)
        end

        field.destroy!
      end
    end


    execute <<~SQL
      CREATE OR REPLACE FUNCTION fields_validate_id_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.id !~ '^[a-z_]+$' THEN
          RAISE EXCEPTION 'ID must contain only lowercase letters without accents and underscores';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER fields_validate_id_t
      BEFORE INSERT OR UPDATE ON fields
      FOR EACH ROW EXECUTE FUNCTION fields_validate_id_f();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS fields_validate_id_t ON fields;
      DROP FUNCTION IF EXISTS fields_validate_id_f();
    SQL
  end
end
