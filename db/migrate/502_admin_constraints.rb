class AdminConstraints < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change

    add_index :users, :org_id,
      name: :users_org_id_idx,
      unique: true

    add_index :users, 'lower(email)',
      name: :users_email_idx,
      unique: true
  end

end


