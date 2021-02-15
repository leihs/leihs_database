class UsersOrganizationConstraint < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      UPDATE users
      SET organization = 'local'
      WHERE organization = 'leihs-local'
    SQL

    execute <<~SQL
      ALTER TABLE users
      ADD CONSTRAINT organization_prefix CHECK (organization !~* '^leihs-')
    SQL
  end
end
