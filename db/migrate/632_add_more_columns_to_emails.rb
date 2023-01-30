class AddMoreColumnsToEmails < ActiveRecord::Migration[6.1]

  def up
    add_column :emails, :to_address, :text
    add_column :emails, :inventory_pool_id, :uuid
    add_foreign_key :emails, :inventory_pools, name: :emails_inventory_pool_id_fk, on_delete: :cascade
    change_column :emails, :user_id, :uuid, null: true
    add_foreign_key :emails, :users, name: :emails_user_id_fk, on_delete: :cascade

    execute <<~SQL
      ALTER TABLE emails
      ADD CONSTRAINT check_user_id_or_inventory_pool_id_not_null
      CHECK ( user_id IS NOT NULL OR inventory_pool_id IS NOT NULL );
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION check_emails_to_address_not_null_f()
      RETURNS TRIGGER AS $$
      BEGIN
        IF ( NEW.to_address IS NULL ) THEN
          RAISE EXCEPTION 'to_address cannot be null';
        END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    SQL

    execute <<-SQL
      CREATE CONSTRAINT TRIGGER check_emails_to_address_not_null_t
      AFTER INSERT OR UPDATE
      ON emails
      FOR EACH ROW
      EXECUTE PROCEDURE check_emails_to_address_not_null_f()
    SQL
  end

  def down
    remove_column :emails, :to_address
    remove_column :emails, :inventory_pool_id
    change_column :emails, :user_id, :uuid, null: false
    remove_foreign_key :emails, :users
    execute 'ALTER TABLE emails DROP CONSTRAINT IF EXISTS check_user_id_or_inventory_pool_id_not_null'
    execute 'DROP TRIGGER check_emails_to_address_not_null_t ON emails'
    execute 'DROP FUNCTION IF EXISTS check_emails_to_address_not_null_f()'
  end

end

