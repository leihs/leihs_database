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
        ['access_rights', 'reservations', 'orders', 'contracts'].each do |table|
          execute <<-SQL.strip_heredoc
            UPDATE #{table}
              SET user_id = '#{user_id}'
              WHERE user_id = '#{duplicate_id}';
          SQL
          
          if table == 'reservations'
            ['handed_over_by_user_id', 'returned_to_user_id', 'delegated_user_id'].each do |col|
              execute <<-SQL.strip_heredoc
                UPDATE #{table}
                SET #{col} = '#{user_id}'
                WHERE #{col} = '#{duplicate_id}';
              SQL
            end
          end
        end

        execute <<-SQL.strip_heredoc
          INSERT INTO entitlement_groups_users
          SELECT '#{user_id}', entitlement_group_id
          FROM entitlement_groups_users
          WHERE user_id = '#{duplicate_id}'
          ON CONFLICT DO NOTHING
        SQL

        execute <<-SQL.strip_heredoc
          DELETE FROM entitlement_groups_users
          WHERE user_id = '#{duplicate_id}'
        SQL

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


