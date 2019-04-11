class CreateTableEmails < ActiveRecord::Migration[5.0]
  def change
    create_table :emails, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.text :subject, null: false
      t.text :body, null: false
      t.text :from_address, null: false
      t.integer :trials, null: false, default: 0
      t.integer :code
      t.text :error
      t.text :message
      t.timestamps null: false, default: -> { 'NOW()' }
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE emails
          ADD CONSTRAINT check_code
            CHECK ((trials = 0 AND code IS NULL) OR (trials != 0 AND CODE IS NOT NULL)),
          ADD CONSTRAINT check_error
            CHECK ((trials = 0 AND error IS NULL) OR (trials != 0 AND CODE IS NOT NULL)),
          ADD CONSTRAINT check_message
            CHECK ((trials = 0 AND message IS NULL) OR (trials != 0 AND CODE IS NOT NULL))
        SQL
      end
    end
  end
end
