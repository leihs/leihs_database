class AddConstraintsToProcurementMainCategories < ActiveRecord::Migration[5.0]
  def change
    change_table(:procurement_main_categories) do |t|
      reversible do |dir|
        dir.up do
          t.change :name, :string, null: false
        end
        dir.down do
          t.change :name, :string, null: true
        end
      end
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE procurement_main_categories
          ADD CONSTRAINT name_is_not_blank
          CHECK (name !~ '^\\s*$');
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE procurement_main_categories
          DROP CONSTRAINT name_is_not_blank
        SQL
      end
    end
  end
end
