-- table `entitlement_groups_direct_users` was replaced by `entitlement_groups_users`
-- bug before: users' assignment via groups was not considered

CREATE OR REPLACE VIEW visits AS
SELECT uuid_generate_v5(uuid_ns_dns(), concat_ws('_'::text, visit_reservations.user_id, visit_reservations.inventory_pool_id, visit_reservations.status, visit_reservations.date)) AS id,
       visit_reservations.user_id,
       visit_reservations.inventory_pool_id,
       visit_reservations.date,
       visit_reservations.visit_type AS TYPE,
       CASE
           WHEN visit_reservations.status = 'submitted'::text THEN FALSE
           WHEN visit_reservations.status = ANY (ARRAY['approved'::text,
                                                       'signed'::text]) THEN TRUE
           ELSE NULL::boolean
       END AS is_approved,
       sum(visit_reservations.quantity) AS quantity,
       bool_or(visit_reservations.with_user_to_verify) AS with_user_to_verify,
       bool_or(visit_reservations.with_user_and_model_to_verify) AS with_user_and_model_to_verify,
       array_agg(visit_reservations.id) AS reservation_ids
FROM
  (SELECT reservations.id,
          reservations.user_id,
          reservations.inventory_pool_id,
          CASE
              WHEN reservations.status = ANY (ARRAY['submitted'::text,
                                                    'approved'::text]) THEN reservations.start_date
              WHEN reservations.status = 'signed'::text THEN reservations.end_date
              ELSE NULL::date
          END AS date,
          CASE
              WHEN reservations.status = ANY (ARRAY['submitted'::text,
                                                    'approved'::text]) THEN 'hand_over'::text
              WHEN reservations.status = 'signed'::text THEN 'take_back'::text
              ELSE NULL::text
          END AS visit_type,
          reservations.status,
          reservations.quantity,
          (EXISTS
             (SELECT 1
              FROM entitlement_groups_users
              JOIN entitlement_groups ON entitlement_groups.id = entitlement_groups_users.entitlement_group_id
              WHERE entitlement_groups_users.user_id = reservations.user_id
                AND entitlement_groups.is_verification_required IS TRUE)) AS with_user_to_verify,
          (EXISTS
             (SELECT 1
              FROM entitlements
              JOIN entitlement_groups ON entitlement_groups.id = entitlements.entitlement_group_id
              JOIN entitlement_groups_users ON entitlement_groups_users.entitlement_group_id = entitlement_groups.id
              WHERE entitlements.model_id = reservations.model_id
                AND entitlement_groups_users.user_id = reservations.user_id
                AND entitlement_groups.is_verification_required IS TRUE)) AS with_user_and_model_to_verify
   FROM reservations
   WHERE reservations.status = ANY (ARRAY['submitted'::text,
                                          'approved'::text,
                                          'signed'::text])) visit_reservations
GROUP BY visit_reservations.user_id,
         visit_reservations.inventory_pool_id,
         visit_reservations.date,
         visit_reservations.visit_type,
         visit_reservations.status;
