class AddNotNullConstraintsToProcurementUsersFilters < ActiveRecord::Migration[5.0]
  def change
    %w(user_id filter).each do |column|
      change_column_null :procurement_users_filters, column, false
    end

    add_foreign_key :procurement_users_filters, :users, on_delete: :cascade
  end
end
