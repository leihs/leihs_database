class RemoveProcurementImagesThumbnails < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      DELETE FROM procurement_images
      WHERE parent_id IS NOT NULL
    SQL

    remove_column :procurement_images, :parent_id
  end
end
