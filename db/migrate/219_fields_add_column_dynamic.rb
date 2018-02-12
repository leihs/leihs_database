class FieldsAddColumnDynamic < ActiveRecord::Migration[5.0]
  def up
    add_column :fields, :dynamic, :boolean, default: false, null: false

    execute <<-SQL.strip_heredoc
      update
      	fields
      set
      	dynamic = true
      where
      	json_typeof(fields.data::json->'attribute') = 'array'
      	and fields.data::json#>>'{attribute,0}' = 'properties'
    SQL
  end
end
