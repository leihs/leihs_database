class AdminProtection < ActiveRecord::Migration[5.0]

  def up
    execute <<-SQL

      BEGIN;

      UPDATE users SET system_admin_protected = true WHERE is_system_admin = true;
      UPDATE users SET admin_protected = true WHERE is_admin = true;

      COMMIT;

      ALTER TABLE users ADD CONSTRAINT check_require_admin_protection
      CHECK (((is_system_admin AND system_admin_protected) OR (NOT is_system_admin))
             AND ((admin_protected AND is_admin) OR (NOT is_admin)));

    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE users DROP CONSTRAINT check_require_admin_protection;
    SQL
  end

end

