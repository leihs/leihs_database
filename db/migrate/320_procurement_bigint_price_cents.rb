class ProcurementBigintPriceCents < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      ALTER TABLE procurement_requests
      ALTER COLUMN price_cents
      SET DATA TYPE bigint
    SQL

    execute <<-SQL
      ALTER TABLE procurement_requests
      ADD CONSTRAINT check_max_javascript_int
      CHECK (price_cents < 2^52) 
    SQL
  end
end
