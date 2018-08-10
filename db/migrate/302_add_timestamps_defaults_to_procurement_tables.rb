class AddTimestampsDefaultsToProcurementTables < ActiveRecord::Migration[5.0]
  def change
    [:procurement_budget_periods,
     :procurement_requests,
     :procurement_settings].each do |table|
      change_column_default table, :created_at, -> { 'NOW()' }
      change_column_default table, :updated_at, -> { 'NOW()' }
    end
  end
end
