class InventoryPoolsFields < ActiveRecord::Migration[6.1]
  def up
    create_table :inventory_pools_fields do |t|
      t.references :inventory_pool, null: false, foreign_key: true, on_delete: :cascade
      t.references :field, null: false, foreign_key: true, on_delete: :cascade
      t.boolean :active, null: false, default: false
      add_timestamps :null => false
    end

    # execute <<~SQL
    #   INSERT INTO inventory_pools_fields (inventory_pool_id, field_id, active)
    #   SELECT inventory_pools.id, fields.id, fields.active 
    #   FROM fields, inventory_pools
    # SQL
  end
end
