class AddExternalSessionId < ActiveRecord::Migration[6.1]

  def change
    reversible do |dir|
      dir.up do
        add_column :user_sessions, :external_session_id, :text
        add_index :user_sessions, [:authentication_system_id, :external_session_id],
          :unique => true, name: :index_auth_system_ext_session
      end
      dir.down do
        remove_column :user_sessions, :external_session_id, :text
      end
    end
  end

end
