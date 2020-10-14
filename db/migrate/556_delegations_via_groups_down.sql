DROP TRIGGER delegations_users_on_delete_t ON delegations_users;
DROP FUNCTION delegations_users_on_delete_f();
DROP TRIGGER delegations_users_on_insert_t ON delegations_users;
DROP FUNCTION delegations_users_on_insert_f();
DROP VIEW delegations_users;
DROP AGGREGATE delegations_users_type_agg(text);
DROP FUNCTION delegations_users_type_agg_f (tp1 text, tp2 text);
DROP AGGREGATE delegations_users_id_agg (uuid, uuid, uuid);
DROP FUNCTION delegations_users_id_agg_f (id1 uuid, id2 uuid, user_id uuid, delegation_id uuid);
DROP VIEW delegations_users_unified;
ALTER TABLE delegations_direct_users RENAME TO delegations_users;
ALTER TABLE delegations_users DROP COLUMN id;

