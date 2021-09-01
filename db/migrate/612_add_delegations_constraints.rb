class AddDelegationsConstraints < ActiveRecord::Migration[5.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = 'users'
  end

  class MigrationDelegation < ActiveRecord::Base
    self.table_name = 'users'

    has_and_belongs_to_many(:delegated_users,
                            class_name: 'MigrationUser',
                            join_table: 'delegations_users',
                            foreign_key: 'delegation_id',
                            association_foreign_key: 'user_id')

    default_scope {
      joins("JOIN delegations_users AS du ON du.delegation_id = users.id")
        .distinct
    }

    def self.without_name
      where(firstname: nil)
    end

    def self.without_responsible_user
      where(delegator_user_id: nil)
    end
  end

  def up
    execute <<~SQL
      CREATE FUNCTION check_delegations_name_is_not_null_f()
      RETURNS trigger
      LANGUAGE 'plpgsql'
      AS $BODY$
      BEGIN
        IF (
          NEW.firstname IS NULL AND EXISTS (
            SELECT true FROM delegations_users WHERE delegation_id = NEW.id
          )
        )
        THEN
          RAISE EXCEPTION 'A delegation must have a name.';
        END IF;

        RETURN NEW;
      END;
      $BODY$; 

      CREATE CONSTRAINT TRIGGER check_delegations_name_is_not_null_t
      AFTER INSERT OR UPDATE 
      ON users
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_delegations_name_is_not_null_f();

      CREATE FUNCTION check_delegations_responsible_user_is_not_null_f()
      RETURNS trigger
      LANGUAGE 'plpgsql'
      AS $BODY$
      BEGIN
        IF (
          NEW.delegator_user_id IS NULL AND EXISTS (
            SELECT true FROM delegations_users WHERE delegation_id = NEW.id
          )
        )
        THEN
          RAISE EXCEPTION 'A delegation must have a reponsible user.';
        END IF;

        RETURN NEW;
      END;
      $BODY$; 

      CREATE CONSTRAINT TRIGGER check_delegations_responsible_user_is_not_null_t
      AFTER INSERT OR UPDATE 
      ON users
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_delegations_responsible_user_is_not_null_f()
    SQL

    MigrationDelegation.without_name.or(MigrationDelegation.without_responsible_user).each do |d|
      if d.firstname.blank? and d.delegator_user_id.blank?
        ru = d.delegated_users.first
        d.update_attributes!(firstname: "VERIFY NAME & VERIFY RESPONSIBLE USER",
                             delegator_user_id: ru.id)

      elsif d.firstname.blank?
        ru = d.delegated_users.first
        d.update_attributes!(firstname: "VERIFY NAME")

      elsif d.delegator_user_id.blank?
        ru = d.delgated_users.first
        d.update_attributes!(firstname: "VERIFY RESPONSIBLE USER: #{d.firstname}",
                             delegator_user_id: ru.id)
      end
    end

    if MigrationDelegation.without_name.exists?
      raise "Delegation with empty name still exists!"
    end

    if MigrationDelegation.without_responsible_user.exists?
      raise "Delegation with empty responsible user still exists!"
    end
  end

  def down
    execute <<~SQL
      DROP TRIGGER check_delegations_name_is_not_null_t ON users;
      DROP FUNCTION check_delegations_name_is_not_null_f();
      DROP TRIGGER check_delegations_responsible_user_is_not_null_t ON users;
      DROP FUNCTION check_delegations_responsible_user_is_not_null_f();
    SQL
  end
end
