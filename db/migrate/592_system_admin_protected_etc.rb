class SystemAdminProtectedEtc < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    # add is_system_admin col and remove system_admins table

    add_column :users, :is_system_admin, :boolean, default: false, null: false

    execute <<-SQL.strip_heredoc
          UPDATE users SET is_system_admin = true
            WHERE exists (SELECT true FROM system_admin_users
                            WHERE user_id = users.id);
    SQL

    drop_table :system_admin_users

    add_column :users, :pool_protected, :boolean, default: false, null: false

    add_column :users, :system_admin_protected, :boolean, default: false, null: false
    rename_column :users, :protected, :admin_protected

    execute <<-SQL.strip_heredoc
      UPDATE users SET is_admin = true WHERE is_system_admin = true;

      ALTER TABLE users ADD CONSTRAINT users_protected_hierarchy
        CHECK (NOT (system_admin_protected = true AND admin_protected = false));
    SQL

    add_column :groups, :system_admin_protected, :boolean, default: false, null: false
    rename_column :groups, :protected, :admin_protected

    execute <<-SQL.strip_heredoc
      ALTER TABLE groups ADD CONSTRAINT groups_protected_hierarchy
        CHECK (NOT (system_admin_protected = true AND admin_protected = false));
    SQL

    execute <<-SQL.strip_heredoc
      ALTER TABLE users ADD CONSTRAINT users_admin_hierarchy
        CHECK (NOT (is_system_admin = true AND is_admin = false));
    SQL


    ### login #################################################################

    execute <<-SQL.strip_heredoc
      ALTER TABLE users DROP CONSTRAINT login_may_not_contain_at_sign;

      UPDATE users SET login = NULL WHERE login !~ '^[a-z0-9]+$';

      ALTER TABLE users ADD CONSTRAINT login_is_simple CHECK ( login ~ '^[a-z0-9]+$'::text);
    SQL


    ### organization ##########################################################

    add_column :users, :organization, :text,
      default: 'local', limit: 63, index: true, null: false
    add_column :groups, :organization, :text,
      default: 'local', limit: 63, index: true, null: false

    execute <<-SQL.strip_heredoc

      ALTER TABLE users ADD CONSTRAINT check_org_domain_like
        CHECK ( organization ~ '^[A-Za-z0-9]+[A-Za-z0-9.\-]+[A-Za-z0-9]+$'::text);

      ALTER TABLE groups ADD CONSTRAINT check_org_domain_like
        CHECK ( organization ~ '^[A-Za-z0-9]+[A-Za-z0-9.\-]+[A-Za-z0-9]+$'::text);

      ALTER TABLE users ADD CONSTRAINT users_org_id_may_not_contain_at_sign
        CHECK (((org_id)::text !~~* '%@%'::text));

      ALTER TABLE groups ADD CONSTRAINT groups_org_id_may_not_contain_at_sign
        CHECK (((org_id)::text !~~* '%@%'::text));

      UPDATE users SET organization = 'zhdk.ch', admin_protected = true
        WHERE org_id IS NOT NULL
        AND EXISTS (SELECT true FROM system_and_security_settings
                    WHERE external_base_url IN ('https://leihs.zhdk.ch', 'http://localhost:3000'));

      UPDATE groups SET organization = 'zhdk.ch', admin_protected = true
        WHERE org_id IS NOT NULL
        AND EXISTS (SELECT true FROM system_and_security_settings
                    WHERE external_base_url IN ('https://leihs.zhdk.ch', 'http://localhost:3000'));

      UPDATE groups SET organization = 'leihs-core',
        org_id = 'all-users', admin_protected = true, system_admin_protected = true
        WHERE id = '#{::Leihs::Constants::ALL_USERS_GROUP_UUID}';

    SQL

    remove_index :users, :org_id
    remove_index :groups, :org_id

    execute <<-SQL.strip_heredoc
      CREATE UNIQUE INDEX idx_users_organization_org_id
        ON users USING btree ((organization || '_' || org_id));

      CREATE UNIQUE INDEX idx_groups_organization_org_id
        ON groups USING btree ((organization|| '_' || org_id));
    SQL

    execute <<-SQL.strip_heredoc
      ALTER TABLE audited_requests DROP CONSTRAINT IF EXISTS fk_rails_83fd1038f8;
    SQL

    # execute <<-SQL.strip_heredoc
    #   UPDATE system_and_security_settings SET sessions_force_uniqueness = false;
    # SQL

  end

end
