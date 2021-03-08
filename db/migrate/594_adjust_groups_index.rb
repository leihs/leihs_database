class AdjustGroupsIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :groups, name: 'idx_group_name'
    add_index :groups, [:name, :organization], unique: true
  end
end
