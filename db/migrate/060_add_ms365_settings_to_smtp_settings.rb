class AddMs365SettingsToSmtpSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :smtp_settings, :ms365_enabled, :boolean, default: false, null: false
    add_column :smtp_settings, :ms365_client_id, :text
    add_column :smtp_settings, :ms365_tenant_id, :text
    add_column :smtp_settings, :ms365_client_secret, :text

    add_column :smtp_settings, :ms365_token_url, :text,
      default: "https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token", null: false
    add_column :smtp_settings, :ms365_graph_send_url, :text,
      default: "https://graph.microsoft.com/v1.0/users/{user_id}/sendMail", null: false

    add_column :smtp_settings, :ms365_auth_mode, :text, default: "delegated", null: false
    add_check_constraint :smtp_settings,
      "ms365_auth_mode IN ('delegated', 'rbac')",
      name: "ms365_auth_mode_valid_values"
  end
end
