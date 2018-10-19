class CreateUserTrigger < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      CREATE OR REPLACE FUNCTION insert_customer_access_rights()
      RETURNS TRIGGER AS $$
      BEGIN
        INSERT INTO access_rights (
          user_id, inventory_pool_id, role
        )
        SELECT NEW.id, inventory_pools.id, 'customer'
        FROM inventory_pools
        WHERE inventory_pools.automatic_access = TRUE;

        RETURN NULL;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER trigger_insert_customer_access_rights
      AFTER INSERT
      ON users
      FOR EACH ROW
      EXECUTE PROCEDURE insert_customer_access_rights();
    SQL
  end

  def down
    execute <<-SQL.strip_heredoc
      DROP TRIGGER IF EXISTS trigger_insert_customer_access_rights ON users;
      DROP FUNCTION IF EXISTS insert_customer_access_rights();
    SQL
  end
end
