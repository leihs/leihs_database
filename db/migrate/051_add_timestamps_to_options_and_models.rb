class AddTimestampsToOptionsAndModels < ActiveRecord::Migration[7.2]
  include Leihs::MigrationHelper

  def change
    add_auto_timestamps :options, timezone: false, table_with_autogen_columns: true
    # adds only updated_at update trigger
    add_auto_timestamps :models, created_at: false, updated_at: false,
      updated_at_trigger: true, table_with_autogen_columns: true
  end
end
