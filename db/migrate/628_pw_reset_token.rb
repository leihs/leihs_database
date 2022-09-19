class PwResetToken < ActiveRecord::Migration[5.0]

  def up
    execute <<-SQL

      CREATE OR REPLACE FUNCTION base32_crockford_str(n int DEFAULT 10) RETURNS text
        LANGUAGE SQL
        AS $$
        SELECT
          string_agg(substr(characters, (random() * length(characters) + 1)::integer, 1), '')
        FROM (values('0123456789ABCDEFGHJKMNPQRSTVWXYZ')) as symbols(characters)
          JOIN generate_series(1, n) on 1 = 1;
        $$;

      ALTER TABLE user_password_resets ADD CONSTRAINT check_token_base32_crockford
        CHECK (token ~ '^[0123456789ABCDEFGHJKMNPQRSTVWXYZ]+$'::text);

      ALTER TABLE user_password_resets ALTER COLUMN token
        SET DEFAULT base32_crockford_str(10) ;

      ALTER TABLE user_password_resets ALTER COLUMN token
        SET NOT NULL;

    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE user_password_resets DROP CONSTRAINT check_token_base32_crockford;
      ALTER TABLE user_password_resets DROP NOT NULL;
      ALTER TABLE user_password_resets DROP DEFAULT;
      DROP FUNCTION base32_crockford_str(integer);
    SQL
  end

end

