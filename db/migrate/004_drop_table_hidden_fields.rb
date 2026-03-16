class DropTableHiddenFields < ActiveRecord::Migration[6.1]
  def up
    drop_table :hidden_fields, if_exists: true
  end

  def down
    create_table :hidden_fields, id: :uuid, default: -> { "uuid_generate_v4()" } do |t|
      t.string :field_id
      t.uuid :user_id
    end

    add_foreign_key :hidden_fields, :users, column: :user_id, on_delete: :cascade
    add_foreign_key :hidden_fields, :fields, column: :field_id, on_delete: :cascade
  end
end
