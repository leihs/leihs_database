class AdminApiRefactoring < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    auto_update_searchable :users, [:lastname, :firstname, :email, :login, :unique_id]
    set_timestamps_defaults :users

    add_column :users, :sign_in_enabled, :boolean, default: true, null: false
    add_column :users, :password_sign_in_enabled, :boolean, default: true, null: false

    reversible do |dir|
      dir.up do
        change_column :users, :firstname, :text, null: true
        execute <<-SQL.strip_heredoc
          ALTER TABLE users ADD COLUMN pw_hash text
            NOT NULL DEFAULT crypt(gen_random_uuid()::Text, gen_salt('bf'))
        SQL
      end
      dir.down do
        remove_column :users, :pw_hash
        change_column :users, :firstname, :text
      end
    end

    add_column :users, :img256_data_url, :string, limit: 100000
    add_column :users, :img32_data_url, :string, limit: 10000
    add_column :users, :img_upload_id, :text

    ###########################################################################
    # users constraints, TODO INCOMPLETE YET ##################################
    ###########################################################################

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          ALTER TABLE users DROP CONSTRAINT IF EXISTS email_not_null;
          ALTER TABLE users ADD CONSTRAINT email_not_null CHECK (email is NOT NULL OR delegator_user_id IS NOT NULL);
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          ALTER TABLE users DROP CONSTRAINT IF EXISTS email_not_null;
        SQL
      end
    end


    ###########################################################################
    # settings ################################################################
    ###########################################################################

    remove_column :settings, :id, :uuid,
      default: '00000000-0000-0000-0000-000000000000'

    add_column :settings, :id, :int, default: 0, null: false

    add_column :settings, :accept_server_secret_as_universal_password, :boolean,
      null: false, default: true

    reversible do |dir|
      dir.up do
        change_column :settings, :local_currency_string, :text, null: true
        change_column :settings, :email_signature, :text, null: true
        change_column :settings, :default_email, :text, null: true
        execute <<-SQL.strip_heredoc
          ALTER TABLE settings ADD CONSTRAINT id_is_zero CHECK (id = 0);
          ALTER TABLE settings ADD PRIMARY KEY (id);
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          ALTER TABLE settings DROP CONSTRAINT id_is_zero;
        SQL
      end
    end


    ###########################################################################
    # is_admin ################################################################
    ###########################################################################

    add_column :users, :is_admin, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          UPDATE users SET is_admin = true
            WHERE EXISTS (SELECT 1 FROM access_rights
                            WHERE role = 'admin'
                            AND user_id = users.id )
        SQL

        # TODO: now also delete the admin role

      end
    end


    ###########################################################################
    # api_tokens ##############################################################
    ###########################################################################

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          CREATE TABLE api_tokens (
              id uuid DEFAULT uuid_generate_v4() NOT NULL,
              user_id uuid NOT NULL,
              token_hash text NOT NULL,
              token_part character varying(5) NOT NULL,
              scope_read boolean DEFAULT true NOT NULL,
              scope_write boolean DEFAULT false NOT NULL,
              scope_admin_read boolean DEFAULT false NOT NULL,
              scope_admin_write boolean DEFAULT false NOT NULL,
              description text,
              created_at timestamp with time zone DEFAULT now() NOT NULL,
              updated_at timestamp with time zone DEFAULT now() NOT NULL,
              expires_at timestamp with time zone DEFAULT (now() + '1 year'::interval) NOT NULL,
              CONSTRAINT sensible_scope_admin_read CHECK (((NOT scope_admin_read) OR (scope_admin_read AND scope_read))),
              CONSTRAINT sensible_scrope_admin_write CHECK (((NOT scope_admin_write) OR (scope_admin_write AND scope_admin_read))),
              CONSTRAINT sensible_scrope_write CHECK (((NOT scope_write) OR (scope_write AND scope_read)))
          );
        SQL
        set_timestamps_defaults :api_tokens
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TABLE api_tokens;
        SQL
      end
    end


    ###########################################################################
    # users_overview, just convenience ########################################
    ###########################################################################

    reversible do |dir|
      dir.up do

        execute <<-SQL.strip_heredoc
          CREATE OR REPLACE VIEW users_overview AS
          SELECT id, unique_id AS org_id, email, firstname, lastname,
            is_admin, sign_in_enabled,
            (pw_hash IS NOT NULL)  AS has_password,
            (img256_data_url IS NOT NULL) AS has_image
            FROM users;
        SQL


      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP VIEW users_overview;
        SQL
      end

    end


  end

end

