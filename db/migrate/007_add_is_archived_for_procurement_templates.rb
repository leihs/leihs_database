class AddIsArchivedForProcurementTemplates < ActiveRecord::Migration[6.1]
  def change
    add_column(:procurement_templates, :is_archived, :boolean, default: false)

    reversible do |dir|
      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS check_if_template_is_used_when_updating_or_deleting_t ON procurement_templates;
          DROP FUNCTION IF EXISTS check_if_template_is_used_when_updating_or_deleting_f();
        SQL
      end
    end
  end
end
