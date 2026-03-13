class NotNullableColumnsForProcurementFiles < ActiveRecord::Migration[6.1]
  TABLES = [:procurement_uploads,
    :procurement_attachments,
    :procurement_images]

  COMMON_COLUMNS = [:filename,
    :content_type,
    :size,
    :content,
    :metadata,
    :exiftool_version,
    :exiftool_options]

  def up
    TABLES.each do |table|
      if column_exists?(table, :content)
        execute <<~SQL
          DELETE FROM #{table} WHERE content IS NULL
        SQL
      end

      cols = case table
      when :procurement_attachments
        COMMON_COLUMNS + [:request_id]
      when :procurement_images
        COMMON_COLUMNS + [:main_category_id]
      else
        COMMON_COLUMNS
      end

      cols.each do |col|
        change_column_null table, col, false if column_exists?(table, col)
      end
    end
  end

  def down
  end
end
