class UsersEmailCleanUp < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    execute <<-SQL.strip_heredoc
      UPDATE USERS SET email = nullif(trim(email),'');

      CREATE OR REPLACE FUNCTION clean_email()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.email = nullif(trim(NEW.email),'');
        RETURN NEW;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER clean_email
      AFTER INSERT OR UPDATE
      ON users
      FOR EACH ROW
      EXECUTE PROCEDURE clean_email();

    SQL

  end

  def down
    execute <<-SQL.strip_heredoc
      DROP TRIGGER IF EXISTS clean_email ON users;
      DROP FUNCTION IF EXISTS clean_email();
    SQL
  end

end


