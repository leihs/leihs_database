class MigrateMailTemplates < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationMailTemplates

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

  LANGUAGES = [['English (UK)', 'en-GB', true],
               ['English (US)', 'en-US', false],
               ['Deutsch', 'de-CH', false],
               ['Züritüütsch','gsw-CH', false]]

  def create_languages!
    LANGUAGES.each do |lang|
      MigrationLanguage.create!(
        name: lang[0],
        locale_name: lang[1],
        default: lang[2],
        active: true
      )
    end
  end
    
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
      template.update_attributes!(type: TEMPLATE_TEMPLATES[template.name.to_sym][:type])
    end

    TEMPLATE_TEMPLATES.each do |name, type:, body:|
      base_attrs = {
        name: name,
        type: type,
        format: :text
      }
      
      create_languages! unless MigrationLanguage.exists?

      MigrationLanguage.all.each do |language|
        attrs = base_attrs.merge(language_id: language.id)

        # create missing admin mail template for a particular language
        unless MigrationMailTemplate.find_by(attrs.merge(is_template_template: true))
          MigrationMailTemplate.create!(attrs.merge(is_template_template: true, body: body))
        end

        MigrationInventoryPool.all.each do |inventory_pool|
          # skip if there is a already a mail template for an inventory pool
          unless MigrationMailTemplate.find_by(attrs.merge(inventory_pool_id: inventory_pool.id))
            # use admin mail template for the new inventory pool template
            tt = MigrationMailTemplate.find_by(attrs.merge(is_template_template: true))
            MigrationMailTemplate.create!(
              attrs.merge(inventory_pool_id: inventory_pool.id,
                          body: tt.body,
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
