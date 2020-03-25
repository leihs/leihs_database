DROP TRIGGER access_rights_on_insert_t ON access_rights;
DROP FUNCTION access_rights_on_insert_f();

DROP VIEW access_rights;

DROP AGGREGATE origin_table_agg(text);
DROP FUNCTION origin_table_agg_f(text, text);

DROP AGGREGATE ar_uuid_agg(uuid);
DROP FUNCTION ar_uuid_agg_f(uuid, uuid);

DROP AGGREGATE role_agg (text);
DROP FUNCTION role_agg_f (text, text);
