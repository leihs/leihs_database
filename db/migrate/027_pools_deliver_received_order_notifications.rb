class PoolsDeliverReceivedOrderNotifications < ActiveRecord::Migration[7.2]
  def up
    add_column :inventory_pools, :deliver_received_order_emails, :boolean, null: false, default: false
    execute <<~SQL
      UPDATE inventory_pools
      SET deliver_received_order_emails = settings.deliver_received_order_notifications
      FROM settings
    SQL
    remove_column :settings, :deliver_received_order_notifications
  end
end
