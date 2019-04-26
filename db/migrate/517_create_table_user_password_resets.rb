class CreateTableUserPasswordResets < ActiveRecord::Migration[5.0]
  def change
    create_table :user_password_resets, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.text :used_user_param, null: false
      t.text :token, null: false
      t.datetime :valid_until, null: false
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end

    add_foreign_key :user_password_resets, :users, on_delete: :cascade
    add_index :user_password_resets, :user_id, unique: true

    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE OR REPLACE FUNCTION delete_obsolete_user_password_resets_1()
          RETURNS TRIGGER AS $$
          BEGIN
            DELETE FROM user_password_resets
            WHERE user_id = NEW.user_id;

            RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<~SQL
          CREATE TRIGGER trigger_delete_obsolete_user_password_resets
          BEFORE INSERT ON user_password_resets
          FOR EACH ROW
          EXECUTE PROCEDURE delete_obsolete_user_password_resets_1();
        SQL

        execute <<-SQL
          CREATE OR REPLACE FUNCTION delete_obsolete_user_password_resets_2()
          RETURNS TRIGGER AS $$
          BEGIN
            IF NEW.authentication_system_id = 'password' THEN
              DELETE FROM user_password_resets
              WHERE user_id = NEW.user_id;
            END IF;

            RETURN NEW;
          END;
          $$ language 'plpgsql';
        SQL

        execute <<~SQL
          CREATE TRIGGER trigger_delete_obsolete_user_password_resets
          AFTER INSERT OR UPDATE ON authentication_systems_users
          FOR EACH ROW
          EXECUTE PROCEDURE delete_obsolete_user_password_resets_2();
        SQL
      end

      dir.down do
        execute <<-SQL.strip_heredoc
          DROP TRIGGER IF EXISTS trigger_delete_obsolete_user_password_resets ON user_password_resets;
          DROP FUNCTION IF EXISTS delete_obsolete_user_password_resets_1();
          DROP TRIGGER IF EXISTS trigger_delete_obsolete_user_password_resets ON user_password_resets;
          DROP FUNCTION IF EXISTS delete_obsolete_user_password_resets_2();
        SQL
      end
    end
  end
end
