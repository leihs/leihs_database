class FieldsIdMatchesPropertyNameConstraint < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      alter table fields
      add constraint fields_id_matches_property_name
      check (
        not dynamic
        or id = 'properties_' || (data::json#>>'{attribute,1}')
      );
    SQL
  end
end
