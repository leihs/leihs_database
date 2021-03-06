class AddContentToImagesAndAttachments < ActiveRecord::Migration[4.2]

TABLES = [:images, :attachments, :procurement_attachments]

  def up
    TABLES.each do |table_name|
      if ActiveRecord::Base.connection.table_exists? table_name
        add_column table_name, :content, :text
      end
    end
  end

  def down
    TABLES.each do |table_name|
      if ActiveRecord::Base.connection.table_exists? table_name
        remove_column table_name, :content
      end
    end
  end
end
