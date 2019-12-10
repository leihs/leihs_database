class Suspensions < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  class Suspension < ActiveRecord::Base
  end

  class AccessRight < ActiveRecord::Base
  end

  def change

    create_table :suspensions, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :inventory_pool_id
      t.date :suspended_until, null: false, default: ->{"now() + INTERVAL '10000 years'"}
      t.text :suspended_reason
      t.index [:user_id, :inventory_pool_id], unique: true
      t.index [:suspended_until]
    end

    add_auto_timestamps :suspensions

    add_foreign_key :suspensions, :users
    add_foreign_key :suspensions, :inventory_pools

    reversible do |dir|
      dir.up do
        AccessRight \
          .where.not(suspended_until: nil) \
          .where("suspended_until >= ?", Date.today.iso8601) \
          .each do |ac|
            print("Migrating #{ac}")

            Suspension.create(
              created_at: ac.created_at,
              updated_at: ac.updated_at,
              suspended_until: ac.suspended_until,
              suspended_reason: ac.suspended_reason,
              user_id: ac.user_id,
              inventory_pool_id: ac.inventory_pool_id)

        end
      end
    end

    remove_column :access_rights, :suspended_until, :date
    remove_column :access_rights, :suspended_reason, :text

  end
end
