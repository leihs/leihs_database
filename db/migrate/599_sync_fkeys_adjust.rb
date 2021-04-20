class SyncFkeysAdjust < ActiveRecord::Migration[5.0]
  def up
    remove_foreign_key(:group_access_rights, :groups)
    add_foreign_key(:group_access_rights, :groups, on_delete: :cascade)

    add_column :system_and_security_settings, :instance_element, :text
  end
end
