class EntitlementsGroups < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    create_table :entitlement_groups_groups, id: :uuid do |t|
      t.uuid :group_id, null: false
      t.index :group_id
      t.uuid :entitlement_group_id, null: false
      t.index :entitlement_group_id
      t.index [:entitlement_group_id, :group_id], unique: true,
        name: :entitlement_groups_groups_idx
    end
    add_foreign_key :entitlement_groups_groups, :entitlement_groups
    add_foreign_key :entitlement_groups_groups, :groups
    add_auto_timestamps :entitlement_groups_groups

  end
end
