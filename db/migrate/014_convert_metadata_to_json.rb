class ConvertMetadataToJson < ActiveRecord::Migration[6.1]
  BACKUP_DIR_PATH = ENV['BACKUP_DIR_PATH'] ? Pathname.new(ENV['BACKUP_DIR_PATH']) : Rails.root.join('db', 'migrate', 'tmp-backup')
  BACKUP_FILE = BACKUP_DIR_PATH.join("procurement_attachments_backup.json")

  class ProcurementAttachment < ActiveRecord::Base
    self.table_name = 'procurement_attachments'
  end

  class SchemaMigraion < ActiveRecord::Base
    self.table_name = 'procurement_attachments'
  end

  def up
    ActiveRecord::Base.transaction do
      backup_data

      ProcurementAttachment.all.find_each do |attachment|
        metadata = attachment.metadata
        if metadata.blank? || (metadata.is_a?(String) && metadata.try(:strip).blank?)
          puts "WARNING: 'procurement_attachments.metadata'-field contains invalid format/value, process reset to default={}; id=#{attachment.id}  metadata: >#{metadata}<"

          attachment.update!(metadata: {})
          next
        end

        if metadata.is_a?(String)
          begin
            parsed_metadata = JSON.parse(metadata)

            if parsed_metadata.is_a?(Array)
              if parsed_metadata.length == 1
                attachment.update!(metadata: parsed_metadata.first)
              else
                raise ActiveRecord::Rollback, "Metadata contains more than one element in array for ProcurementAttachment id: #{attachment.id}"
              end
            else
              attachment.update!(metadata: parsed_metadata)
            end
          rescue JSON::ParserError => e
            Rails.logger.error "Invalid JSON content in metadata for ProcurementAttachment id: #{attachment.id}: #{e.message}"
            raise ActiveRecord::Rollback
          end
        end
      end
    end
  end

  def down
    execute <<~SQL
      DELETE FROM schema_migrations where version='14'
    SQL

    execute <<~SQL
      DELETE FROM procurement_attachments
    SQL

    restore_data
  end

  def backup_data
    data = ProcurementAttachment.all.as_json
    File.open(BACKUP_FILE, 'w') do |file|
      file.write(JSON.pretty_generate(data))
    end
  rescue => e
    puts "Backup failed: #{e.message}"
    raise ActiveRecord::Rollback
  end

  def restore_data
    data = JSON.parse(File.read(BACKUP_FILE))
    ActiveRecord::Base.transaction do
      ProcurementAttachment.delete_all
      ProcurementAttachment.create!(data)
    end
  rescue => e
    puts "Restore failed: #{e.message}"
  end
end

