CREATE OR REPLACE VIEW unified_customer_orders AS
  -- contracts without orders
  SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || cs.id::text) AS id,
         cs.user_id,
         cs.purpose,
         ARRAY['APPROVED'] AS state,
         'CLOSED' AS rental_state,
         cs.created_at,
         cs.updated_at,
         NULL AS title,
         FALSE AS lending_terms_accepted,
         NULL AS contact_details,
         ( SELECT array_agg(id) FROM reservations AS rs WHERE rs.contract_id = cs.id ) AS reservation_ids,
         'contracts' AS origin_table
  FROM contracts AS cs
  WHERE NOT EXISTS (
    SELECT 1
    FROM reservations AS rs2
    WHERE rs2.contract_id = cs.id AND rs2.order_id IS NOT NULL
  )
  UNION
  -- hand overs
  SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || rs.user_id::text || rs.inventory_pool_id::text) AS id,
         rs.user_id,
         NULL AS purpose,
         ARRAY['APPROVED'] AS state,
         'OPEN' AS rental_state,
         MIN(rs.created_at) AS created_at,
         MAX(rs.updated_at) AS updated_at,
         NULL AS title,
         FALSE AS lending_terms_accepted,
         NULL AS contact_details,
         ARRAY_AGG(rs.id) AS reservation_ids,
         'reservations' AS origin_table
  FROM reservations AS rs
  WHERE rs.order_id IS NULL AND rs.contract_id IS NULL
  GROUP BY rs.user_id, rs.inventory_pool_id
  UNION
  -- customer orders
  SELECT customer_orders.id,
         customer_orders.user_id,
         customer_orders.purpose,
         ARRAY_AGG(DISTINCT UPPER(orders.state)) AS state,
         CASE
           WHEN ARRAY_AGG(DISTINCT UPPER(orders.state)) = '{"CLOSED"}' THEN 'CLOSED'
           ELSE 'OPEN'
         END AS state,
         customer_orders.created_at,
         customer_orders.updated_at,
         customer_orders.title,
         customer_orders.lending_terms_accepted,
         customer_orders.contact_details,
         ARRAY_AGG(reservations.id) AS reservation_ids,
         'customer_orders' AS origin_table
  FROM customer_orders
  JOIN orders ON orders.customer_order_id = customer_orders.id
  JOIN reservations ON reservations.order_id = orders.id
  GROUP BY customer_orders.id
