class AccessRightsIndex < ActiveRecord::Migration[5.0]
  def change
    add_index(:access_rights,
              [:inventory_pool_id, :user_id],
              unique: true,
              name: :index_access_rights_on_pool_id_and_user_id)
  end
end
