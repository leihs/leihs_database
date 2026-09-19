require "securerandom"

class InventoryCodeNotBlank < ActiveRecord::Migration[7.2]
  def up
    say_with_time "Backfilling blank inventory_code values" do
      rows = select_all(<<~SQL)
        SELECT id FROM items WHERE inventory_code ~ '^\s*$'
      SQL

      ids = rows.map { |row| row["id"] }

      ids.each do |id|
        execute <<~SQL
          UPDATE items SET inventory_code = #{quote("BLANK_#{SecureRandom.hex(5)}")}
          WHERE id = #{quote(id)}
        SQL
      end

      say "inventory_code backfill summary: #{ids.size} row(s) updated"
      ids.size
    end

    execute <<~SQL
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
