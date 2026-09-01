class InventoryCodeNotBlank < ActiveRecord::Migration[6.1]
  def up
    execute <<~'SQL'
      ALTER TABLE items
      ADD CONSTRAINT inventory_code_not_blank
      CHECK (inventory_code !~ '^\s*$')
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE items
      DROP CONSTRAINT inventory_code_not_blank
    SQL
  end
end
