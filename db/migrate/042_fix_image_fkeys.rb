class FixImageFkeys < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :images, :images, column: :parent_id
    remove_foreign_key :models, :images, column: :cover_image_id
    add_foreign_key :images, :images, column: :parent_id, on_delete: :cascade
    add_foreign_key :models, :images, column: :cover_image_id, on_delete: :nullify
  end
end
