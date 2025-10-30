class AddTimestampDefaultsToItems < ActiveRecord::Migration[7.2]
  include Leihs::MigrationHelper

  def up
    change_column(:items, :created_at, "timestamp without time zone", default: -> { "now()" }, null: false)
    change_column(:items, :updated_at, "timestamp without time zone", default: -> { "now()" }, null: false)

    execute <<~SQL
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
         NEW.updated_at = now();
         RETURN NEW;
      END;
      $$ language 'plpgsql';

      CREATE TRIGGER update_updated_at_column_of_items
      BEFORE UPDATE ON items FOR EACH ROW
      WHEN (OLD.* IS DISTINCT FROM NEW.*)
      EXECUTE PROCEDURE update_updated_at_column();
    SQL
  end

  def down
    change_column(:items, :created_at, "timestamp without time zone", null: false)
    change_column(:items, :updated_at, "timestamp without time zone", null: false)

    execute <<~SQL
      DROP TRIGGER IF EXISTS update_updated_at_column_of_items ON items;
    SQL
  end
end
