class NullableContractsPurpose < ActiveRecord::Migration[5.0]
  def up
    change_column(:contracts, :purpose, :text, null: true)

    execute <<~SQL
      UPDATE contracts
      SET purpose = NULL
      WHERE purpose ~ '^\s*$' 
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION check_contracts_purpose_is_not_null_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (
          NEW.purpose IS NULL AND
          ( SELECT required_purpose FROM inventory_pools WHERE inventory_pools.id = NEW.inventory_pool_id )
          ) THEN
          RAISE EXCEPTION 'Contract''s purpose can''t be NULL for this inventory pool.';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE 'plpgsql';

      CREATE TRIGGER check_contracts_purpose_is_not_null_t
      AFTER INSERT OR UPDATE
      ON contracts
      FOR EACH ROW
      EXECUTE PROCEDURE check_contracts_purpose_is_not_null_f();
    SQL
  end

  def down
    execute 'DROP FUNCTION IF EXISTS check_contracts_purpose_is_not_null_f'
    execute 'DROP TRIGGER IF EXISTS check_contracts_purpose_is_not_null_t ON contracts'
    execute <<~SQL
      UPDATE contracts
      SET purpose = ''
      WHERE purpose IS NULL
    SQL
    change_column(:contracts, :purpose, :text, null: false)
  end
end
