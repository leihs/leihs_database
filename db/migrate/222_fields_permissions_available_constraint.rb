class FieldsPermissionsAvailableConstraint < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      alter table fields
      add constraint fields_permissions_available
      check (
        not dynamic
        or (
          (data::jsonb ? 'permissions')
          and (data::jsonb->'permissions' ? 'role')
          and (data::jsonb->'permissions' ? 'owner')
        )
      );
    SQL
  end
end
