class MigrateSmtpOpensslVerifyMode < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      UPDATE settings
      SET smtp_openssl_verify_mode =
        CASE
          WHEN smtp_openssl_verify_mode = '0' THEN 'none'
          WHEN smtp_openssl_verify_mode = '1' THEN 'peer'
          ELSE 'none'
        END
      WHERE smtp_openssl_verify_mode NOT IN ('none', 'peer')
    SQL
  end
end
