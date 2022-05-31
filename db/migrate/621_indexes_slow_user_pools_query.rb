class IndexesSlowUserPoolsQuery < ActiveRecord::Migration[5.0]
  def change
    add_index :reservations, :user_id
    add_index :direct_access_rights, :user_id
  end
end

