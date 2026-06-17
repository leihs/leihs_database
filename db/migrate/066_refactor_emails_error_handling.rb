class RefactorEmailsErrorHandling < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE emails DISABLE TRIGGER delete_old_emails_t"

    add_column :emails, :is_successful, :boolean
    add_column :emails, :error_message, :text

    execute <<~SQL
      UPDATE emails
      SET is_successful = (code = 0),
          error_message = CASE
            WHEN code = 0 THEN NULL
            WHEN error IS NOT NULL AND message IS NOT NULL THEN error || ': ' || message
            WHEN error IS NOT NULL THEN error
            ELSE message
          END
      WHERE trials > 0
    SQL

    execute <<~SQL
      ALTER TABLE emails DROP CONSTRAINT check_code
    SQL

    execute <<~SQL
      ALTER TABLE emails DROP CONSTRAINT check_error
    SQL

    execute <<~SQL
      ALTER TABLE emails DROP CONSTRAINT check_message
    SQL

    remove_column :emails, :code
    remove_column :emails, :error
    remove_column :emails, :message

    execute <<~SQL
      ALTER TABLE emails
      ADD CONSTRAINT check_trial_success_or_error CHECK (
        ((trials = 0) AND (is_successful IS NULL) AND (error_message IS NULL))
        OR ((trials > 0) AND (
          ((is_successful = true) AND (error_message IS NULL))
          OR ((is_successful = false) AND (error_message IS NOT NULL))
        ))
      )
    SQL

    execute "ALTER TABLE emails ENABLE TRIGGER delete_old_emails_t"

    execute <<~SQL
      DELETE FROM emails WHERE created_at < CURRENT_DATE - INTERVAL '90 days'
    SQL
  end

  def down
    execute "ALTER TABLE emails DISABLE TRIGGER delete_old_emails_t"

    execute <<~SQL
      ALTER TABLE emails DROP CONSTRAINT check_trial_success_or_error
    SQL

    add_column :emails, :code, :integer
    add_column :emails, :error, :text
    add_column :emails, :message, :text

    execute <<~SQL
      UPDATE emails
      SET code = 0,
          error = 'SUCCESS',
          message = 'message sent'
      WHERE trials > 0 AND is_successful = true
    SQL

    execute <<~SQL
      UPDATE emails
      SET code = 1,
          error = split_part(error_message, ':', 1),
          message = CASE
            WHEN position(': ' in error_message) > 0
            THEN substring(error_message from position(': ' in error_message) + 2)
            ELSE error_message
          END
      WHERE trials > 0 AND is_successful = false
    SQL

    execute <<~SQL
      ALTER TABLE emails
      ADD CONSTRAINT check_code CHECK (
        ((trials = 0) AND (code IS NULL)) OR ((trials <> 0) AND (code IS NOT NULL))
      )
    SQL

    execute <<~SQL
      ALTER TABLE emails
      ADD CONSTRAINT check_error CHECK (
        ((trials = 0) AND (error IS NULL)) OR ((trials <> 0) AND (code IS NOT NULL))
      )
    SQL

    execute <<~SQL
      ALTER TABLE emails
      ADD CONSTRAINT check_message CHECK (
        ((trials = 0) AND (message IS NULL)) OR ((trials <> 0) AND (code IS NOT NULL))
      )
    SQL

    remove_column :emails, :is_successful
    remove_column :emails, :error_message

    execute "ALTER TABLE emails ENABLE TRIGGER delete_old_emails_t"
  end
end
