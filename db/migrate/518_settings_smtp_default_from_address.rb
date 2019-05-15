class SettingsSmtpDefaultFromAddress < ActiveRecord::Migration[5.0]
  def change
    add_column :settings,
               :smtp_default_from_address,
               :text,
               null: false,
               default: 'noreply@example.com'
  end
end
