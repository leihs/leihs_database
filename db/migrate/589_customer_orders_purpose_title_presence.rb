class CustomerOrdersPurposeTitlePresence < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE customer_orders
      ADD CONSTRAINT non_blank_title CHECK ( title !~ '^\s*$' ),
      ADD CONSTRAINT non_blank_purpose CHECK ( purpose !~ '^\s*$' )
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE customer_orders
      DROP CONSTRAINT non_blank_title,
      DROP CONSTRAINT non_blank_purpose
    SQL
  end
end
