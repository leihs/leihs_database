class AddSomeNotNullForGroupAccessRights < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          ALTER TABLE group_access_rights ALTER COLUMN group_id SET NOT NULL;
          ALTER TABLE group_access_rights ALTER COLUMN inventory_pool_id SET NOT NULL;
        SQL
      end
    end
  end
end
