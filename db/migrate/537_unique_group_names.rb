class UniqueGroupNames < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper
  def change
    add_index :groups, 'lower(name)', name: 'idx_group_name', unique: true
  end
end
