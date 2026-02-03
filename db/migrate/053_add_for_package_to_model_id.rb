class AddForPackageToModelId < ActiveRecord::Migration[7.2]
  def up
    execute "ALTER TABLE fields DISABLE TRIGGER fields_update_check_trigger;"

    execute <<~SQL
      UPDATE fields
      SET data = data || '{"forPackage": true}'::jsonb
      WHERE id = 'model_id';
    SQL

    execute "ALTER TABLE fields ENABLE TRIGGER fields_update_check_trigger;"
  end
end
