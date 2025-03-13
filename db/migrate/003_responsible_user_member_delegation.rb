class ResponsibleUserMemberDelegation < ActiveRecord::Migration[6.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationDelegationDirectUser < ActiveRecord::Base
    self.table_name = "delegations_direct_users"
  end

  def up
    MigrationUser.all.each do |u|
      if u.delegator_user_id &&
          !MigrationDelegationDirectUser.find_by(delegation_id: u.id, user_id: u.delegator_user_id)
        MigrationDelegationDirectUser.create!(delegation_id: u.id, user_id: u.delegator_user_id)
      end
    end

    execute <<-SQL
      CREATE OR REPLACE FUNCTION insert_into_delegations_direct_users_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (NEW.delegator_user_id IS NOT NULL) THEN 
          INSERT INTO delegations_direct_users (delegation_id, user_id)
          VALUES (NEW.id, NEW.delegator_user_id)
          ON CONFLICT DO NOTHING;

          IF (TG_OP = 'UPDATE' AND OLD.delegator_user_id <> NEW.delegator_user_id) THEN
            DELETE FROM delegations_direct_users
            WHERE delegation_id = OLD.id AND user_id = OLD.delegator_user_id;
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE TRIGGER insert_into_delegations_direct_users_t
      AFTER INSERT OR UPDATE
      ON users
      FOR EACH ROW
      EXECUTE PROCEDURE insert_into_delegations_direct_users_f()
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_if_responsible_user_after_delete_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF EXISTS (
          SELECT 1
          FROM users
          WHERE OLD.delegation_id = id AND OLD.user_id = delegator_user_id
        ) THEN
          RAISE EXCEPTION 'One cannot delete a member of a delegation if he is also the responsible user.';
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER check_if_responsible_user_after_delete_t
      AFTER DELETE
      ON delegations_direct_users
      FOR EACH ROW
      EXECUTE PROCEDURE check_if_responsible_user_after_delete_f()
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_if_responsible_user_after_update_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1
          FROM users
          WHERE NEW.user_id = delegator_user_id AND NEW.delegation_id = id
          )
          THEN RAISE EXCEPTION
            'Responsible user must also be a member for this delegation.';
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER check_if_responsible_user_after_update_t
      AFTER UPDATE
      ON delegations_direct_users
      FOR EACH ROW
      EXECUTE PROCEDURE check_if_responsible_user_after_update_f()
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS insert_into_delegations_direct_users_t ON users;
      DROP FUNCTION IF EXISTS insert_into_delegations_direct_users_f();
      DROP TRIGGER IF EXISTS check_if_responsible_user_after_delete_t ON delegations_direct_users;
      DROP FUNCTION IF EXISTS check_if_responsible_user_after_delete_f();
      DROP TRIGGER IF EXISTS check_if_responsible_user_after_update_t ON delegations_direct_users;
      DROP FUNCTION IF EXISTS check_if_responsible_user_after_update_f();
    SQL
  end
end
