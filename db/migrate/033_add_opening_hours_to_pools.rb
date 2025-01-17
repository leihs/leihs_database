class AddOpeningHoursToPools < ActiveRecord::Migration[7.2]
  def change
    [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday].each do |day|
      add_column :workdays, "#{day}_info", :text
    end
  end
end
