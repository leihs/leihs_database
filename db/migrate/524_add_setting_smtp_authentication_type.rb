class AddSettingSmtpAuthenticationType< ActiveRecord::Migration[5.0]
  def change
    add_column :settings, :smtp_authentication_type, :text, default: 'plain'
  end
end
