class DropUnusedTables < ActiveRecord::Migration[6.1]
  def up
    remove_column :inventory_pools, :address_id if column_exists?(:inventory_pools, :address_id)
    drop_table :addresses, if_exists: true
    drop_table :numerators, if_exists: true
    drop_table :old_empty_contracts, if_exists: true
    add_foreign_key :api_tokens, :users unless foreign_key_exists?(:api_tokens, :users)
  end

  def down
    remove_foreign_key :api_tokens, :users if foreign_key_exists?(:api_tokens, :users)

    create_table :addresses, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.string :street
      t.string :zip_code
      t.string :city
      t.string :country_code
      t.float :latitude
      t.float :longitude
    end
    add_index :addresses, [:street, :zip_code, :city, :country_code], unique: true, name: :index_addresses_szcc

    create_table :numerators, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.integer :item
    end

    create_table :old_empty_contracts, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.text :compact_id, null: false
      t.text :note
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :old_empty_contracts, :compact_id, unique: true

    add_column :inventory_pools, :address_id, :uuid
    add_foreign_key :inventory_pools, :addresses, column: :address_id unless foreign_key_exists?(:inventory_pools, :addresses, column: :address_id)
  end
end
