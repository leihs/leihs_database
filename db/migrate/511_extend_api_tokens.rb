class ExtendApiTokens < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    add_column :api_tokens, :scope_system_admin_read, :boolean, default: :false, null: false
    add_column :api_tokens, :scope_system_admin_write, :boolean, default: :false, null: false
  end

end

