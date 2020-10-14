DROP TRIGGER entitlement_groups_users_on_delete_t ON entitlement_groups_users;
DROP FUNCTION entitlement_groups_users_on_delete_f();
DROP TRIGGER entitlement_groups_users_on_insert_t ON entitlement_groups_users;
DROP FUNCTION entitlement_groups_users_on_insert_f();
DROP VIEW entitlement_groups_users;
DROP AGGREGATE entitlement_groups_users_type_agg(text);
DROP FUNCTION entitlement_groups_users_type_agg_f (tp1 text, tp2 text);
DROP AGGREGATE entitlement_groups_users_id_agg (uuid, uuid, uuid);
DROP FUNCTION entitlement_groups_users_id_agg_f (id1 uuid, id2 uuid, user_id uuid, entitlement_group_id uuid);
DROP VIEW entitlement_groups_users_unified;
ALTER TABLE entitlement_groups_direct_users RENAME TO entitlement_groups_users;
ALTER TABLE entitlement_groups_users DROP COLUMN id;

