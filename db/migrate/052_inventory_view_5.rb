class InventoryView5 < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      DROP VIEW IF EXISTS inventory
    SQL

    execute <<-SQL
      CREATE OR REPLACE VIEW inventory AS

      SELECT id,
             product,
             version,
             name,
             CASE type
             WHEN 'Software' THEN 'Software'
             WHEN 'Model' THEN
               CASE WHEN is_package THEN 'Package' ELSE 'Model' END
             END AS type,
             'models' AS origin_table,
             manufacturer,
             NULL AS inventory_code,
             NULL AS price,
             NULL AS inventory_pool_id,
             cover_image_id,
             created_at,
             updated_at
      FROM models

      UNION

      SELECT id,
             product,
             version,
             name,
             'Option' AS type,
             'options' AS origin_table,
             manufacturer,
             inventory_code,
             price,
             inventory_pool_id,
             NULL AS cover_image_id,
             created_at,
             updated_at
      FROM options
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS inventory
    SQL
  end
end
