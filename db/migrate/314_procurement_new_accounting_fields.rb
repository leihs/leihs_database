class ProcurementNewAccountingFields < ActiveRecord::Migration[5.0]
  def change
    add_column :procurement_categories, :procurement_account, :string 
  end
end
