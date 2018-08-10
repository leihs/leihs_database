class AddNotNullConstraintsToProcurementRequests < ActiveRecord::Migration[5.0]
  def change
    %w(budget_period_id category_id organization_id user_id).each do |column|
      change_column_null :procurement_requests, column, false
    end
  end
end
