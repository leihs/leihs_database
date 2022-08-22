class ExtendAuditsWithTx2 < ActiveRecord::Migration[5.0]

  def up
    execute <<-SQL.strip_heredoc
      ALTER TABLE audited_requests DROP CONSTRAINT audited_requests_pkey;
      ALTER TABLE audited_requests ADD COLUMN id UUID DEFAULT uuid_generate_v4();
      ALTER TABLE audited_requests ADD PRIMARY KEY (id);
      ALTER TABLE audited_requests ADD COLUMN tx2id UUID;
      CREATE INDEX audited_requests_tx2id ON audited_requests (tx2id);


      ALTER TABLE audited_responses DROP CONSTRAINT audited_responses_pkey;
      ALTER TABLE audited_responses ADD COLUMN id UUID DEFAULT uuid_generate_v4();
      ALTER TABLE audited_responses ADD PRIMARY KEY (id);
      ALTER TABLE audited_responses ADD COLUMN tx2id UUID;
      CREATE INDEX audited_responses_tx2id ON audited_responses (tx2id);
    SQL
  end

  def down
    raise 'not reversible'
  end

end
