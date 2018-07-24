class ProcurementCategoryViewers < ActiveRecord::Migration[5.0]
  def change
    create_table :procurement_category_viewers, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.uuid :category_id, null: false
      t.index [:user_id, :category_id], unique: true, name: :idx_procurement_category_viewers_uc
    end
    add_foreign_key :procurement_category_viewers, :users
    add_foreign_key(:procurement_category_viewers,
                    :procurement_categories,
                    column: :category_id,
                    on_delete: :cascade)

    #############################################################

    # reversible do |dir|
    #   dir.up do 
    #     add_foreign_key(:procurement_category_viewers,
    #                     :procurement_categories,
    #                     column: :category_id,
    #                     on_delete: :cascade)
    #   end
    #   dir.down do
    #     add_foreign_key(:procurement_category_viewers,
    #                     :procurement_categories,
    #                     column: :category_id)
    #   end
    # end
  end
end
