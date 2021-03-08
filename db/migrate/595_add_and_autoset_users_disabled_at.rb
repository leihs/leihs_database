class AddAndAutosetUsersDisabledAt < ActiveRecord::Migration[5.0]
  def change

    add_column :users, :account_disabled_at, 'timestamp with time zone'

    reversible do |dir|

      dir.up do

        execute <<-SQL.strip_heredoc

          UPDATE users SET account_disabled_at = now() WHERE account_enabled = false;

          CREATE OR REPLACE FUNCTION users_set_account_disabled_at()
          RETURNS TRIGGER AS $$
          BEGIN
            IF ( OLD.account_enabled = true AND NEW.account_enabled = false) THEN
              NEW.account_disabled_at = now();
            ELSIF ( NEW.account_enabled = true) THEN
              NEW.account_disabled_at = NULL;
            END IF;
            RETURN NEW;
          END;
          $$ language 'plpgsql';

          CREATE TRIGGER users_set_account_disabled_at
          BEFORE UPDATE ON users FOR EACH ROW
          EXECUTE PROCEDURE users_set_account_disabled_at();

        SQL

      end

      dir.down do

        execute <<-SQL.strip_heredoc

          DROP TRIGGER IF EXISTS users_set_account_disabled_at ON users;
          DROP FUNCTION IF EXISTS users_set_account_disabled_at();

        SQL

      end

    end
  end
end
