class AddAndMigrateSmtpSettings< ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    execute <<-SQL.strip_heredoc
      CREATE TABLE public.smtp_settings (
          id integer DEFAULT 0 NOT NULL,
          enabled boolean DEFAULT false NOT NULL,
          address text,
          authentication_type text DEFAULT 'plain'::text,
          default_from_address text DEFAULT 'noreply'::text NOT NULL,
          domain text,
          enable_starttls_auto boolean DEFAULT false NOT NULL,
          openssl_verify_mode text DEFAULT 'none'::text NOT NULL,
          password text,
          port integer,
          sender_address text,
          username text,
          CONSTRAINT id_is_zero CHECK ((id = 0))
      );

      ALTER TABLE ONLY public.smtp_settings
          ADD CONSTRAINT smtp_settings_pkey PRIMARY KEY (id);
    SQL

    audit_table :smtp_settings

    execute "INSERT INTO smtp_settings DEFAULT VALUES;"

    cols = [ :address, :authentication_type, :default_from_address, :domain, :enable_starttls_auto,
        :openssl_verify_mode, :password, :port, :sender_address, :username]

    update_cmd = "UPDATE smtp_settings SET "
    update_cmd << cols.map{ |col| " #{col} = settings.smtp_#{col} " }.join(", ")
    update_cmd << " FROM settings WHERE smtp_settings.id = settings.id ; "
    execute update_cmd

    cols.each do |col|
      remove_column :settings, "smtp_#{col}"
    end


    execute <<-SQL.strip_heredoc
      UPDATE smtp_settings SET
      enabled = CASE
                  WHEN settings.mail_delivery_method = 'smtp' THEN true
                  ELSE false
                END
      FROM settings WHERE smtp_settings.id = settings.id ;
    SQL

    remove_column :settings, :mail_delivery_method

  end
end
