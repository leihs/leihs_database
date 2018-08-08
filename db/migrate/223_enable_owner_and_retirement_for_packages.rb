class EnableOwnerAndRetirementForPackages < ActiveRecord::Migration[5.0]

  class MigrationField < ActiveRecord::Base
    self.table_name = 'fields'
  end

  def change
    execute 'alter table fields disable trigger fields_update_check_trigger'

    MigrationField.reset_column_information

    [
      'owner_id',
      'retired',
      'retired_reason'
    ].each do |field_id|
      field = MigrationField.unscoped.find(field_id)
      field.data['forPackage'] = true
      field.save!
    end

    execute 'alter table fields enable trigger fields_update_check_trigger'
  end
end
