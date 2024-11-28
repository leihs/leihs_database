class AddWidthHeightToImages < ActiveRecord::Migration[7.2]
  def change
    add_column :images, :width, :integer
    add_column :images, :height, :integer
  end
end
