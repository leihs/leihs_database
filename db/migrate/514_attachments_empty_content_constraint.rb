class AttachmentsEmptyContentConstraint < ActiveRecord::Migration[5.0]
  class MigrationAttachment < ActiveRecord::Base
    self.table_name = 'attachments'
  end

  def up
    empty_as =
      MigrationAttachment
      .where(content: nil)
      .or(MigrationAttachment.where(content: ''))
      .or(MigrationAttachment.where(content_type: nil))
      .or(MigrationAttachment.where(content_type: ''))
      .or(MigrationAttachment.where(size: 0))
      .or(MigrationAttachment.where(size: nil))
      .or(MigrationAttachment.where(filename: nil))
      .or(MigrationAttachment.where(filename: ''))

    unless empty_as.empty?
      as_info = empty_as.map { |a| "Model ID: #{a.model_id} - Filename: #{a.filename}" } 
      puts 'Cannot introduce constraint due to existing broken files. Please first delete and re-upload following attachments:'
      puts as_info
      raise
    end

    execute <<-SQL.strip_heredoc
      ALTER TABLE attachments
      ALTER COLUMN content SET NOT NULL,
      ALTER COLUMN content_type SET NOT NULL,
      ALTER COLUMN size SET NOT NULL,
      ALTER COLUMN filename SET NOT NULL,
      ADD CONSTRAINT check_size_greater_than_zero CHECK (size > 0),
      ADD CONSTRAINT check_model_id_or_item_id_not_null CHECK (model_id IS NOT NULL OR item_id IS NOT NULL),
      ADD CONSTRAINT check_non_empty_content CHECK (content !~ '^\\s*$'),
      ADD CONSTRAINT check_non_empty_content_type CHECK (content_type !~ '^\\s*$'),
      ADD CONSTRAINT check_non_empty_filename CHECK (filename !~ '^\\s*$')
    SQL
  end

  def down
  end
end
