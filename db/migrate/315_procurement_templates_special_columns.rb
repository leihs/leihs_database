class ProcurementTemplatesSpecialColumns < ActiveRecord::Migration[5.0]
  class MigrationProcurementTemplate < ActiveRecord::Base
    self.table_name = :procurement_templates
  end

  class MigrationSupplier < ActiveRecord::Base
    self.inheritance_column = nil
    self.table_name = :suppliers
  end

  class MigrationModel < ActiveRecord::Base
    self.inheritance_column = nil
    self.table_name = :models

    def name
      [product, version].compact.join(' ')
    end
  end

  def change
    change_column :procurement_templates, :article_name, :text, null: true

    MigrationProcurementTemplate.all.each do |tmpl|
      ################# SUPPLIER ################
      if tmpl.supplier_name
        if supplier = MigrationSupplier.find_by_name(tmpl.supplier_name) 
          tmpl.update_attributes!(supplier_id: supplier.id)
        else
          new_supplier = MigrationSupplier.create(name: tmpl.supplier_name)
          tmpl.update_attributes!(supplier_id: new_supplier.id)
        end
      end

      ################# MODEL ###################
      if tmpl.model_id and tmpl.article_name
        model = MigrationModel.find(tmpl.model_id) 
        if model.name == tmpl.article_name
          tmpl.update_attributes!(article_name: nil)
        else
          tmpl.update_attributes!(model_id: nil)
        end
      end

      if tmpl.article_name
        tmpl.update_attributes!(article_name: tmpl.article_name.strip)
      end
    end

    remove_column :procurement_templates, :supplier_name

    [:article_name].each do |col|
      execute <<-SQL
        ALTER TABLE procurement_templates
        ADD CONSTRAINT #{col}_is_not_blank
        CHECK (#{col} !~ '^\\s*$');
      SQL
    end

    execute <<-SQL.strip_heredoc
      ALTER TABLE procurement_templates
        ADD CONSTRAINT check_either_model_id_or_article_name
        CHECK (
          (model_id IS NOT NULL AND article_name IS NULL) OR
          (model_id IS NULL AND article_name IS NOT NULL)
        );
    SQL
  end
end
