class TrashMetadataColumns < ActiveRecord::Migration[7.2]
  TABLES = [:attachments,
    :images,
    :procurement_attachments,
    :procurement_images,
    :procurement_uploads]

  def up
    TABLES.each do |table|
      remove_column table, :metadata

      [:exiftool_version, :exiftool_options].each do |column|
        if column_exists?(table, column)
          remove_column table, column
        end
      end
    end
  end
end
