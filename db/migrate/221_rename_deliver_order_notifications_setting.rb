class RenameDeliverOrderNotificationsSetting < ActiveRecord::Migration[5.0]
  def change
    rename_column :settings, :deliver_order_notifications, :deliver_received_order_notifications
  end
end
