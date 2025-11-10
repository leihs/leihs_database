class SetInventoryPoolIdFieldRequired < ActiveRecord::Migration[7.2]
  def up
    execute "ALTER TABLE fields DISABLE TRIGGER fields_update_check_trigger;"

    execute <<~SQL
      UPDATE fields 
      SET data = jsonb_set(data, '{required}', 'true'::jsonb)
      WHERE id = 'inventory_pool_id';
    SQL

    execute "ALTER TABLE fields ENABLE TRIGGER fields_update_check_trigger;"
  end

  def down
    execute "ALTER TABLE fields DISABLE TRIGGER fields_update_check_trigger;"

    execute <<~SQL
      UPDATE fields 
      SET data = jsonb_set(data, '{required}', 'false'::jsonb)
      WHERE id = 'inventory_pool_id';
    SQL

    execute "ALTER TABLE fields ENABLE TRIGGER fields_update_check_trigger;"
  end
end
