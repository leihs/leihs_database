class ProcurementCascadeDeleteAttachments < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key(:procurement_attachments,
                       column: :request_id)
    add_foreign_key(:procurement_attachments,
                    :procurement_requests,
                    column: :request_id,
                    on_delete: :cascade)
  end
end
