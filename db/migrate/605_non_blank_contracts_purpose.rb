class NonBlankContractsPurpose < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      ALTER TABLE contracts
      ADD CONSTRAINT non_blank_purpose CHECK ( purpose !~ '^\s*$' )
    SQL
  end

  def down
    execute 'ALTER TABLE contracts DROP CONSTRAINT non_blank_purpose'
  end
end
