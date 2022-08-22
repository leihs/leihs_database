class AddMissingLanguages < ActiveRecord::Migration[5.0]
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

  LANGUAGES = [['English (UK)', 'en-GB', true, true],
               ['English (US)', 'en-US', false, true],
               ['Deutsch', 'de-CH', false, true],
               ['Züritüütsch','gsw-CH', false, true],
               ['Castellano', 'es', false, false],
               ['Français (CH)', 'fr-CH', false, false]]

  def create_languages
    LANGUAGES.each do |lang|
      unless MigrationLanguage.find_by(locale: lang[1])
        MigrationLanguage.create!(name: lang[0],
                                  locale: lang[1],
                                  default: lang[2],
                                  active: lang[3])
      end
    end
  end

  def up
    MigrationLanguage.reset_column_information
    MigrationMailTemplate.reset_column_information

    create_languages

    TEMPLATE_TEMPLATES.each do |name, type:, body:|
      base_attrs = {
        name: name,
        type: type,
        format: :text
      }

      MigrationLanguage.all.each do |language|
        attrs = base_attrs.merge(language_locale: language.locale)

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
  end
end
