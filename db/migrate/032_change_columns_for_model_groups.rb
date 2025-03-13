class ChangeColumnsForModelGroups < ActiveRecord::Migration[7.2]
  def change
    change_column_default :model_groups, :created_at, -> { "now()" }
    change_column_default :model_groups, :updated_at, -> { "now()" }

    change_column_null :model_group_links, :parent_id, false
    change_column_null :model_group_links, :child_id, false
  end
end
