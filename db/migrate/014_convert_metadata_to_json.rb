class ConvertMetadataToJson < ActiveRecord::Migration[6.1]
  BACKUP_DIR_PATH = ENV['BACKUP_DIR_PATH'] ? Pathname.new(ENV['BACKUP_DIR_PATH']) : Rails.root.join('db', 'migrate')
  BACKUP_FILE = BACKUP_DIR_PATH.join("procurement_attachments_backup.json")

  class ProcurementAttachment < ActiveRecord::Base
    self.table_name = 'procurement_attachments'
  end

  class SchemaMigraion < ActiveRecord::Base
    self.table_name = 'procurement_attachments'
  end

  def up
    ActiveRecord::Base.transaction do
      backup_relevant_data

      ProcurementAttachment.all.find_each do |attachment|
        metadata = attachment.metadata

        if metadata.blank? || (metadata.is_a?(String) && metadata.try(:strip).blank?)
          puts "WARNING: 'procurement_attachments.metadata'-field contains invalid format/value, process reset to " +
                 "default=[]; id=#{attachment.id}  metadata: >#{metadata}<"

          attachment.update!(metadata: [])
          next
        end

        if metadata.is_a?(String)
          begin
            attachment.update!(metadata: JSON.parse(metadata))
          rescue JSON::ParserError => e
            Rails.logger.error "Invalid JSON content in metadata for ProcurementAttachment id: #{attachment.id}: #{e.message}"
            raise ActiveRecord::Rollback
          end
        end
      end
    end
  end

  def down
    restore_metadata_data
  end

  def backup_relevant_data
    data = ProcurementAttachment.select(:id, :filename, :metadata).as_json

    File.open(BACKUP_FILE, 'w') do |file|
      file.write(JSON.pretty_generate(data))
    end
  rescue => e
    puts "Backup failed: #{e.message}"
    raise ActiveRecord::Rollback
  end

  def restore_metadata_data
    data = JSON.parse(File.read(BACKUP_FILE))
    ActiveRecord::Base.transaction do
      data.each do |item|
        record = ProcurementAttachment.find_by(id: item['id'])
        record.update(metadata: item['metadata']) if record
      end
    end
  rescue => e
    puts "Restore failed: #{e.message}"
  end
end

