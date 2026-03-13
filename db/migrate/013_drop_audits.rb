class DropAudits < ActiveRecord::Migration[6.1]
  def change
    drop_table :audits do |t|
      t.uuid :auditable_id
      t.string :auditable_type
      t.uuid :associated_id
      t.string :associated_type
      t.uuid :user_id
      t.string :user_type
      t.string :username
      t.string :action
      t.text :audited_changes
      t.integer :version, default: 0
      t.string :comment
      t.string :remote_address
      t.string :request_uuid
      t.timestamp :created_at
    end
  end
end
