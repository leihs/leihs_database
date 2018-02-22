class DynamicFields < ActiveRecord::Migration[5.0]
  def up
    drop_old_trigger
    add_missing_not_null
    add_column_dynamic
    add_delete_trigger
    add_insert_trigger
    add_update_trigger
    migrate_property_fields_as_dynamic_fields
  end

  def down
    execute <<-SQL.strip_heredoc
      ALTER TABLE fields DROP COLUMN dynamic;

      DROP TRIGGER IF EXISTS trigger_fields_delete_check_function ON fields;
      DROP FUNCTION IF EXISTS fields_delete_check_function();

      DROP TRIGGER IF EXISTS fields_insert_check_trigger ON fields;
      DROP FUNCTION IF EXISTS fields_insert_check_function();

      DROP TRIGGER IF EXISTS fields_update_check_trigger ON fields;
      DROP FUNCTION IF EXISTS fields_update_check_function();
    SQL

    change_column_null :fields, :data, true
    change_column_null :fields, :position, true
    change_column_null :fields, :active, true
  end

  private

  def drop_old_trigger
    execute <<-SQL.strip_heredoc
      DROP TRIGGER IF EXISTS trigger_restrict_operations_on_fields_function ON fields;
      DROP FUNCTION IF EXISTS restrict_operations_on_fields_function();
    SQL
  end

  def add_missing_not_null
    change_column_null :fields, :data, false
    change_column_null :fields, :position, false
    change_column_null :fields, :active, false
  end

  def migrate_property_fields_as_dynamic_fields
    execute <<-SQL.strip_heredoc

      update
        fields
      set
        dynamic = true

      where (
        #{checks_as_ands_sql('fields')}
      )
    SQL
  end

  def add_column_dynamic
    add_column :fields, :dynamic, :boolean, default: false, null: false
  end

  def add_delete_trigger
    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION fields_delete_check_function()
      RETURNS TRIGGER AS $$
      BEGIN

        IF (
          NOT OLD.dynamic
        )
        THEN
          RAISE EXCEPTION 'Cannot delete field which is not dynamic.';
          RETURN OLD;
        END IF;


        IF (
          -- Check if there is an item which uses the field.
          EXISTS (
            SELECT 1
            FROM items
            WHERE items.properties::jsonb ? (OLD.data::json#>>'{attribute,1}')
          )
        )
        THEN
          RAISE EXCEPTION 'Cannot delete field which is still in use.';
          RETURN OLD;
        END IF;

        RETURN OLD;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER trigger_fields_delete_check_function
      BEFORE DELETE
      ON fields
      FOR EACH ROW
      EXECUTE PROCEDURE fields_delete_check_function();
    SQL
  end

  def add_insert_trigger
    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION fields_insert_check_function()
      RETURNS TRIGGER AS $$
      BEGIN

        IF (
          not NEW.dynamic
        )
        THEN
          RAISE EXCEPTION 'New fields must always be dynamic.';
          RETURN NEW;
        END IF;

        #{checks_as_ifs_sql('NEW')}

        RETURN NEW;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER fields_insert_check_trigger
      BEFORE INSERT
      ON fields
      FOR EACH ROW
      EXECUTE PROCEDURE fields_insert_check_function();
    SQL
  end

  def add_update_trigger
    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION fields_update_check_function()
      RETURNS TRIGGER AS $$
      BEGIN

        IF (
          not NEW.dynamic
          and not (
            -- Id may not change.
            NEW.id = OLD.id

            and
            -- Data must be same as before except the label, permissions.role and permission.owner.
            jsonb_pretty(NEW.data::jsonb)
            =
            jsonb_pretty(
              jsonb_set(
                jsonb_set(
                  jsonb_set(
                    OLD.data::jsonb,
                    '{label}',
                    (NEW.data::jsonb->'label'),
                    false
                  ),
                  '{permissions,role}',
                  (NEW.data::jsonb->'permissions'->'role'),
                  false
                ),
                '{permissions,owner}',
                (NEW.data::jsonb->'permissions'->'owner'),
                false
              )
            )
          )
        )
        THEN
          RAISE EXCEPTION 'None dynamic fields only allow to change the attributes active, position, data.label, data.permissions.role and data.permissions.owner.';
          RETURN NEW;
        END IF;

        #{checks_as_ifs_sql('NEW')}


        IF (
          NEW.dynamic
          and not (

            (

              -- We do not check the values, if no item uses this field. Otherwise if the field is already used, existing values must not change.
              not EXISTS (
                SELECT 1
                FROM items
                WHERE items.properties::jsonb ? (NEW.data::json#>>'{attribute,1}')
              )

              -- If the values were null, the values will have to be null again.
              or (
                (NEW.data::json->'values') is null
                and
                (OLD.data::json->'values') is null
              )

              -- If there were values, we will need the same count of values again or more.
              -- The old values must be contained in the new values.
              or (
                json_array_length(NEW.data::json->'values') >= json_array_length(OLD.data::json->'values')
                and
                (select array_agg(v::jsonb->'value') from (select jsonb_array_elements(NEW.data::jsonb->'values') as v) as vs)
                @>
                (select array_agg(v::jsonb->'value') from (select jsonb_array_elements(OLD.data::jsonb->'values') as v) as vs)
              )

            )
          )
        )
        THEN
          RAISE EXCEPTION 'New field is not valid.';
          RETURN NEW;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER fields_update_check_trigger
      BEFORE UPDATE
      ON fields
      FOR EACH ROW
      EXECUTE PROCEDURE fields_update_check_function();
    SQL
  end

  def checks_as_ands_sql(name)
    <<-SQL.strip_heredoc

      #{check_properties_id_format(name)}
      and #{check_data_json_keys(name)}
      and #{check_attributes_format(name)}
      and #{check_attribute_name(name)}
      and #{check_permissions(name)}
      and #{check_type(name)}
      and #{check_label(name)}
      and #{check_target_type(name)}
      and #{check_required(name)}
      and #{check_values(name)}
      and #{check_distinct_values(name)}
      and #{check_default(name)}

    SQL
  end

  def checks_as_ifs_sql(name)
    <<-SQL.strip_heredoc
      IF (#{name}.dynamic and not #{check_properties_id_format(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_properties_id_format !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_data_json_keys(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_data_json_keys !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_attributes_format(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_attributes_format !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_attribute_name(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_attribute_name !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_permissions(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_permissions !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_type(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_type !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_label(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_label !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_target_type(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_target_type !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_required(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_required !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_values(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_values !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_distinct_values(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_distinct_values !!!!!'; RETURN #{name};
      END IF;

      IF (#{name}.dynamic and not #{check_default(name)})
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_default !!!!!'; RETURN #{name};
      END IF;
    SQL
  end

  def check_properties_id_format(name)
    <<-SQL.strip_heredoc
      -- At least one character after underline.
      (
        #{name}.id like 'properties\\__%'
      )
    SQL
  end

  def check_data_json_keys(name)
    <<-SQL.strip_heredoc
      (
        (
          -- No other attributes in data than these ones.
          array['attribute', 'default', 'forPackage', 'group', 'label', 'permissions', 'target_type', 'type', 'values']
          @>
          array(select json_object_keys(#{name}.data::json))
        )
        and
        (
          -- These keys are always mandatory (some can be null, check further checks, but the keys must exist).
          #{name}.data::jsonb ?& array['type', 'group', 'label', 'attribute', 'permissions']
        )
      )
    SQL
  end

  def check_attributes_format(name)
    <<-SQL.strip_heredoc
      -- The attribute must have the right format.
      (
        #{name}.data::json->'attribute' is not null
        and json_typeof(#{name}.data::json->'attribute') = 'array'
        and json_array_length(#{name}.data::json->'attribute') = 2
        and (#{name}.data::json#>>'{attribute,0}') = 'properties'
      )
    SQL
  end

  def check_attribute_name(name)
    <<-SQL.strip_heredoc
      -- The attribute name must match the id.
      (
        #{name}.id = 'properties_' || (#{name}.data::json#>>'{attribute,1}')
      )
    SQL
  end

  def check_permissions(name)
    <<-SQL.strip_heredoc
      (
        (#{name}.data::json->'permissions') is not null
        and (#{name}.data::json->'permissions'->>'role') is not null
        and (#{name}.data::json->'permissions'->>'owner') is not null
      )
    SQL
  end

  def check_type(name)
    <<-SQL.strip_heredoc
      (
        (#{name}.data::json->>'type') is not null
        and (#{name}.data::json->>'type') in ('text', 'date', 'select', 'textarea', 'radio', 'checkbox')
      )
    SQL
  end

  def check_label(name)
    <<-SQL.strip_heredoc
      (
        (#{name}.data::json->>'label') is not null
      )
    SQL
  end

  def check_target_type(name)
    <<-SQL.strip_heredoc
      (
        (#{name}.data::json->>'target_type') is null
        or (#{name}.data::json->>'target_type') in ('item', 'license')
      )
    SQL
  end

  def check_required(name)
    <<-SQL.strip_heredoc
      (
        (#{name}.data::json->>'required') is null
      )
    SQL
  end

  def check_values(name)
    <<-SQL.strip_heredoc
      (
        (
          not (#{name}.data::json->>'type') in ('radio', 'select', 'checkbox')
          and #{name}.data::json->'values' is null

        )
        or
        (

          (#{name}.data::json->>'type') in ('radio', 'select', 'checkbox')


          and json_typeof(#{name}.data::json->'values') = 'array'

          -- There should not exist values which do not match the expected properties.
          and not exists (

            -- The values as a json row list.
            with vs as (
            	select jsonb_array_elements(#{name}.data::jsonb->'values') as v
            ),

            -- The values as an array row list.
            arr as (
            	select
            		array_to_json(array(
            			select jsonb_object_keys(v::jsonb)
            		)) as arr
            	from
            		vs
            )

            -- Find the ones which have not 2 keys or not the expected properties.
            select
            	*
            from
            	arr
            where
            	json_array_length(arr) <> 2
            	or not (arr::jsonb @> '["label","value"]'::jsonb)
          )

        )

      )
    SQL
  end

  def check_distinct_values(name)
    <<-SQL.strip_heredoc
      (

        not (#{name}.data::json->>'type') in ('radio', 'select', 'checkbox')

        or (
          (#{name}.data::json->>'type') in ('radio', 'select', 'checkbox')

          and (

            with vs as (
              select jsonb_array_elements(#{name}.data::jsonb->'values') as v
            )

            select
            (

              -- We need to wrap it otherwise count will not count null values.
              select count(*) from (
                select
                    distinct v::json->>'value'
                from
                    vs v
              ) as sub
            )

            =

            (
              -- We need to wrap it otherwise count will not count null values.
              select count(*) from (
                select
                    v::json->>'value'
                from
                    vs v
              ) as sub
            )

          )
        )

      )
    SQL
  end

  def check_default(name)
    <<-SQL.strip_heredoc
      (
        -- Check default only for radio and select.
        (
          not (#{name}.data::json->>'type') in ('radio', 'select')
          and #{name}.data::json->'default' is null
        )
        or
        (
          (#{name}.data::json->>'type') in ('radio', 'select')

          and

          (
            (#{name}.data::json->'values' is null)
            and
            (#{name}.data::json->'default' is null)

            or

            (#{name}.data::json->'values' is not null)
            and
            (#{name}.data::json->'default' is not null)
            and 1 = (

              with vs as (
                select jsonb_array_elements(#{name}.data::jsonb->'values') as v
              )

              -- Check that there exists a value equal to the default value or both are null.
              select
                count(*)
              from
                vs v
              where
                (v::json->>'value') = (#{name}.data::jsonb->>'default')
                or (v::json->>'value') is null and (#{name}.data::jsonb->>'default') is null

            )
          )
        )
      )
    SQL
  end
end
