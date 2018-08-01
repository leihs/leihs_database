class ProcurementRequestsNotNullableColumns < ActiveRecord::Migration[5.0]
  def change
    change_column :procurement_requests, :replacement, :boolean, null: false
  end
end
