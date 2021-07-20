CREATE OR REPLACE VIEW unified_customer_orders AS
  -- contracts without orders
  SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || cs.id::text) AS id,
         cs.user_id,
         cs.purpose,
         ARRAY['APPROVED'] AS state,
         UPPER(cs.state) AS rental_state,
         ( SELECT MIN(start_date) FROM reservations AS rs WHERE rs.contract_id = cs.id ) AS from_date,
         ( SELECT MAX(end_date) FROM reservations AS rs WHERE rs.contract_id = cs.id ) AS until_date,
         ARRAY[cs.inventory_pool_id] AS inventory_pool_ids,
         ( COALESCE(cs.purpose, '') || ' ' ||
           COALESCE(cs.note, '') || ' ' ||
           STRING_AGG(ms.product || ' ' || COALESCE(ms.version, ''), ' ') ) AS searchable,
         FALSE AS with_pickups,
         cs.state = 'open' AS with_returns,
         cs.created_at,
         cs.updated_at,
         NULL AS title,
         FALSE AS lending_terms_accepted,
         NULL AS contact_details,
         ( SELECT array_agg(id) FROM reservations AS rs WHERE rs.contract_id = cs.id ) AS reservation_ids,
         'contracts' AS origin_table
  FROM contracts AS cs
  JOIN reservations AS rs ON rs.contract_id = cs.id
  JOIN models AS ms ON rs.model_id = ms.id
  GROUP BY cs.id
  HAVING ARRAY_AGG(DISTINCT rs.order_id) = ARRAY[NULL::uuid]
  UNION
  -- hand overs
  SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || rs.user_id::text || rs.inventory_pool_id::text) AS id,
         rs.user_id,
         NULL AS purpose,
         ARRAY['APPROVED'] AS state,
         'OPEN' AS rental_state,
         MIN(rs.start_date) AS from_date,
         MAX(rs.end_date) AS until_date,
         ARRAY_AGG(DISTINCT rs.inventory_pool_id) AS inventory_pool_ids,
         STRING_AGG(ms.product || ' ' || COALESCE(ms.version, '') , ' ') AS searchable,
         TRUE AS with_pickups,
         FALSE AS with_returns,
         MIN(rs.created_at) AS created_at,
         MAX(rs.updated_at) AS updated_at,
         NULL AS title,
         FALSE AS lending_terms_accepted,
         NULL AS contact_details,
         ARRAY_AGG(rs.id) AS reservation_ids,
         'reservations' AS origin_table
  FROM reservations AS rs
  JOIN models AS ms ON rs.model_id = ms.id
  WHERE rs.order_id IS NULL AND rs.contract_id IS NULL
    AND rs.status = 'approved'
  GROUP BY rs.user_id, rs.inventory_pool_id
  UNION
  -- customer orders
  SELECT co.id,
         co.user_id,
         co.purpose,
         ARRAY_AGG(DISTINCT UPPER(os.state)) AS state,
         CASE
           WHEN ARRAY_AGG(DISTINCT UPPER(os.state)) = '{"CLOSED"}' THEN 'CLOSED'
           ELSE 'OPEN'
         END AS rental_state,
         MIN(rs.start_date) AS from_date,
         MAX(rs.end_date) AS until_date,
         ARRAY_AGG(DISTINCT os.inventory_pool_id) AS inventory_pool_ids,
         ( co.purpose || ' ' ||
           co.title || ' ' ||
           COALESCE(cs.purpose, '') || ' ' ||
           COALESCE(cs.note, '') || ' ' ||
           STRING_AGG(ms.product || ' ' || COALESCE(ms.version, ''), ' ') ) AS searchable,
        'approved' = ANY(ARRAY_AGG(rs.status)) AS with_pickups,
        'signed' = ANY(ARRAY_AGG(rs.status)) AS with_returns,
         co.created_at,
         co.updated_at,
         co.title,
         co.lending_terms_accepted,
         co.contact_details,
         ARRAY_AGG(rs.id) AS reservation_ids,
         'customer_orders' AS origin_table
  FROM customer_orders AS co
  JOIN orders AS os ON os.customer_order_id = co.id
  JOIN reservations AS rs ON rs.order_id = os.id
  JOIN models AS ms ON rs.model_id = ms.id
  LEFT JOIN contracts AS cs ON rs.contract_id = cs.id
  GROUP BY co.id, cs.purpose, cs.note
