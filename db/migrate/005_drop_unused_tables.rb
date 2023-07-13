class DropUnusedTables < ActiveRecord::Migration[6.1]
  def up
    remove_column :inventory_pools, :address_id
    drop_table :addresses
    drop_table :numerators
    drop_table :old_empty_contracts
    add_foreign_key :api_tokens, :users
  end
end
