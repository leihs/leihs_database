class CreatePickupLocations < ActiveRecord::Migration[7.2]
  include Leihs::MigrationHelper

  def up
    create_table :pickup_locations, id: :uuid do |t|
      t.uuid :inventory_pool_id, null: false
      t.text :name, null: false
      t.text :description
    end

    add_auto_timestamps(:pickup_locations,
      created_at_null: false,
      updated_at_null: false)

    add_foreign_key :pickup_locations, :inventory_pools,
      column: :inventory_pool_id,
      on_delete: :cascade

    add_index :pickup_locations, :inventory_pool_id
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS update_updated_at_column_of_pickup_locations ON pickup_locations;
    SQL

    drop_table :pickup_locations
  end
end
