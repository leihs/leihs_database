class RejectReasonNotBlank < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      ALTER TABLE orders
      ADD CONSTRAINT reject_reason_not_blank
      CHECK (reject_reason IS NULL OR reject_reason !~ '^\s*$')
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE orders
      DROP CONSTRAINT reject_reason_not_blank
    SQL
  end
end
