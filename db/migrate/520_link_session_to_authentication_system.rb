class LinkSessionToAuthenticationSystem < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change
    reversible do |dir|
      dir.up do
        execute 'DELETE FROM user_sessions;'
      end
    end
		rename_column :authentication_systems, :external_url, :external_sign_in_url
		add_column :authentication_systems, :external_sign_out_url, :text
    add_column :user_sessions, :authentication_system_id, :text, null: false
    add_foreign_key :user_sessions, :authentication_systems, on_delete: :cascade
  end

end
