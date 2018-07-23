class AddUniqueConstraintsOnProcurementOrganizations < ActiveRecord::Migration[5.0]
  def change
    add_index :procurement_organizations, [:name, :parent_id]
    change_column_null :procurement_organizations, :name, false
  end
end
