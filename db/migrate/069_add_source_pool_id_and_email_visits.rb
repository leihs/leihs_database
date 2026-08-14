class AddSourcePoolIdAndEmailVisits < ActiveRecord::Migration[6.1]
  def up
    add_column :emails, :source_pool_id, :uuid

    create_table :emails_visits, id: false do |t|
      t.uuid :email_id, null: false
      t.uuid :visit_id, null: false
    end

    execute <<~SQL
      ALTER TABLE emails_visits ADD PRIMARY KEY (email_id, visit_id)
    SQL

    add_foreign_key :emails_visits, :emails, column: :email_id, on_delete: :cascade
    add_index :emails_visits, :visit_id
  end

  def down
    drop_table :emails_visits
    remove_column :emails, :source_pool_id
  end
end
