class AccessRightsView < ActiveRecord::Migration[5.0]
  def change
    rename_table :access_rights, :direct_access_rights

    reversible do |dir|

      dir.up do
        execute IO.read(
          Pathname(__FILE__).dirname.join("541_unified_access_rights_view.sql"))
        execute IO.read(
          Pathname(__FILE__).dirname.join("541_access_rights_view_up.sql"))
      end

      dir.down do
        execute IO.read( Pathname(__FILE__).dirname.join("541_access_rights_view_down.sql"))
        execute <<-SQL.strip_heredoc
          DROP VIEW IF EXISTS unified_access_rights;
        SQL
      end

    end

  end
end
