class AddTimestampsToOptions < ActiveRecord::Migration[7.2]
  def change
    add_auto_timestamps :options, created_at_null: false, timezone: false
  end
end
