class InventoryView < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      CREATE OR REPLACE VIEW inventory AS

      SELECT id,
             product,
             version,
             type,
             'models' AS origin_table,
             is_package,
             manufacturer,
             NULL AS inventory_code,
             NULL AS price,
             NULL AS inventory_pool_id
      FROM models

      UNION

      SELECT id,
             product,
             version,
             'Option' AS type,
             'options' AS origin_table,
             FALSE AS is_package,
             manufacturer,
             inventory_code,
             price,
             inventory_pool_id
      FROM options
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS inventory
    SQL
  end
end
