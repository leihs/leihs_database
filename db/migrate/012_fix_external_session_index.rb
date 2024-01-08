class FixExternalSessionIndex < ActiveRecord::Migration[6.1]
  def up
    remove_index :user_sessions, [:authentication_system_id, :external_session_id],
          :unique => true, name: :index_auth_system_ext_session

    add_index :user_sessions, [:authentication_system_id, :external_session_id],
      :unique => false, name: :index_auth_system_ext_session

  end
end
