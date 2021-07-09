class CreateCustomerOrdersView < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      CREATE OR REPLACE VIEW unified_customer_orders AS
        SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || cs.id::text) AS id,
               cs.user_id,
               cs.purpose,
               cs.created_at,
               cs.updated_at,
               NULL AS title,
               FALSE AS lending_terms_accepted,
               NULL AS contact_details,
               ( SELECT array_agg(id) FROM reservations AS rs WHERE rs.contract_id = cs.id ) AS reservation_ids,
               NULL AS origin_table
        FROM contracts AS cs
        WHERE NOT EXISTS (
          SELECT 1
          FROM reservations AS rs2
          WHERE rs2.contract_id = cs.id AND rs2.order_id IS NOT NULL
        )
        UNION
        SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || rs.user_id::text || rs.inventory_pool_id::text) AS id,
               rs.user_id,
               NULL AS purpose,
               min(rs.created_at) AS created_at,
               max(rs.updated_at) AS updated_at,
               NULL AS title,
               FALSE AS lending_terms_accepted,
               NULL AS contact_details,
               array_agg(rs.id) AS reservation_ids,
               NULL AS origin_table
        FROM reservations AS rs
        WHERE rs.order_id IS NULL AND rs.contract_id IS NULL
        GROUP BY rs.user_id, rs.inventory_pool_id
        UNION
        SELECT customer_orders.id,
               customer_orders.user_id,
               customer_orders.purpose,
               customer_orders.created_at,
               customer_orders.updated_at,
               customer_orders.title,
               customer_orders.lending_terms_accepted,
               customer_orders.contact_details,
               array_agg(reservations.id) AS reservation_ids,
               'customer_orders' AS origin_table
        FROM customer_orders
        JOIN orders ON orders.customer_order_id = customer_orders.id
        JOIN reservations ON reservations.order_id = orders.id
        GROUP BY customer_orders.id
    SQL
  end

  def down
    execute 'DROP VIEW unified_customer_orders'
  end
end
