class PoolsEmailSignature < ActiveRecord::Migration[7.2]
  def change
    add_column :inventory_pools, :email_signature, :text
  end
end
