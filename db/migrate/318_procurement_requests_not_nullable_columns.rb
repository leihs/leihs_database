class ProcurementRequestsNotNullableColumns < ActiveRecord::Migration[5.0]
  def change
    [:motivation, :replacement].each do |c|
      change_column_null :procurement_requests, c, false
    end
  end
end
