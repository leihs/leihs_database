class SplitProcurementAccessesTable < ActiveRecord::Migration[5.0]
  class MigrationProcurementAccess < ActiveRecord::Base
    self.table_name = :procurement_accesses
  end

  class MigrationProcurementAdmin < ActiveRecord::Base
    self.table_name = :procurement_admins
  end

  def up
    create_table(:procurement_admins, id: false) do |t|
      t.column :user_id, :uuid, null: false
      t.index :user_id, unique: true
    end

    MigrationProcurementAccess.where(is_admin: true).each do |pa|
      begin
        execute <<-SQL
          INSERT INTO procurement_admins (user_id) VALUES ('#{pa.user_id}');
        SQL
      end
    end

    MigrationProcurementAccess.where(is_admin: true).delete_all

    execute 'SET CONSTRAINTS ALL IMMEDIATE'

    add_foreign_key :procurement_admins, :users
    remove_column :procurement_accesses, :is_admin
    add_index :procurement_accesses,
              [:user_id, :organization_id],
              unique: true,
              name: 'index_on_user_id_and_organization_id'
    change_column_null :procurement_accesses, :user_id, false
    change_column_null :procurement_accesses, :organization_id, false
    rename_table :procurement_accesses, :procurement_requesters_organizations
  end
        
  def down
    rename_table :procurement_requesters_organizations, :procurement_accesses
    add_column :procurement_accesses, :is_admin, :boolean
    remove_index :procurement_accesses, column: [:user_id, :organization_id]
    remove_foreign_key :procurement_accesses, :users

    MigrationProcurementAdmin.all.each do |pa|
      execute <<-SQL
        INSERT INTO procurement_accesses (user_id, is_admin) VALUES ('#{pa.user_id}', TRUE);
      SQL
    end

    drop_table :procurement_admins
  end
end

