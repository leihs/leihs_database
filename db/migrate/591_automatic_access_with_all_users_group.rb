class AutomaticAccessWithAllUsersGroup < ActiveRecord::Migration[5.0]
  class MigrationGroup < ActiveRecord::Base
    self.table_name = 'groups'
  end

  class MigrationInventoryPool < ActiveRecord::Base
    self.table_name = 'inventory_pools'
  end

  class MigrationDirectAccessRight < ActiveRecord::Base
    self.table_name = 'direct_access_rights'
  end

  class MigrationDirectAccessRight < ActiveRecord::Base
    self.table_name = 'direct_access_rights'
  end

  class MigrationGroupAccessRight < ActiveRecord::Base
    self.table_name = 'group_access_rights'
  end

  def up
    MigrationGroup.create!(id: ::Leihs::Constants::ALL_USERS_GROUP_UUID,
                           name: 'All users',
                           protected: true)

    populate_group_sql = <<~SQL
      INSERT INTO groups_users(group_id, user_id)
      SELECT '#{::Leihs::Constants::ALL_USERS_GROUP_UUID}', id
      FROM users
      WHERE delegator_user_id IS NULL
      ON CONFLICT DO NOTHING;
    SQL

    execute populate_group_sql

    MigrationInventoryPool.where(automatic_access: true).each do |pool|
      MigrationDirectAccessRight
        .where(inventory_pool_id: pool.id, role: 'customer')
        .delete_all

      MigrationGroupAccessRight.create!(inventory_pool_id: pool.id,
                                        group_id: ::Leihs::Constants::ALL_USERS_GROUP_UUID,
                                        role: 'customer')
    end

    remove_column(:inventory_pools, :automatic_access)

    execute <<-SQL.strip_heredoc
      DROP TRIGGER IF EXISTS trigger_insert_customer_access_rights ON users;
      DROP FUNCTION IF EXISTS insert_customer_access_rights();
    SQL

    execute <<-SQL.strip_heredoc
      CREATE FUNCTION populate_all_users_group_f()
      RETURNS TRIGGER AS $$
      BEGIN
        #{populate_group_sql}
        RETURN NULL;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER populate_all_users_group_t
      AFTER INSERT ON users
      FOR EACH STATEMENT
      EXECUTE PROCEDURE populate_all_users_group_f();
    SQL
    
    execute <<-SQL.strip_heredoc
      CREATE FUNCTION prevent_deleting_all_users_group_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF ( OLD.id = '#{::Leihs::Constants::ALL_USERS_GROUP_UUID}' )
        THEN
          RAISE EXCEPTION 'Deleting this specific group is not allowed.';
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER prevent_deleting_all_users_group_t
      BEFORE delete ON groups
      FOR EACH ROW
      EXECUTE PROCEDURE prevent_deleting_all_users_group_f();
    SQL
  end
end
