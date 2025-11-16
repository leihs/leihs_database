class CreateMs365Mailboxes < ActiveRecord::Migration[7.2]
  include Leihs::MigrationHelper

  EMAIL_REGEX = '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

  def up
    create_table :ms365_mailboxes, id: false do |t|
      t.text :id, null: false, primary_key: true
      t.text :access_token
      t.text :refresh_token
      t.timestamp :token_expires_at
    end

    add_auto_timestamps(:ms365_mailboxes, null: false)
    audit_table(:ms365_mailboxes)

    add_check_constraint :ms365_mailboxes,
      "id ~* '#{EMAIL_REGEX}'",
      name: 'ms365_mailboxes_id_is_email'

    create_table :ms365_mailboxes_aliases, id: :uuid do |t|
      t.text :ms365_mailbox_id, null: false
      t.text :email, null: false
    end

    add_auto_timestamps(:ms365_mailboxes_aliases, null: false)
    audit_table(:ms365_mailboxes_aliases)

    add_foreign_key :ms365_mailboxes_aliases, :ms365_mailboxes,
      column: :ms365_mailbox_id,
      primary_key: :id,
      on_delete: :cascade

    add_check_constraint :ms365_mailboxes_aliases,
      "email ~* '#{EMAIL_REGEX}'",
      name: 'ms365_mailboxes_aliases_email_is_valid'

    add_index :ms365_mailboxes_aliases, :email, unique: true
    add_index :ms365_mailboxes_aliases, :ms365_mailbox_id
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS audited_change_on_ms365_mailboxes_aliases ON ms365_mailboxes_aliases;
      DROP TRIGGER IF EXISTS update_updated_at_column_of_ms365_mailboxes_aliases ON ms365_mailboxes_aliases;
      DROP TRIGGER IF EXISTS audited_change_on_ms365_mailboxes ON ms365_mailboxes;
      DROP TRIGGER IF EXISTS update_updated_at_column_of_ms365_mailboxes ON ms365_mailboxes;
    SQL

    drop_table :ms365_mailboxes_aliases
    drop_table :ms365_mailboxes
  end
end
