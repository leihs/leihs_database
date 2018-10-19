class CleanUpDuplicateAccessRights < ActiveRecord::Migration[5.0]
  class MigrationAccessRight < ActiveRecord::Base
    self.table_name = 'access_rights'
  end

  ROLES_HIERARCHY = ['inventory_manager',
                     'lending_manager',
                     'group_manager',
                     'customer']

  FIND_DUPLICATES_SQL = <<-SQL.strip_heredoc
    SELECT ar1.*
    FROM access_rights ar1
    JOIN users ON users.id = ar1.user_id
    WHERE EXISTS (
      SELECT TRUE
      FROM access_rights ar2
      WHERE ar1.user_id = ar2.user_id
        AND ar1.inventory_pool_id = ar2.inventory_pool_id
        AND ((ar1.deleted_at IS NULL AND ar2.deleted_at IS NULL) OR
             (ar1.deleted_at IS NOT NULL AND ar2.deleted_at IS NOT NULL))
        AND ar1.id != ar2.id
      );
  SQL

  def up
    execute <<-SQL.strip_heredoc
      ALTER TABLE access_rights
      ALTER COLUMN created_at SET DEFAULT now(),
      ALTER COLUMN updated_at SET DEFAULT now()
    SQL

    ars_count_before = MigrationAccessRight.count
    ars_duplicates = MigrationAccessRight.find_by_sql(FIND_DUPLICATES_SQL)
    puts("Number of duplicates: #{ars_duplicates.count}")

    ars_duplicates
      .group_by { |ar| [ar.user_id, ar.inventory_pool_id, ar.deleted_at] }
      .each do |_, ars2|
        ars2
          .sort do |ar1, ar2|
            ROLES_HIERARCHY.index(ar1.role) - ROLES_HIERARCHY.index(ar2.role)
          end
          .drop(1)
          .each(&:destroy)
      end

    deleted_count = (ars_count_before - MigrationAccessRight.count)
    puts("Number of deleted duplicates: #{deleted_count}")
  end

  def down
    execute <<-SQL.strip_heredoc
      ALTER TABLE access_rights
      ALTER COLUMN created_at DROP DEFAULT,
      ALTER COLUMN updated_at DROP DEFAULT
    SQL
  end
end
