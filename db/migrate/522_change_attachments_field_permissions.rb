class ChangeAttachmentsFieldPermissions < ActiveRecord::Migration[5.0]
  class MigrationField < ActiveRecord::Base
    self.table_name = 'fields'
  end

  def change
    f = MigrationField.find_by_id!('attachments')

    reversible do |dir|
      dir.up do
        f.data['permissions'].merge!('role' => 'lending_manager')
      end

      dir.down do
        f.data['permissions'].merge!('role' => 'inventory_manager')
      end
    end

    f.save!
  end
end
