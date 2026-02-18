class AddMs365AuthMode < ActiveRecord::Migration[7.2]
  def change
    add_column :smtp_settings, :ms365_auth_mode, :text, default: "delegated", null: false
    add_check_constraint :smtp_settings,
      "ms365_auth_mode IN ('delegated', 'rbac')",
      name: "ms365_auth_mode_valid_values"
  end
end
