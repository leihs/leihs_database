class AddMs365SettingsToSmtpSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :smtp_settings, :ms365_enabled, :boolean, default: false, null: false
    add_column :smtp_settings, :ms365_client_id, :text
    add_column :smtp_settings, :ms365_tenant_id, :text
    add_column :smtp_settings, :ms365_client_secret, :text
  end
end
