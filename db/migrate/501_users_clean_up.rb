class UsersCleanUp < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def change


    remove_column :users, :authentication_system_id

    # clean up users table
    #

    ActiveRecord::Base.connection.execute(
      'SELECT lower(email) AS email, array_agg(id) AS ids FROM users GROUP BY lower(email) HAVING count(lower(email)) >= 2'
    ).to_a.each do |duplicate_email_user|
      email = duplicate_email_user['email']
      duplicate_ids = ActiveRecord::Base.connection.execute(
        " SELECT id FROM users
           WHERE lower(email) = '#{email}'; ").to_a.map{|u| u['id']}

      user_id = duplicate_ids.shift
      duplicate_ids.each do |duplicate_id|
        ['access_rights', 'reservations', 'orders', 'contracts', 'entitlement_groups_users'].each do |table|
          execute <<-SQL.strip_heredoc
          UPDATE #{table}
            SET user_id = '#{user_id}'
            WHERE user_id = '#{duplicate_id}';
          SQL
        end
        execute <<-SQL.strip_heredoc
          DELETE FROM users WHERE id = '#{duplicate_id}';
        SQL
      end
    end

    ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
      UPDATE users SET login = NULL where login ilike '%@%';

      UPDATE users SET login = NULL 
        WHERE EXISTS 
          (SELECT TRUE FROM users as duplicates
            WHERE users.login = duplicates.login AND users.id <> duplicates.id);

    SQL

  end

end


