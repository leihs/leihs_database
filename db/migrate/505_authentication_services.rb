class AuthenticationServices < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    execute <<-SQL.strip_heredoc
      DROP TABLE IF EXISTS authentication_systems CASCADE;
      DROP TABLE IF EXISTS database_authentications CASCADE;
    SQL


    create_table :authentication_systems, id: :varchar do |t|
      t.string :name, null: false
      t.text :description
      t.string :type, null: false
      t.boolean :enabled, null: false, default: false
      t.integer :priority, null: false, default: 0
      t.text :internal_private_key
      t.text :internal_public_key
      t.text :external_public_key
      t.text :external_url
      t.boolean :send_email, null: false, default: true
      t.boolean :send_org_id, null: false, default: false
      t.boolean :send_login, null: false, default: false
      t.boolean :send_auth_system_user_data, null: false, default: false
      t.boolean :shortcut_sign_in_enabled, null: false, default: false
    end

    execute <<-SQL.strip_heredoc
      ALTER TABLE authentication_systems ADD 
        CONSTRAINT simple_id 
        CHECK (id ~ '^[a-z][a-z0-9_-]*$');

      ALTER TABLE authentication_systems
        ADD CONSTRAINT check_valid_type 
        CHECK (type IN ('password', 'external'));

      ALTER TABLE authentication_systems
        ADD CONSTRAINT check_shortcut_sing_in 
        CHECK (shortcut_sign_in_enabled = false OR type = 'external');
    SQL

    add_auto_timestamps :authentication_systems


    ### auth systems users #################################################################################
    #
    create_table :authentication_systems_users, id: :uuid do |t|
      t.uuid :user_id, null: false, index: true
      t.text :data
      t.string :authentication_system_id, null: false, index: true
    end
    add_index :authentication_systems_users, [:user_id, :authentication_system_id], unique: true, name: "idx_auth_sys_users"
    add_auto_timestamps :authentication_systems_users, updated_at: false

    add_auto_timestamps :authentication_systems_users

    add_foreign_key :authentication_systems_users, :users, on_delete: :cascade
    add_foreign_key :authentication_systems_users, :authentication_systems


    execute <<-SQL.strip_heredoc
      CREATE FUNCTION seed_authentication_systems() 
      RETURNS trigger AS $$
        BEGIN
          INSERT INTO authentication_systems(id, name, type, enabled) 
            VALUES ('password', 'leihs password', 'password', true)
            ON CONFLICT (id)
            DO UPDATE SET type = 'password';
          RETURN NEW;
        END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER seed_authentication_systems_on_authentication_systems_users
        BEFORE INSERT OR UPDATE ON authentication_systems_users
          FOR EACH STATEMENT EXECUTE PROCEDURE seed_authentication_systems();

    SQL


    ### auth systems groups ################################################################################

    create_table :authentication_systems_groups, id: :uuid do |t|
      t.uuid :group_id, null: false, index: true
      t.string :authentication_system_id, null: false, index: true
    end
    add_index :authentication_systems_groups, [:group_id, :authentication_system_id], unique: true, name: "idx_auth_sys_groups"
    add_auto_timestamps :authentication_systems_groups, updated_at: false

    add_auto_timestamps :authentication_systems_groups

    add_foreign_key :authentication_systems_groups, :groups, on_delete: :cascade
    add_foreign_key :authentication_systems_groups, :authentication_systems

  end


  def down

    drop_table :system_admins
    drop_table :authentication_systems_groups
    drop_table :authentication_systems_users
    drop_table :authentication_systems

  end

end
