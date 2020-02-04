class MaxVisitsJson < ActiveRecord::Migration[5.0]
  class Workday < ActiveRecord::Base
  end

  def up
    add_column :workdays, :max_visits_json, :jsonb

    Workday.where.not(max_visits: nil).in_batches do |workdays|
      workdays.each do |workday|
        max_visits = YAML.load(workday.max_visits).try do |m| 
          m.map do |k, v|
            [k, v.to_s.force_encoding('utf-8').presence]
          end.compact.to_h
        end
        workday.update_columns max_visits_json: max_visits
      end
    end

    remove_column :workdays, :max_visits
    rename_column :workdays, :max_visits_json, :max_visits
  end
end
