class Audits < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change

    remove_foreign_key :procurement_admins, :users
    add_foreign_key :procurement_admins, :users, on_delete: :cascade

    reversible do |dir|

      dir.up do

        execute <<-SQL.strip_heredoc

          CREATE OR REPLACE FUNCTION txid()
          RETURNS uuid AS $$
          BEGIN
            RETURN uuid_generate_v5(uuid_nil(), current_date::TEXT || ' ' || txid_current()::TEXT);
          END;
          $$ LANGUAGE plpgsql;

          CREATE OR REPLACE FUNCTION jsonb_changed(jold JSONB,jnew JSONB)
          RETURNS JSONB AS $$
          DECLARE
            result JSONB;
            v RECORD;
          BEGIN
             result = jnew;
             FOR v IN SELECT * FROM jsonb_each(jold) LOOP
               IF result @> jsonb_build_object(v.key,v.value)
                  THEN result = result - v.key;
               ELSIF result ? v.key THEN CONTINUE;
               ELSE
                  result = result || jsonb_build_object(v.key,'null');
               END IF;
             END LOOP;
             RETURN result;
          END;
          $$ LANGUAGE plpgsql;

        SQL

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE FUNCTION audit_change()
          RETURNS TRIGGER AS $$
            DECLARE 
              c_changed JSONB;
              c_new JSONB;
              c_old JSONB;
          BEGIN
            IF (TG_OP = 'DELETE') THEN
              c_old = row_to_json(OLD)::JSONB;
              c_new = '{}'::JSONB;
            ELSIF (TG_OP = 'INSERT') THEN
              c_old = '{}'::JSONB;
              c_new = row_to_json(NEW)::JSONB;
            ELSIF (TG_OP = 'UPDATE') THEN
              c_old = row_to_json(OLD)::JSONB;
              c_new = row_to_json(NEW)::JSONB;
            END IF;
            c_changed = jsonb_changed(c_old,c_new);
            if (c_old <> c_new) THEN
              INSERT INTO audited_changes (tg_op, table_name, before, after, changed) 
                VALUES (TG_OP, TG_TABLE_NAME, c_old, c_new, c_changed);
            END IF;
            RETURN NEW;
          END;
          $$ LANGUAGE 'plpgsql';
        SQL

        audit_table :api_tokens
        audit_table :authentication_systems
        audit_table :authentication_systems_groups
        audit_table :authentication_systems_users
        audit_table :groups
        audit_table :groups_users
        audit_table :system_admin_groups
        audit_table :user_password_resets
        audit_table :user_sessions
        audit_table :users

      end

      dir.down do

        execute <<-SQL.strip_heredoc
          DROP FUNCTION jsonb_changed;
          DROP FUNCTION audit_change CASCADE;
          DROP FUNCTION txid;

        SQL

      end

    end

    create_table :audited_changes, id: :uuid do |table|
      table.uuid :txid, null: false, default: 'txid()'
      table.text :tg_op, null: false
      table.text :table_name, null: false
      table.jsonb :before
      table.jsonb :after
      table.jsonb :changed
    end
    add_auto_timestamps :audited_changes, updated_at: false
    

    create_table :audited_requests, id: :uuid do |table|
      table.uuid :txid, null: false, default: 'txid()'
      table.uuid :user_id
      table.text :url
      table.text :method
      table.jsonb :data
    end
    add_auto_timestamps :audited_requests, updated_at: false
    # not sure if we want the following  
    # add_foreign_key :audited_requests, :users, on_delete: :cascade
    # surely not with cascade! 

    create_table :audited_responses, id: :uuid do |table|
      table.uuid :txid, null: false
      table.integer :status, null: false
      table.jsonb :data
    end
    add_auto_timestamps :audited_responses, updated_at: false


    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE INDEX audited_changes_txid ON audited_changes (txid);
          CREATE INDEX audited_changes_table_name ON audited_changes (table_name);
          CREATE INDEX audited_changes_tg_op ON audited_changes (tg_op);
          CREATE INDEX audited_changes_before_idx ON audited_changes USING gin(to_tsvector('english', before));
          CREATE INDEX audited_changes_after_idx ON audited_changes USING gin(to_tsvector('english', after));
          CREATE INDEX audited_changes_changed_idx ON audited_changes USING gin(to_tsvector('english', changed));

          CREATE INDEX audited_requests_txid ON audited_requests (txid);
          CREATE INDEX audited_requests_user_id ON audited_requests (user_id);
          CREATE INDEX audited_requests_method ON audited_requests (method);
          CREATE INDEX audited_requests_url ON audited_requests (url);
          CREATE INDEX audited_requests_data ON audited_requests USING gin(to_tsvector('english', data));

          CREATE INDEX audited_responses_txid ON audited_responses (txid);

        SQL
      end
    end

  end

end
