class TrashMetadataColumns < ActiveRecord::Migration[7.2]
  TABLES = [:attachments,
    :images,
    :procurement_attachments,
    :procurement_images,
    :procurement_uploads]

  def up
    TABLES.each do |table|
      remove_column table, :metadata
    end
  end
end
