class AddContactToPools < ActiveRecord::Migration[7.2]
  def change
    add_column :inventory_pools, :contact, :text
  end
end
