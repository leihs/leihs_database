class AddTransportableToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :transportable, :boolean, null: false, default: true
  end
end
