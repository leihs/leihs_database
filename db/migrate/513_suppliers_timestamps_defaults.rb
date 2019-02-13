class SuppliersTimestampsDefaults < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      ALTER TABLE suppliers
      ALTER COLUMN updated_at SET DEFAULT now(),
      ALTER COLUMN created_at SET DEFAULT now()
    SQL
  end
end
