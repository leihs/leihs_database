class AddUniqueConstraintToEntitlements < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      ALTER TABLE entitlements
      ADD CONSTRAINT entitlements_group_model_unique
      UNIQUE (entitlement_group_id, model_id);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE entitlements
      DROP CONSTRAINT IF EXISTS entitlements_group_model_unique;
    SQL
  end
end
