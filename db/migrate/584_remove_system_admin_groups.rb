class RemoveSystemAdminGroups < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      DROP TABLE system_admin_groups;
    SQL
  end
end
