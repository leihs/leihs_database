class MigrateMailTemplates < ActiveRecord::Migration[5.0]

  class MigrationInventoryPool < ActiveRecord::Base
    self.table_name = 'inventory_pools'
    has_many :mail_templates
  end

  class MigrationMailTemplate < ActiveRecord::Base
    self.inheritance_column = nil
    self.table_name = 'mail_templates'
    belongs_to :inventory_pool
  end

  class MigrationLanguage < ActiveRecord::Base
    self.table_name = 'languages'
  end

  TEMPLATE_TYPES = {
    reminder: :user,
    deadline_soon_reminder: :user,
    received: :order,
    submitted: :order,
    approved: :order,
    rejected: :order
  }

  def up
    add_timestamps :mail_templates, null: true
    t = Time.now
    MigrationMailTemplate.update_all(created_at: t, updated_at: t)

    ############################## is_template_template ###########################################
    add_column :mail_templates, :is_template_template, :boolean, null: true

    MigrationMailTemplate.where(inventory_pool_id: nil).update_all(is_template_template: true)
    MigrationMailTemplate.where.not(inventory_pool_id: nil).update_all(is_template_template: false)

    execute <<-SQL
      ALTER TABLE mail_templates
      ADD CHECK (
        (inventory_pool_id IS NULL AND is_template_template IS TRUE) OR
        (inventory_pool_id IS NOT NULL AND is_template_template IS FALSE)
      )
    SQL

    MigrationMailTemplate.reset_column_information
    ###############################################################################################

    add_column :mail_templates, :type, :text
    MigrationMailTemplate.all.each do |template|
      template.update_attributes!(type: TEMPLATE_TYPES[template.name.to_sym])
    end

    Dir["../legacy/app/views/mailer/**/*.liquid"].each do |file_path|
      name, format, _ = File.basename(file_path).split('.')
      dirname = File.dirname(file_path)
      file_contents = File.read(File.join(file_path))

      base_attrs = {
        name: name,
        format: format
      }
      
      MigrationLanguage.all.each do |language|
        attrs = base_attrs.merge(language_id: language.id)

        # create missing admin mail template for a particular language
        unless MigrationMailTemplate.find_by(attrs.merge(is_template_template: true))
          MigrationMailTemplate.create!(attrs.merge(is_template_template: true,
                                                    type: TEMPLATE_TYPES[base_attrs[:name].to_sym],
                                                    body: file_contents))
        end

        MigrationInventoryPool.all.each do |inventory_pool|
          # skip if there is a already a mail template for an inventory pool
          unless MigrationMailTemplate.find_by(attrs.merge(inventory_pool_id: inventory_pool.id))
            # use admin mail template for the new inventory pool template
            tt = MigrationMailTemplate.find_by(attrs.merge(is_template_template: true))
            MigrationMailTemplate.create!(
              attrs.merge(inventory_pool_id: inventory_pool.id,
                          body: tt.body,
                          type: TEMPLATE_TYPES[base_attrs[:name].to_sym],
                          is_template_template: false)
            )
          end
        end
      end
    end

    MigrationMailTemplate.column_names.reject { |cn| %w(id inventory_pool_id).include?(cn) }.each do |cn|
      change_column_null :mail_templates, cn.to_sym, false
    end
  end
end
