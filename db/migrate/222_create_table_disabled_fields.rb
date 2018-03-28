class CreateTableDisabledFields < ActiveRecord::Migration[5.0]
  def up
    create_table :disabled_fields, id: :uuid do |t|
      t.string :field_id, null: false, foreign_key: true
      t.uuid :inventory_pool_id, null: false, foreign_key: true

      t.index :field_id, unique: false
      t.index :inventory_pool_id, unique: false
      t.index [:field_id, :inventory_pool_id], unique: true
    end
    add_foreign_key(:disabled_fields, :fields, column: 'field_id', on_delete: :cascade)
    add_foreign_key(:disabled_fields, :inventory_pools, column: 'inventory_pool_id', on_delete: :cascade)
  end

  def down
    drop_table :disabled_fields
  end
end
