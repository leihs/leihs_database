class MigrateMailTemplates < ActiveRecord::Migration[5.0]

  class MigrationInventoryPool < ActiveRecord::Base
    self.table_name = 'inventory_pools'
    has_many :mail_templates
  end

  class MigrationMailTemplate < ActiveRecord::Base
    self.table_name = 'mail_templates'
    belongs_to :inventory_pool
  end

  class MigrationLanguage < ActiveRecord::Base
    self.table_name = 'languages'
  end

  def up
    add_timestamps :mail_templates, null: true
    t = Time.now
    MigrationMailTemplate.update_all(created_at: t, updated_at: t)

    Dir["../legacy/app/views/mailer/**/*.liquid"].each do |file_path|
      name, format, _ = File.basename(file_path).split('.')
      file_contents = File.read(File.join(file_path))

      MigrationInventoryPool.all.each do |inventory_pool|
        MigrationLanguage.all.each do |language|
          base_attrs = {
            language_id: language.id,
            name: name,
            format: format
          }
          # skip if there is a already a mail template for an inventory pool
          unless MigrationMailTemplate.find_by(base_attrs.merge(inventory_pool_id: inventory_pool.id))
            attrs = if mt = MigrationMailTemplate.find_by(base_attrs) # create an inventory pool template using the attributes of a system-wide one
                      mt.attributes.merge(inventory_pool_id: inventory_pool.id).reject { |k, _| k == 'id' }
                    else # create an inventory pool template using the template file
                      base_attrs.merge(inventory_pool_id: inventory_pool.id, body: file_contents)
                    end
            MigrationMailTemplate.create!(attrs)
          end
        end
      end
    end

    MigrationMailTemplate.where(inventory_pool_id: nil).destroy_all

    MigrationMailTemplate.column_names.reject { |cn| cn == 'id' }.each do |cn|
      change_column_null :mail_templates, cn.to_sym, false
    end
  end
end
