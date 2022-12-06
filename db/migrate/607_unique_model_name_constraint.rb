class UniqueModelNameConstraint < ActiveRecord::Migration[5.0]
  class MigrationModel < ActiveRecord::Base
    self.inheritance_column = nil
    self.table_name = 'models'

    def name
      [product, version].compact.join(' ')
    end
  end

  def up
    MigrationModel.all.group_by(&:name).each_pair do |name, models|
      next if models.count == 1
      models.sort_by(&:created_at).each_with_index do |model, index|
        version = [model.version.presence, index.succ.to_i].compact.join(" ")
        model.update!(version: version)
      end
    end

    execute <<~SQL
      CREATE UNIQUE INDEX unique_model_name_idx ON models
      ((models.product || ' ' || COALESCE(models.version, '')))
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX unique_model_name_idx
    SQL
  end
end
