class ContractsUniqueStartDateConstraint < ActiveRecord::Migration[6.1]

  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_unique_start_date_for_same_contract_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF EXISTS (
          SELECT TRUE
          FROM reservations
          WHERE contract_id = NEW.contract_id
            AND start_date <> NEW.start_date
          )
          THEN RAISE EXCEPTION
            'Start date must be same for all reservations of the same contract.';
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER check_unique_start_date_for_same_contract_t
      AFTER INSERT OR UPDATE
      ON reservations
      FOR EACH ROW
      EXECUTE PROCEDURE check_unique_start_date_for_same_contract_f()
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS check_unique_start_date_for_same_contract_t ON fields;
      DROP FUNCTION IF EXISTS check_unique_start_date_for_same_contract_f();
    SQL
  end

end

