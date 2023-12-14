class UniqueBuildingsNamesAndCodes < ActiveRecord::Migration[6.1]
  class MigrationBuilding < ActiveRecord::Base
    self.table_name = 'buildings'
    has_many(:rooms, class_name: 'MigrationRoom', foreign_key: :building_id)
  end

  class MigrationRoom < ActiveRecord::Base
    self.table_name = 'rooms'
    has_many(:items, class_name: 'MigrationItem', foreign_key: :room_id)
    has_many(:procurement_requests, class_name: 'MigrationProcurementRequest', foreign_key: :room_id)
  end

  class MigrationItem < ActiveRecord::Base
    self.table_name = 'items'
  end

  class MigrationProcurementRequest < ActiveRecord::Base
    self.table_name = 'procurement_requests'
  end

  def change
    reversible do |dir|
      dir.up do
        MigrationBuilding.all.group_by(&:name).each_pair do |name, buildings|
          if buildings.count == 1
            next
          else
            to_keep_building = buildings.first
            to_delete_buildings = buildings.drop(1)
            to_keep_general_room = to_keep_building.rooms.detect(&:general?)

            to_delete_buildings.each do |to_delete_building|
              to_delete_building.rooms.each do |to_delete_room|
                target_room = if to_delete_room.general?
                                to_keep_general_room
                              else
                                to_keep_building.rooms.detect { |r| r.name == to_delete_room.name }
                              end

                if target_room
                  to_delete_room.items.update_all(room_id: target_room.id)
                  to_delete_room.procurement_requests.update_all(room_id: target_room.id)
                else
                  to_delete_room.update!(building_id: to_keep_building.id)
                end

              end
              to_delete_building.destroy! # destroy the rooms too
            end
            
            items_count = to_keep_building.rooms.map(&:items).flatten.count
          end
        end

        MigrationBuilding.all.each do |b|
          if b.code.nil?
            c = if b.name.split(" ").count > 1
                  b.name.split(" ").map do |x|
                    if ["(", "["].include?(x[0])
                      x[1]
                    else
                      x[0]
                    end
                  end.join.upcase
                else
                  b.name.slice(0..2).upcase
                end
            b.update!(code: c)
          else
            next
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
