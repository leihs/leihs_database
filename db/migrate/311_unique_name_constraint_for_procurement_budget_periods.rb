class UniqueNameConstraintForProcurementBudgetPeriods < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE UNIQUE INDEX unique_name_procurement_budget_periods
          ON procurement_budget_periods (LOWER(name));
        SQL
      end
      
      dir.down do
        execute <<-SQL
          DROP INDEX unique_name_procurement_budget_periods;
        SQL
      end
    end
  end
end
