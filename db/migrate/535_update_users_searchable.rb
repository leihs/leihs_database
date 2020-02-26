class UpdateUsersSearchable < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper
  def change
    reversible do |dir|
      dir.up do
        execute " DROP TRIGGER IF EXISTS update_searchable_column_of_users ON users"
      end
    end
    auto_update_searchable :users, [:firstname, :lastname, :email, :login, :badge_id, :org_id, :lastname, :firstname]
  end
end
