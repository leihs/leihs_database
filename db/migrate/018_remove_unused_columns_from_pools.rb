class RemoveUnusedColumnsFromPools < ActiveRecord::Migration[6.1]
  def change
    remove_column :inventory_pools, :color, :text
    remove_column :inventory_pools, :contact_details, :string
    remove_column :inventory_pools, :contract_description, :string
    remove_column :inventory_pools, :contract_url, :string
    remove_column :inventory_pools, :logo_url, :string
    remove_column :inventory_pools, :opening_hours, :text
  end
end
