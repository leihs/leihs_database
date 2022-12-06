class RemoveUnusedSettings < ActiveRecord::Migration[5.0]
  class MigrationSettings < ActiveRecord::Base
    self.table_name = 'settings'
  end

  class MigrationSmtpSettings < ActiveRecord::Base
    self.table_name = 'smtp_settings'
  end

  def up
    remove_column(:settings, :contract_terms)
    MigrationSettings.reset_column_information

    misc = MigrationSettings.first
    smtp = MigrationSmtpSettings.first

    if email = misc.try(:default_email).presence
      smtp.update!(default_from_address: email)
    end

    remove_column(:settings, :default_email)
  end
end
