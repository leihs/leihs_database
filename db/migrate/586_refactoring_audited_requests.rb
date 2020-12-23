class RefactoringAuditedRequests < ActiveRecord::Migration[5.0]
  def up

    remove_column :audited_requests, :data
    remove_column :audited_responses, :data

    add_index :audited_changes, :created_at
    add_index :audited_requests, :created_at
    add_index :audited_responses, :created_at

    add_column :audited_requests, :http_uid, :text, index: true

  end
end
