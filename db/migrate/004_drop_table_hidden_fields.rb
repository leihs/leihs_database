class DropTableHiddenFields < ActiveRecord::Migration[6.1]
  def up
    drop_table :hidden_fields
  end
end
