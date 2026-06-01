class AddUpdatedAtTriggerToOrders < ActiveRecord::Migration[7.2]
  include Leihs::MigrationHelper

  def change
    add_auto_timestamps :orders, created_at: false
  end
end
