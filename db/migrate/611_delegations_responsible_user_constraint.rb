class DelegationsResponsibleUserConstraint < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE FUNCTION check_responsible_user_is_not_delegation_f()
      RETURNS trigger
      LANGUAGE 'plpgsql'
      AS $BODY$
      BEGIN
        IF (
          ( SELECT delegator_user_id
            FROM users
            WHERE id = NEW.delegator_user_id ) IS NOT NULL
        )
        THEN
          RAISE EXCEPTION 'Responsible user of a delegation can''t be a delegation.';
        END IF;

        RETURN NEW;
      END;
      $BODY$; 

      CREATE CONSTRAINT TRIGGER check_responsible_user_is_not_delegation_t
      AFTER INSERT OR UPDATE 
      ON users
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_responsible_user_is_not_delegation_f();
    SQL
  end
end
