class RolesCleanUp < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change

    execute <<-SQL.strip_heredoc
      DELETE FROM access_rights WHERE role = 'admin';
      ALTER TABLE access_rights DROP CONSTRAINT check_allowed_roles;
      ALTER TABLE access_rights
        ADD CONSTRAINT check_allowed_roles
        CHECK (
          role IN ('customer', 'group_manager', 'lending_manager', 'inventory_manager')
        );
    SQL

  end

end
