class ProcurementMigrateInspectorsToRequesters < ActiveRecord::Migration[5.0]
  class MigrationProcurementInspector < ActiveRecord::Base
    self.table_name = :procurement_category_inspectors
  end

  class MigrationProcurementRequester < ActiveRecord::Base
    self.table_name = :procurement_requesters_organizations
  end

  class MigrationProcurementOrganization < ActiveRecord::Base
    self.table_name = :procurement_organizations
  end

  def change
    dep_tbd = MigrationProcurementOrganization.find_or_create_by(name: 'tbd',
                                                                 parent_id: nil)
    org_tbd = MigrationProcurementOrganization.find_or_create_by(name: 'tbd',
                                                                 parent_id: dep_tbd.id)

    MigrationProcurementInspector.all.each do |pi|
      unless MigrationProcurementRequester.find_by_user_id(pi.user_id)
        MigrationProcurementRequester.create!(user_id: pi.user_id,
                                              organization_id: org_tbd.id)
      end
    end
  end
end
