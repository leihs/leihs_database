class DeleteProcurementUsersFiltersTrigger < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      DROP TRIGGER IF EXISTS
        trigger_delete_procurement_users_filters_after_procurement_accesses
      ON procurement_requesters_organizations;

      DROP FUNCTION IF EXISTS
        delete_procurement_users_filters_after_procurement_accesses();
    SQL
  end
end
