class RemoveSeedAuthenticationSystemsTrigger < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      DROP TRIGGER IF EXISTS seed_authentication_systems_on_authentication_systems_users ON authentication_systems_users;
      DROP FUNCTION IF EXISTS seed_authentication_systems();
    SQL
  end
end
