class ProcurementCascadesAndFks < ActiveRecord::Migration[6.1]

  def up
    execute <<~SQL
      DELETE FROM procurement_requesters_organizations
      WHERE NOT EXISTS (
        SELECT TRUE
        FROM users
        WHERE procurement_requesters_organizations.user_id = users.id
      )
    SQL

    add_foreign_key(:procurement_requesters_organizations, :users, on_delete: :cascade)

    execute <<~SQL
      DELETE FROM procurement_category_viewers
      WHERE NOT EXISTS (
        SELECT TRUE
        FROM users
        WHERE procurement_category_viewers.user_id = users.id
      )
    SQL

    remove_foreign_key(:procurement_category_viewers, :users)
    add_foreign_key(:procurement_category_viewers, :users, on_delete: :cascade)

    execute <<~SQL
      DELETE FROM procurement_category_inspectors
      WHERE NOT EXISTS (
        SELECT TRUE
        FROM users
        WHERE procurement_category_inspectors.user_id = users.id
      )
    SQL

    remove_foreign_key(:procurement_category_inspectors, :users)
    add_foreign_key(:procurement_category_inspectors, :users, on_delete: :cascade)
  end

  def down
    remove_foreign_key(:procurement_requesters_organizations, :users)
    remove_foreign_key(:procurement_category_viewers, :users)
    remove_foreign_key(:procurement_category_inspectors, :users)
  end

end
