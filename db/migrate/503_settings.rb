class Settings < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change

    create_table :system_settings, id: false do |t|

      t.integer :id, default: 0, null: false
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          ALTER TABLE system_settings ADD CONSTRAINT id_is_zero CHECK (id = 0);
          ALTER TABLE system_settings ADD PRIMARY KEY (id);
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          ALTER TABLE system_settings DROP CONSTRAINT id_is_zero;
        SQL
      end
    end



    add_column :system_settings, :ldap_config, :jsonb

    add_column :system_settings, :smtp_address, :string, default: 'localhost'
    add_column :system_settings, :smtp_domain, :string, default: 'example.com'
    add_column :system_settings, :smtp_enable_starttls_auto, :boolean, null: false, default: false
    add_column :system_settings, :smtp_openssl_verify_mode, :string, null: false, default: :none
    add_column :system_settings, :smtp_password, :string
    add_column :system_settings, :smtp_port, :integer, default: 25
    add_column :system_settings, :smtp_username, :string

    add_column :system_settings, :time_zone, :string, null: false, default: 'Bern'

    add_column :system_settings, :external_base_url, :string, null: false, default: 'http://localhost:3100'

    add_column :system_settings, :sessions_force_secure, :boolean, null: false, default: false
    add_column :system_settings, :sessions_force_uniqueness, :boolean, null: false, default: false
    add_column :system_settings, :sessions_max_lifetime_secs, :integer, default: 32000

    add_column :system_settings, :accept_server_secret_as_universal_password, :boolean, null: false, default: false

    execute <<-SQL.strip_heredoc
      INSERT INTO system_settings (id) VALUES (0);
    SQL

    # migrate cols
    [:smtp_address, :smtp_domain, :smtp_enable_starttls_auto, :smtp_openssl_verify_mode, :smtp_password, :smtp_port, :smtp_username,
     :time_zone, :external_base_url,
     :sessions_force_secure, :sessions_force_uniqueness, :sessions_max_lifetime_secs, :accept_server_secret_as_universal_password,
    ].each do |setting|
      execute <<-SQL.strip_heredoc
        UPDATE system_settings
          SET #{setting.to_s} = settings.#{setting}
          FROM settings
          WHERE settings.id = system_settings.id
      SQL
    end


    # remove cols
    [:ldap_config,
     :smtp_address, :smtp_domain, :smtp_enable_starttls_auto, :smtp_openssl_verify_mode, :smtp_password, :smtp_port, :smtp_username,
     :time_zone, :external_base_url,
     :sessions_force_secure, :sessions_force_uniqueness, :sessions_max_lifetime_secs, :accept_server_secret_as_universal_password,
    ].each do |setting|
       remove_column :settings, setting
     end

  end

end
