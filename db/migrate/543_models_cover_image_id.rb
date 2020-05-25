class ModelsCoverImageId < ActiveRecord::Migration[5.0]
  def change
    add_column(:models, :cover_image_id, :uuid)
    add_foreign_key(:models, :images, column: :cover_image_id, on_delete: :cascade)
  end
end
