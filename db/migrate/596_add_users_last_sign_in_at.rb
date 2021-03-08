class AddUsersLastSignInAt < ActiveRecord::Migration[5.0]
  def change

    add_column :users, :last_sign_in_at, 'timestamp with time zone'

    reversible do |dir|

      dir.up do

        execute <<-SQL.strip_heredoc

          UPDATE users SET last_sign_in_at = session.max_created_at
            FROM (SELECT MAX(created_at) AS max_created_at, user_id
                    FROM user_sessions
                    GROUP BY user_id) AS session
             WHERE users.id = session.user_id;


          CREATE OR REPLACE FUNCTION users_set_last_sign_in_at()
          RETURNS TRIGGER AS $$
          BEGIN
            UPDATE users SET last_sign_in_at = now() WHERE id = NEW.user_id;
            RETURN NULL;
          END;
          $$ language 'plpgsql';

          CREATE TRIGGER users_set_last_sign_in_at
          AFTER INSERT ON user_sessions FOR EACH ROW
          EXECUTE PROCEDURE users_set_last_sign_in_at();

        SQL

      end

      dir.down do

        execute <<-SQL.strip_heredoc

          DROP TRIGGER IF EXISTS users_set_last_sign_in_at ON user_sessions;
          DROP FUNCTION IF EXISTS users_set_last_sign_in_at();

        SQL

      end

    end
  end
end
