class DelegationsGroups < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    create_table :delegations_groups, id: :uuid do |t|
      t.uuid :group_id, null: false
      t.index :group_id
      t.uuid :delegation_id, null: false
      t.index :delegation_id
      t.index [:delegation_id, :group_id], unique: true,
        name: :delegations_groups_idx
    end
    add_foreign_key :delegations_groups, :users, column: :delegation_id
    add_foreign_key :delegations_groups, :groups
    add_auto_timestamps :delegations_groups

  end
end
