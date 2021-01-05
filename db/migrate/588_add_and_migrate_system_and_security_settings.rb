class AddAndMigrateSystemAndSecuritySettings< ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    execute <<-SQL.strip_heredoc
      CREATE TABLE public.system_and_security_settings (
          id integer DEFAULT 0 NOT NULL,
          accept_server_secret_as_universal_password boolean DEFAULT true NOT NULL,
          external_base_url character varying,
          sessions_force_secure boolean DEFAULT false NOT NULL,
          sessions_force_uniqueness boolean DEFAULT false NOT NULL,
          sessions_max_lifetime_secs integer DEFAULT 432000,
          CONSTRAINT id_is_zero CHECK ((id = 0))
      );

      ALTER TABLE ONLY public.system_and_security_settings
          ADD CONSTRAINT system_and_security_settings_pkey PRIMARY KEY (id);
    SQL

    audit_table :system_and_security_settings

    execute "INSERT INTO system_and_security_settings DEFAULT VALUES;"

    cols = [
      "accept_server_secret_as_universal_password",
      "external_base_url",
      "sessions_force_secure",
      "sessions_force_uniqueness",
      "sessions_max_lifetime_secs",
    ]

    update_cmd = "UPDATE system_and_security_settings SET "
    update_cmd << cols.map{ |col| " #{col} = settings.#{col} " }.join(", ")
    update_cmd << " FROM settings WHERE system_and_security_settings.id = settings.id ; "
    execute update_cmd

    cols.each do |col|
      remove_column :settings, "#{col}"
    end

  end
end
