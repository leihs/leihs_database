class ToAddressNotNull < ActiveRecord::Migration[8.1]
  def up
    execute "DROP TRIGGER check_emails_to_address_not_null_t ON emails"
    execute "DROP FUNCTION check_emails_to_address_not_null_f()"
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
      FOR EACH ROW EXECUTE FUNCTION public.check_emails_to_address_not_null_f();
    SQL
  end
end
