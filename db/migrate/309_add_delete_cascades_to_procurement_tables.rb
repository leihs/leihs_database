class AddDeleteCascadesToProcurementTables < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do 
        remove_foreign_key(:procurement_budget_limits,
                           :procurement_main_categories)
      end
      dir.down do
        add_foreign_key(:procurement_budget_limits,
                        :procurement_main_categories,
                        column: :main_category_id)

      end
    end

    add_foreign_key(:procurement_budget_limits,
                    :procurement_main_categories,
                    column: :main_category_id,
                    on_delete: :cascade)

    #############################################################

    reversible do |dir|
      dir.up do 
        remove_foreign_key(:procurement_budget_limits,
                           :procurement_budget_periods)
      end
      dir.down do
        add_foreign_key(:procurement_budget_limits,
                        :procurement_budget_periods,
                        column: :budget_period_id)

      end
    end

    add_foreign_key(:procurement_budget_limits,
                    :procurement_budget_periods,
                    column: :budget_period_id,
                    on_delete: :cascade)

    #############################################################

    reversible do |dir|
      dir.up do 
        remove_foreign_key(:procurement_categories,
                           :procurement_main_categories)
      end
      dir.down do
        add_foreign_key(:procurement_categories,
                        :procurement_main_categories,
                        column: :main_category_id)

      end
    end

    add_foreign_key(:procurement_categories,
                    :procurement_main_categories,
                    column: :main_category_id,
                    on_delete: :cascade)

    #############################################################

    reversible do |dir|
      dir.up do 
        remove_foreign_key(:procurement_category_inspectors,
                           :procurement_categories)
      end
      dir.down do
        add_foreign_key(:procurement_category_inspectors,
                        :procurement_categories,
                        column: :category_id)

      end
    end

    add_foreign_key(:procurement_category_inspectors,
                    :procurement_categories,
                    column: :category_id,
                    on_delete: :cascade)

    #############################################################

    reversible do |dir|
      dir.up do 
        remove_foreign_key(:procurement_images,
                           :procurement_main_categories)
      end
      dir.down do
        add_foreign_key(:procurement_images,
                        :procurement_main_categories,
                        column: :main_category_id)

      end
    end

    add_foreign_key(:procurement_images,
                    :procurement_main_categories,
                    column: :main_category_id,
                    on_delete: :cascade)

  end
end
