class Groups < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    create_table :groups, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :org_id
      t.index :org_id, unique: true
      t.text :searchable
    end


    auto_update_searchable :groups, [:name, :org_id]

    add_auto_timestamps :groups

    create_table :groups_users, id: :uuid do |t|
      t.uuid :user_id, null: false, index: true
      t.uuid :group_id, null: false, index: true
    end
    add_index :groups_users, [:user_id, :group_id], unique: true
    add_auto_timestamps :groups_users, updated_at: false

    add_foreign_key :groups_users, :users, on_delete: :cascade
    add_foreign_key :groups_users, :groups, on_delete: :cascade

  end


  def down

    drop_table :groups_users
    drop_table :groups

  end

end

