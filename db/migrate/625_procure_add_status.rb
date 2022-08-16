class ProcureAddStatus < ActiveRecord::Migration[5.0]
  def up
    # Rename the enum value 'not_procured' to 'not_processed' and re-add 'not_procured'
    execute <<~SQL
              ALTER TYPE order_status_enum RENAME TO order_status_enum_old;
              CREATE TYPE order_status_enum AS ENUM (
                'not_processed',
                'in_progress',
                'procured',
                'alternative_procured',
                'not_procured'
              );
              ALTER TABLE procurement_requests ALTER order_status DROP DEFAULT;
              ALTER TABLE procurement_requests ALTER COLUMN order_status TYPE order_status_enum USING order_status::text::order_status_enum;
              ALTER TABLE procurement_requests ALTER order_status SET DEFAULT 'not_processed'::order_status_enum;
              DROP TYPE order_status_enum_old;
              UPDATE procurement_requests SET order_status = 'not_processed' WHERE order_status = 'not_procured';    
            SQL
  end
end
