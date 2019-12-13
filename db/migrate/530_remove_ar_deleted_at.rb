class RemoveArDeletedAt < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  class AccessRight < ActiveRecord::Base
  end

  def change

    reversible do |dir|
      dir.up do
        AccessRight.where.not(deleted_at: nil).delete_all()
      end
    end

    remove_column :access_rights, :deleted_at, :date

  end
end
