class RemoveUnusedColumnsFromPools < ActiveRecord::Migration[6.1]
  def change
    %w[
      color
      contact_details
      contract_description
      contract_url
      logo_url
      opening_hours
    ].each do |col|
      remove_column :inventory_pools, col
    end
  end
end
