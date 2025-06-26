class FixMinimumRoleForFieldsDefault < ActiveRecord::Migration[7.2]
  def up
    execute "ALTER TABLE fields DISABLE TRIGGER fields_update_check_trigger;"

    execute <<~SQL
      UPDATE fields 
      SET data = data || '{"permissions": {"role": "lending_manager", "owner": false}}'::jsonb
      WHERE data->'permissions' IS NULL;
    SQL

    execute <<~SQL
      UPDATE fields 
      SET data = jsonb_set(data, '{permissions,owner}', 'true'::jsonb) 
      WHERE data->'permissions'->'owner' = '"true"';
    SQL

    execute <<~SQL
      UPDATE fields 
      SET data = jsonb_set(data, '{permissions,owner}', 'false'::jsonb) 
      WHERE data->'permissions'->'owner' = '"false"';
    SQL

    execute "ALTER TABLE fields ENABLE TRIGGER fields_update_check_trigger;"
  end
end
