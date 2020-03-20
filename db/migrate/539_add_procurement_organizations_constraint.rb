class AddProcurementOrganizationsConstraint < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_parent_id_for_organization_id()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (
          SELECT true
          FROM procurement_organizations
          WHERE id = NEW.organization_id 
            AND parent_id IS NULL 
        ) THEN
          RAISE EXCEPTION 'Associated organization must have a parent.';
        END IF;

        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER trigger_check_parent_id_for_organization_id
      AFTER INSERT OR UPDATE
      ON procurement_requesters_organizations
      INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE PROCEDURE check_parent_id_for_organization_id()
    SQL
  end

  def down
    execute 'DROP TRIGGER trigger_check_parent_id_for_organization_id ON procurement_requesters_organizations'
    execute 'DROP FUNCTION IF EXISTS check_parent_id_for_organization_id()'
  end
end
