class RefactoringAuditedRequests < ActiveRecord::Migration[5.0]
  def up

    remove_column :audited_requests, :data
    remove_column :audited_responses, :data

    add_index :audited_changes, :created_at
    add_index :audited_requests, :created_at
    add_index :audited_responses, :created_at
    add_index :audited_responses, :status

    rename_column :audited_requests, :url, :path

    execute <<-SQL.strip_heredoc
      ALTER TABLE audited_requests
        ADD CONSTRAINT check_absolute_path CHECK (path ~ '^\/.*$')
    SQL

    add_column :audited_requests, :http_uid, :text, index: true

    # migrate datea set user_id for sign-in
    execute <<-SQL.strip_heredoc
      UPDATE audited_requests
      SET user_id = ((audited_changes.changed -> 'user_id') ->> 1)::UUID
      FROM audited_changes
      WHERE audited_changes.txid = audited_requests.txid
      AND audited_changes.table_name = 'user_sessions'
      AND audited_changes.tg_op = 'INSERT'
      AND EXISTS (SELECT true FROM users WHERE users.id = ((audited_changes.changed -> 'user_id') ->> 1)::UUID );
    SQL

    ["audited_requests", "audited_responses"].each do |table|
      execute <<-SQL.strip_heredoc
        ALTER TABLE #{table} DROP CONSTRAINT #{table}_pkey;
        ALTER TABLE #{table} DROP COLUMN id;
        ALTER TABLE #{table} ADD PRIMARY KEY (txid);
      SQL
    end

  end
end
