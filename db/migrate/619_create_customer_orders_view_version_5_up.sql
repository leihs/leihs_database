DROP VIEW unified_customer_orders;

CREATE VIEW unified_customer_orders AS
  -- contracts without orders
  SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || cs.id::text) AS id,
         cs.user_id,
         cs.purpose,
         ARRAY['APPROVED'] AS state,
         UPPER(cs.state) AS rental_state,
         cs.created_at::date AS from_date,
         MAX(COALESCE(rs.returned_date, rs.end_date)) AS until_date,
         ARRAY[cs.inventory_pool_id] AS inventory_pool_ids,
         ( COALESCE(cs.purpose, '') || ' ' ||
           COALESCE(cs.note, '') || ' ' ||
           COALESCE(cs.compact_id, '') || ' ' ||
           STRING_AGG(COALESCE(ms.id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ms.product, '') || ' ' || COALESCE(ms.version, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ms.manufacturer, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.product, '') || ' ' || COALESCE(os.version, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.manufacturer, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.inventory_code, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".inventory_code, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".serial_number, ''), ' ') ) AS searchable,
         FALSE AS with_pickups,
         cs.state = 'open' AS with_returns,
         cs.created_at,
         cs.updated_at,
         NULL AS title,
         FALSE AS lending_terms_accepted,
         NULL AS contact_details,
         ARRAY_AGG(rs.id) AS reservation_ids,
         ARRAY_AGG(DISTINCT rs.status) AS reservation_states,
         'contracts' AS origin_table
  FROM contracts AS cs
  JOIN reservations AS rs ON rs.contract_id = cs.id
  LEFT JOIN models AS ms ON rs.model_id = ms.id
  LEFT JOIN options AS os ON rs.option_id = os.id
  LEFT JOIN items AS "is" ON rs.item_id = "is".id
  GROUP BY cs.id
  HAVING ARRAY_AGG(DISTINCT rs.order_id) = ARRAY[NULL::uuid]
  UNION
  -- hand overs
  SELECT uuid_generate_v5(uuid_ns_dns(), 'customer_order_' || rs.user_id::text || '_' || rs.inventory_pool_id::text) AS id,
         rs.user_id,
         NULL AS purpose,
         ARRAY['APPROVED'] AS state,
         CASE
           WHEN CURRENT_DATE > ALL(ARRAY_AGG(rs.end_date)) THEN 'CLOSED'
           ELSE 'OPEN'
         END AS rental_state,
         MIN(rs.start_date) AS from_date,
         MAX(rs.end_date) AS until_date,
         ARRAY_AGG(DISTINCT rs.inventory_pool_id) AS inventory_pool_ids,
         ( STRING_AGG(COALESCE(ms.product, '') || ' ' || COALESCE(ms.version, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ms.id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ms.manufacturer, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.product, '') || ' ' || COALESCE(os.version, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.manufacturer, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(os.inventory_code, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".inventory_code, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".serial_number, ''), ' ') ) AS searchable,
         TRUE AS with_pickups,
         FALSE AS with_returns,
         MIN(rs.created_at) AS created_at,
         MAX(rs.updated_at) AS updated_at,
         NULL AS title,
         FALSE AS lending_terms_accepted,
         NULL AS contact_details,
         ARRAY_AGG(rs.id) AS reservation_ids,
         ARRAY['approved'] AS reservation_states,
         'reservations' AS origin_table
  FROM reservations AS rs
  LEFT JOIN models AS ms ON rs.model_id = ms.id
  LEFT JOIN items AS "is" ON rs.item_id = "is".id
  LEFT JOIN options AS os ON rs.option_id = os.id
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
           WHEN EVERY (
             (rs.status = 'submitted' AND CURRENT_DATE > rs.end_date) OR
             (rs.status = 'approved' AND CURRENT_DATE > rs.end_date) OR
             (rs.status in ('closed', 'rejected', 'canceled'))
           ) THEN 'CLOSED'
           ELSE 'OPEN'
         END AS rental_state,
         MIN(COALESCE(cs.created_at::date, rs.start_date)) AS from_date,
         MAX(COALESCE(rs.returned_date, rs.end_date)) AS until_date,
         ARRAY_AGG(DISTINCT os.inventory_pool_id) AS inventory_pool_ids,
         ( COALESCE(co.purpose, '') || ' ' ||
           COALESCE(co.title, '') || ' ' ||
           STRING_AGG(COALESCE(cs.purpose, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(cs.note, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(cs.compact_id, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ms.id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ms.product, '') || ' ' || COALESCE(ms.version, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ms.manufacturer, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ops.id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ops.product, '') || ' ' || COALESCE(ops.version, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ops.manufacturer, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE(ops.inventory_code, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".id::text, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".inventory_code, ''), ' ') || ' ' ||
           STRING_AGG(COALESCE("is".serial_number, ''), ' ') ) AS searchable,
        'approved' = ANY(ARRAY_AGG(rs.status)) AS with_pickups,
        'signed' = ANY(ARRAY_AGG(rs.status)) AS with_returns,
         co.created_at,
         co.updated_at,
         co.title,
         co.lending_terms_accepted,
         co.contact_details,
         ARRAY_AGG(DISTINCT rs.id) AS reservation_ids,
         ARRAY_AGG(DISTINCT rs.status) AS reservation_states,
         'customer_orders' AS origin_table
  FROM customer_orders AS co
  JOIN orders AS os ON os.customer_order_id = co.id
  LEFT JOIN reservations rs1 ON rs1.order_id = os.id
  LEFT JOIN reservations rs
    ON rs.id = rs1.id OR
       rs.contract_id = rs1.contract_id AND rs.order_id IS NULL
  LEFT JOIN models AS ms ON rs.model_id = ms.id
  LEFT JOIN options AS ops ON rs.option_id = ops.id AND rs.order_id IS NULL
  LEFT JOIN items AS "is" ON rs.item_id = "is".id
  LEFT JOIN contracts AS cs ON rs.contract_id = cs.id
  GROUP BY co.id;
