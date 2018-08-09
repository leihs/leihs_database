class ProcurementRequestsSpecialColumns < ActiveRecord::Migration[5.0]
  class MigrationProcurementRequest < ActiveRecord::Base
    self.table_name = :procurement_requests
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
    remove_column :procurement_requests, :location_name, :text
    change_column :procurement_requests, :article_name, :text, null: true

    MigrationProcurementRequest.all.each do |req|
      ################# SUPPLIER ################
      if req.supplier_id and req.supplier_name
        supplier = MigrationSupplier.find(req.supplier_id) 
        if supplier.name == req.supplier_name
          req.update_attributes!(supplier_name: nil)
        else
          req.update_attributes!(supplier_id: nil)
        end
      end

      if req.supplier_name
        req.update_attributes!(supplier_name: req.supplier_name.strip)
      end

      ################# MODEL ###################
      if req.model_id and req.article_name
        model = MigrationModel.find(req.model_id) 
        if model.name == req.article_name
          req.update_attributes!(article_name: nil)
        else
          req.update_attributes!(model_id: nil)
        end
      end

      if req.article_name
        req.update_attributes!(article_name: req.article_name.strip)
      end
    end

    [:supplier_name, :article_name].each do |col|
      execute <<-SQL
        ALTER TABLE procurement_requests
        ADD CONSTRAINT #{col}_is_not_blank
        CHECK (#{col} !~ '^\\s*$');
      SQL
    end

    execute <<-SQL.strip_heredoc
      ALTER TABLE procurement_requests
        ADD CONSTRAINT check_either_model_id_or_article_name
        CHECK (
          (model_id IS NOT NULL AND article_name IS NULL) OR
          (model_id IS NULL AND article_name IS NOT NULL)
        );
    SQL

    execute <<-SQL.strip_heredoc
      ALTER TABLE procurement_requests
        ADD CONSTRAINT check_either_supplier_id_or_supplier_name
        CHECK (
          (supplier_id IS NOT NULL AND supplier_name IS NULL) OR
          (supplier_id IS NULL AND supplier_name IS NOT NULL) OR
          (supplier_id IS NULL AND supplier_name IS NULL)
        );
    SQL
  end
end
