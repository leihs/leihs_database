class AddConstraintsToHolidays < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      ALTER TABLE holidays
      ADD CONSTRAINT end_date_after_start_date
      CHECK (end_date >= start_date)
    SQL

    execute <<~SQL
      UPDATE holidays
      SET name = 'TODO: Set a name'
      WHERE name IS NULL
    SQL

    change_column_null :holidays, :name, false
    change_column_null :holidays, :start_date, false
    change_column_null :holidays, :end_date, false
    change_column_null :holidays, :inventory_pool_id, false
  end

  def down
    execute <<~SQL
      ALTER TABLE holidays
      DROP CONSTRAINT end_date_after_start_date
    SQL
    change_column_null :holidays, :name, true
    change_column_null :holidays, :start_date, true
    change_column_null :holidays, :end_date, true
    change_column_null :holidays, :inventory_pool_id, true
  end
end
