class AddIndexGarRole < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      CREATE INDEX IF NOT EXISTS idx_group_access_rights_on_role ON group_access_rights (role);
    SQL
  end
end
