class RefactorEmailsErrorHandling < ActiveRecord::Migration[8.1]
  def up
    add_column :emails, :is_successful, :boolean
    add_column :emails, :error_message, :text

    execute <<~SQL
      UPDATE emails
      SET is_successful = true,
          error_message = NULL
      WHERE trials > 0 AND code = 0
    SQL

    execute <<~SQL
      UPDATE emails
      SET is_successful = false,
          error_message = CASE
            WHEN error IS NOT NULL AND message IS NOT NULL THEN error || ': ' || message
            WHEN error IS NOT NULL THEN error
            ELSE message
          END
      WHERE trials > 0 AND code > 0
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

    execute <<~SQL
      DROP TRIGGER check_emails_to_address_not_null_t ON emails
    SQL

    execute <<~SQL
      DROP FUNCTION check_emails_to_address_not_null_f()
    SQL

    change_column_null :emails, :to_address, false
  end

  def down
    change_column_null :emails, :to_address, true

    execute <<~SQL
      CREATE FUNCTION public.check_emails_to_address_not_null_f() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
            BEGIN
              IF ( NEW.to_address IS NULL ) THEN
                RAISE EXCEPTION 'to_address cannot be null';
              END IF;
              RETURN NEW;
            END;
            $$;
    SQL

    execute <<~SQL
      CREATE CONSTRAINT TRIGGER check_emails_to_address_not_null_t
      AFTER INSERT OR UPDATE ON public.emails
      NOT DEFERRABLE INITIALLY IMMEDIATE
      FOR EACH ROW
      EXECUTE FUNCTION public.check_emails_to_address_not_null_f();
    SQL

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
  end
end
