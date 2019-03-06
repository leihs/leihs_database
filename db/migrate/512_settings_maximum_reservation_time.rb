class SettingsMaximumReservationTime < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    add_column :settings, :maximum_reservation_time, :integer
  end

end

