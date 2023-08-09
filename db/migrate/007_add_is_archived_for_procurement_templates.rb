class AddIsArchivedForProcurementTemplates < ActiveRecord::Migration[6.1]
  def change
    add_column(:procurement_templates, :is_archived, :boolean, default: false)

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE OR REPLACE FUNCTION check_if_template_is_used_when_updating_or_deleting_f()
          RETURNS TRIGGER AS $$
          BEGIN
            IF ( EXISTS ( SELECT TRUE FROM procurement_requests pr WHERE pr.template_id = NEW.id ) ) THEN
              RAISE EXCEPTION 'The template has already been used by one or more requests.';
            END IF;
            RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<~SQL
          CREATE TRIGGER check_if_template_is_used_when_updating_or_deleting_t
          AFTER UPDATE
          ON procurement_templates
          FOR EACH ROW
          EXECUTE PROCEDURE check_if_template_is_used_when_updating_or_deleting_f();
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS check_if_template_is_used_when_updating_or_deleting_t ON procurement_templates;
          DROP FUNCTION IF EXISTS check_if_template_is_used_when_updating_or_deleting_f();
        SQL
      end
    end
  end
end
