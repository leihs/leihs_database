class AddSettingIncludeCustomerEmailInContracts < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL.strip_heredoc

      ALTER TABLE "settings"
        ADD COLUMN "include_customer_email_in_contracts" boolean NOT NULL DEFAULT false;

    SQL
  end
end
