class AdditionalAuditedTables < ActiveRecord::Migration[7.0]
  include Leihs::MigrationHelper

  def up
    [:buildings,
      :disabled_fields,
      :fields,
      :options,
      :procurement_admins,
      :procurement_category_inspectors,
      :procurement_category_viewers,
      :procurement_requesters_organizations,
      :procurement_requests,
      :rooms,
      :suppliers].each do |table_name|
      execute "DROP TRIGGER IF EXISTS audited_change_on_#{table_name} ON #{table_name};"
      audit_table table_name
    end
  end
end
