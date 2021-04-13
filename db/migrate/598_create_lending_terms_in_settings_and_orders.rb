class CreateLendingTermsInSettingsAndOrders < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc

      ALTER TABLE "settings"
        ADD COLUMN "lending_terms_acceptance_required_for_order" boolean NOT NULL DEFAULT false,
        ADD COLUMN "lending_terms_url" text,
        ADD CONSTRAINT lending_terms_consistency_check
          CHECK (lending_terms_url !~ '^\s*$'
                 AND ((lending_terms_acceptance_required_for_order AND lending_terms_url IS NOT NULL)
                      OR NOT lending_terms_acceptance_required_for_order));

      ALTER TABLE "customer_orders" 
        ADD COLUMN "lending_terms_accepted" bool;

      ALTER TABLE "orders" 
        ADD COLUMN "lending_terms_accepted" bool;

    SQL
  end
end
