class AdminConstraints < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change

    change_column :delegations_users, :delegation_id, :uuid, null: false
    change_column :delegations_users, :user_id, :uuid, null: false

    add_index :users, :org_id,
      name: :users_org_id_idx,
      unique: true

    add_index :users, 'lower(email)',
      name: :users_email_idx,
      unique: true

    execute <<-SQL
      ALTER TABLE delegations_users DROP CONSTRAINT fk_rails_b5f7f9c898;

      ALTER TABLE delegations_users 
        ADD CONSTRAINT fkey_delegations_users_delegation_id
        FOREIGN KEY (delegation_id) REFERENCES public.users(id) ON
        DELETE CASCADE;


      ALTER TABLE delegations_users DROP CONSTRAINT fk_rails_df1fb72b34;
 
      ALTER TABLE delegations_users  
        ADD CONSTRAINT fkey_delegations_users_user_id
        FOREIGN KEY (user_id) REFERENCES public.users(id) ON
        DELETE CASCADE;

      ALTER TABLE access_rights DROP CONSTRAINT fk_rails_c10a7fd1fd;

      ALTER TABLE access_rights 
        ADD CONSTRAINT fkey_access_rights_user_id
        FOREIGN KEY (user_id) REFERENCES public.users(id) ON
        DELETE CASCADE;

    SQL

    execute <<-SQL.strip_heredoc
      
      ALTER TABLE users ADD CONSTRAINT login_may_not_contain_at_sig
        CHECK (login NOT ILIKE '%@%');
      
    SQL

    add_index :users, 'lower(login)',
      name: :users_login_idx,
      unique: true

  end

end


