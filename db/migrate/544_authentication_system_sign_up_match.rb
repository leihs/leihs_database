class AuthenticationSystemSignUpMatch< ActiveRecord::Migration[5.0]
  def change
    add_column :authentication_systems, :sign_up_email_match, :text
    remove_column :authentication_systems, :send_auth_system_user_data, :boolean, default: false
  end
end
