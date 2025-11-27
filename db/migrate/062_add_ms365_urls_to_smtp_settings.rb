class AddMs365UrlsToSmtpSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :smtp_settings, :m365_token_url, :text,
      default: "https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token", null: false
    add_column :smtp_settings, :m365_graph_send_url, :text,
      default: "https://graph.microsoft.com/v1.0/users/{user_id}/sendMail", null: false
  end
end
