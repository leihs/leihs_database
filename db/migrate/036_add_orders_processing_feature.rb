class AddOrdersProcessingFeature < ActiveRecord::Migration[7.2]
  class MigrationWorkday < ActiveRecord::Base
    self.table_name = :workdays
  end

  DAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  def up
    DAYS.each do |day|
      if [:saturday, :sunday].include?(day)
        add_column :workdays, "#{day}_orders_processing", :boolean, null: false, default: false
      else
        add_column :workdays, "#{day}_orders_processing", :boolean, null: false, default: true
      end
    end

    add_column :holidays, :orders_processing, :boolean, null: false, default: false

    MigrationWorkday.all.each do |workday|
      DAYS.each do |day|
        workday.update_column("#{day}_orders_processing", workday.send(day))
      end
    end

    execute <<~SQL
      ALTER TABLE workdays
      ADD CONSTRAINT check_orders_processing
      CHECK (
        NOT (monday AND NOT monday_orders_processing) AND
        NOT (tuesday AND NOT tuesday_orders_processing) AND
        NOT (wednesday AND NOT wednesday_orders_processing) AND
        NOT (thursday AND NOT thursday_orders_processing) AND
        NOT (friday AND NOT friday_orders_processing) AND
        NOT (saturday AND NOT saturday_orders_processing) AND
        NOT (sunday AND NOT sunday_orders_processing)
      )
    SQL
  end

  def down
    remove_column :holidays, :orders_processing

    DAYS.each do |day|
      remove_column :workdays, "#{day}_orders_processing"
    end

    execute <<~SQL
      ALTER TABLE workdays
      DROP CONSTRAINT check_orders_processing
    SQL
  end
end
