class ProcurementExiftoolJsonMetadata < ActiveRecord::Migration[5.0]
  TABLES = [:procurement_images,
            :procurement_attachments,
            :procurement_uploads]
  EXIFTOOL_VERSION = `exiftool -ver`.chomp
  EXIFTOOL_OPTIONS = '-j -s -a -u -G1'

  class MigrationProcurementImages < ActiveRecord::Base
    self.table_name = 'procurement_images'
  end

  class MigrationProcurementAttachments < ActiveRecord::Base
    self.table_name = 'procurement_attachments'
  end

  class MigrationProcurementUploads < ActiveRecord::Base
    self.table_name = 'procurement_uploads'
  end

  def up
    TABLES.each do |table|
      add_column table, :exiftool_version, :string
      add_column table, :exiftool_options, :string
    end

    tmp_dir = `mktemp -d`.chomp

    puts <<-HEREDOC.strip_heredoc
      ###################################
      TABLE: procurement_images
      ###################################
    HEREDOC
    MigrationProcurementImages.all.each do |entity|
      read_and_store_metadata(entity, tmp_dir)
    end

    puts <<-HEREDOC.strip_heredoc
      ###################################
      TABLE: procurement_attachments
      ###################################
    HEREDOC
    MigrationProcurementAttachments.all.each do |entity|
      read_and_store_metadata(entity, tmp_dir)
    end

    puts <<-HEREDOC.strip_heredoc
      ###################################
      TABLE: procurement_uploads
      ###################################
    HEREDOC
    MigrationProcurementUploads.all.each do |entity|
      read_and_store_metadata(entity, tmp_dir)
    end
  end

  def down
    TABLES.each do |table|
      remove_column table, :exiftool_version
      remove_column table, :exiftool_options
    end
  end

  def read_and_store_metadata(entity, tmp_dir)
    puts "#{entity.class.table_name}: #{entity.id} - #{entity.filename}"
    if entity.content.presence
      path = "#{tmp_dir}/#{entity.filename}"
      f = File.new(path, 'w')
      f.write(Base64.decode64(entity.content).force_encoding('UTF-8'))
      f.close
      h = \
        JSON
        .parse(`exiftool #{EXIFTOOL_OPTIONS} #{Shellwords.escape f.path}`)
        .first
      entity.update!(metadata: h,
                                exiftool_version: EXIFTOOL_VERSION,
                                exiftool_options: EXIFTOOL_OPTIONS)
      File.delete(path)
    else
      puts "No content!"
    end
  end
end
