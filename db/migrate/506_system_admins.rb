class SystemAdmins < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    execute <<-SQL.strip_heredoc
      CREATE TABLE system_admin_users ( 
        user_id UUID NOT NULL
        );

      ALTER TABLE ONLY system_admin_users ADD CONSTRAINT system_admin_users_pkey PRIMARY KEY (user_id);

      ALTER TABLE ONLY system_admin_users ADD CONSTRAINT fkey_system_admin_users_users
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


      CREATE TABLE system_admin_groups ( 
        group_id UUID NOT NULL
        );

      ALTER TABLE ONLY system_admin_groups ADD CONSTRAINT system_admin_groups_pkey PRIMARY KEY (group_id);

      ALTER TABLE ONLY system_admin_groups ADD CONSTRAINT fkey_system_admin_groups_groups
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;

    SQL

  end


  def down

    drop_table :system_admin_users
    drop_table :system_admin_groups

  end

end

