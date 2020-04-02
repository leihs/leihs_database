class FixMaxVisitsJson < ActiveRecord::Migration[5.0]
  class Workday < ActiveRecord::Base
  end

  def up
    add_column :workdays, :max_visits_json, :jsonb

    Workday.all.each do |workday|
      if workday.max_visits.blank?
        workday.update_columns(max_visits_json: {})
      else
        begin
          max_visits = YAML.load(workday.max_visits).try do |m| 
            m.map do |k, v|
              [k, v.to_s.force_encoding('utf-8').presence]
            end.compact.to_h
          end
          workday.update_columns(max_visits_json: max_visits)
        rescue
          workday.update_columns(max_visits_json: workday.max_visits)
        end
      end
    end
    
    remove_column :workdays, :max_visits
    rename_column :workdays, :max_visits_json, :max_visits
    change_column :workdays, :max_visits, :jsonb, default: {}

    [[:inventory_pool_id, :uuid],
     [:monday, :boolean],
     [:tuesday, :boolean],
     [:wednesday, :boolean],
     [:thursday, :boolean],
     [:friday, :boolean],
     [:saturday, :boolean],
     [:sunday, :boolean],
     [:reservation_advance_days, :integer],
     [:max_visits, :jsonb]].each do |col, type|
       change_column :workdays, col, type, null: false
     end
  end
end
