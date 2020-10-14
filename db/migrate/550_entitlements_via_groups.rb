class EntitlementsViaGroups < ActiveRecord::Migration[5.0]
  def change

    reversible do |dir|

      dir.up do
        execute IO.read(
          Pathname(__FILE__).dirname.join("550_entitlements_via_groups_up.sql"))
      end

      dir.down do
        execute IO.read(
          Pathname(__FILE__).dirname.join("550_entitlements_via_groups_down.sql"))
      end

    end

  end
end
