class DeleteOldEmailsTrigger < ActiveRecord::Migration[6.1]

  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION delete_old_emails_f()
      RETURNS TRIGGER AS $$
      BEGIN
        DELETE FROM emails WHERE created_at < CURRENT_DATE - INTERVAL '90 days';
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER delete_old_emails_t
      AFTER INSERT OR UPDATE
      ON emails
      FOR EACH ROW
      EXECUTE PROCEDURE delete_old_emails_f()
    SQL
  end

  def down
    execute 'DROP TRIGGER delete_old_emails_t ON emails'
    execute 'DROP FUNCTION IF EXISTS delete_old_emails_f()'
  end

end

