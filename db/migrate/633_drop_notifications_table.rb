class DropNotificationsTable < ActiveRecord::Migration[6.1]

  def up
    drop_table :notifications
  end

end

