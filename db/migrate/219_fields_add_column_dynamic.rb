class FieldsAddColumnDynamic < ActiveRecord::Migration[5.0]
  def up
    add_column :fields, :dynamic, :boolean, default: false, null: false

    execute <<-SQL.strip_heredoc
      -- update
      -- 	fields
      -- set
      -- 	dynamic = true
      -- where
      -- 	json_typeof(fields.data::json->'attribute') = 'array'
      -- 	and fields.data::json#>>'{attribute,0}' = 'properties'
      --   and (
      -- 		fields.data::json->>'required' <> 'true'
      -- 		or fields.data::json->>'required' is null
      -- 	)


      update
        fields
      set
        dynamic = true


      where (
      	fields.data::json->'attribute' is not null
      	and	json_typeof(fields.data::json->'attribute') = 'array'
      	and json_array_length(fields.data::json->'attribute') = 2
      	and (fields.data::json#>>'{attribute,0}') = 'properties'

      	and (id = 'properties_' || (data::json#>>'{attribute,1}'))

      	and (fields.data::json->'permissions') is not null
      	and (fields.data::json->'permissions'->>'role') is not null
      	and (fields.data::json->'permissions'->>'owner') is not null

      	and (fields.data::json->>'type') is not null
      	and (fields.data::json->>'type') in ('text', 'date', 'select', 'textarea', 'radio', 'checkbox')


      	and (fields.data::json->>'label') is not null

      	and (fields.data::json->>'target_type') is not null
      	and (fields.data::json->>'target_type') in ('item', 'license')

      	and (

      		(fields.data::json->>'type') = 'checkbox'
      		and
      		(
      			array(select json_object_keys(fields.data::json))
      			@>
      			array['attribute', 'group', 'label', 'permissions', 'target_type', 'type', 'values']

      			and

      			array['forPackage']
      			@>
      			array((
      				select * from json_object_keys(fields.data::json) as keys where keys not in ('attribute', 'group', 'label', 'permissions', 'target_type', 'type', 'values')
      			))

      		)

      		or

      		(fields.data::json->>'type') in ('radio', 'select')
      		and
      		(
      			array(select json_object_keys(fields.data::json))
      			@>
      			array['attribute', 'default', 'group', 'label', 'permissions', 'target_type', 'type', 'values']

      			and

      			array['default', 'forPackage']
      			@>
      			array((
      				select * from json_object_keys(fields.data::json) as keys where keys not in ('attribute', 'default', 'group', 'label', 'permissions', 'target_type', 'type', 'values')
      			))
      		)

      		or

      		(fields.data::json->>'type') in ('text', 'textarea')
      		and
      		(
      			array(select json_object_keys(fields.data::json))
      			@>
      			array['attribute', 'group', 'label', 'permissions', 'target_type', 'type']

      			and

      			array['forPackage']
      			@>
      			array((
      				select * from json_object_keys(fields.data::json) as keys where keys not in ('attribute', 'group', 'label', 'permissions', 'target_type', 'type')
      			))
      		)

      		or

      		(fields.data::json->>'type') in ('date')
      		and
      		(
      			array(select json_object_keys(fields.data::json))
      			@>
      			array['attribute', 'group', 'label', 'permissions', 'target_type', 'type']

      			and

      			array['default', 'forPackage']
      			@>
      			array((
      				select * from json_object_keys(fields.data::json) as keys where keys not in ('attribute', 'group', 'label', 'permissions', 'target_type', 'type')
      			))
      		)

      	)

      	and (fields.data::json->>'required') is null

      )
    SQL
  end
end
