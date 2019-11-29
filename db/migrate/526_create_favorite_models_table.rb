class CreateFavoriteModelsTable < ActiveRecord::Migration[5.0]
  def change
    create_table(:favorite_models, id: false) do |t|
      t.uuid(:user_id, null: false)
      t.uuid(:model_id, null: false)
      t.timestamps(null: false, default: -> { 'now()' })
    end

    add_foreign_key(:favorite_models, :users, on_delete: :cascade)
    add_foreign_key(:favorite_models, :models, on_delete: :cascade)

    add_index(:favorite_models, [:user_id, :model_id], unique: true)
  end
end
