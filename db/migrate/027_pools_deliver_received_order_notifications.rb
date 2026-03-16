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

  def down
    add_column :settings, :deliver_received_order_notifications, :boolean unless column_exists?(:settings, :deliver_received_order_notifications)

    if column_exists?(:inventory_pools, :deliver_received_order_emails) &&
        column_exists?(:settings, :deliver_received_order_notifications)
      execute <<~SQL
        UPDATE settings
        SET deliver_received_order_notifications = COALESCE(source.any_enabled, false)
        FROM (
          SELECT BOOL_OR(deliver_received_order_emails) AS any_enabled
          FROM inventory_pools
        ) AS source
        WHERE settings.id = 0
      SQL
    end

    remove_column :inventory_pools, :deliver_received_order_emails if column_exists?(:inventory_pools, :deliver_received_order_emails)
  end
end
