class CreatePasswordAuthSys < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc
      INSERT INTO authentication_systems(id, name, type, enabled)
        VALUES ('password', 'leihs password', 'password', true)
        ON CONFLICT (id)
        DO UPDATE SET type = 'password', enabled = true;
    SQL
  end
end
