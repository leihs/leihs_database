class AllowQuantityAllocationsForAllLicenseTypes < ActiveRecord::Migration[4.2]

  class MigrationField < ActiveRecord::Base
    self.table_name = 'fields'
    serialize :data, JSON
  end

  def up
    # Before:
    # {
    #   label: 'Total quantity',
    #   attribute: ['properties', 'total_quantity'],
    #   type: 'text',
    #   target_type: 'license',
    #   permissions: {
    #     role: 'inventory_manager',
    #     owner: true
    #   },
    #   visibility_dependency_field_id: 'properties_license_type',
    #   visibility_dependency_value: [
    #     'multiple_workplace', 'site_license', 'concurrent'
    #   ],
    #   group: 'General Information'
    # }

    # Now:
    # The dependencies were:
    #   properties_quantity_allocations depends on properties_total_quantity
    #   properties_total_quantity depends on properties_license_type
    # We leave the first one, and remove the second one.
    field = MigrationField.find('properties_total_quantity')
    field.data = {
      label: 'Total quantity',
      attribute: ['properties', 'total_quantity'],
      type: 'text',
      target_type: 'license',
      permissions: {
        role: 'inventory_manager',
        owner: true
      },
      group: 'General Information'
    }
    field.save!
  end
end
