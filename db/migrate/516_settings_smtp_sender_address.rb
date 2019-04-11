class SettingsSmtpSenderAddress < ActiveRecord::Migration[5.0]
  def change
    add_column :settings, :smtp_sender_address, :text
  end
end
