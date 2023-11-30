class UniqueBuildingsNamesAndCodes < ActiveRecord::Migration[6.1]
  class MigrationBuilding < ActiveRecord::Base
    self.table_name = 'buildings'
  end

  def change
    reversible do |dir|
      dir.up do
        MigrationBuilding.all.group_by(&:name).each_pair do |name, buildings|
          if buildings.count == 1
            next
          else
            buildings.each_with_index do |building, index|
              building.update!(name: "#{name} #{index + 1}")
            end
          end
        end

        MigrationBuilding.all.group_by(&:code).each_pair do |code, buildings|
          if buildings.count == 1
            next
          else
            buildings.each_with_index do |building, index|
              building.update!(code: "#{code}#{index + 1}")
            end
          end
        end
      end
    end

    add_index(:buildings, :name, unique: true)
    add_index(:buildings, :code, unique: true)
  end
end
