class DateTimeWithTimeZoneForProcurementBudgetPeriods < ActiveRecord::Migration[5.0]
  COLUMNS = [:inspection_start_date, :end_date]

  def change
    reversible do |dir|
      dir.up do
        COLUMNS.each do |c|
          execute <<-SQL
            ALTER TABLE procurement_budget_periods
            ALTER COLUMN #{c} SET DATA TYPE timestamp with time zone;
          SQL
        end
      end
      dir.down do
        COLUMNS.each do |c|
          execute <<-SQL
            ALTER TABLE procurement_budget_periods
            ALTER COLUMN #{c} SET DATA TYPE date;
          SQL
        end
      end
    end
  end
end
