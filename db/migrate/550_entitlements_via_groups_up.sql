ALTER TABLE entitlement_groups_users RENAME TO entitlement_groups_direct_users;
ALTER TABLE entitlement_groups_direct_users ADD id uuid PRIMARY KEY DEFAULT uuid_generate_v4();

CREATE VIEW entitlement_groups_users_unified AS
    SELECT
      id AS id,
      'direct_entitlement' AS "type",
      user_id AS user_id,
      entitlement_group_id AS entitlement_group_id
    FROM entitlement_groups_direct_users
  UNION
    SELECT
      entitlement_groups_groups.id AS id,
      'group_entitlement' AS "type",
      groups_users.user_id as user_id,
      entitlement_groups_groups.entitlement_group_id AS entitlement_group_id
    FROM entitlement_groups_groups
    INNER JOIN groups ON groups.id = entitlement_groups_groups.group_id
    INNER JOIN groups_users ON groups_users.group_id = groups.id;


-- id aggregate ---------------------------------------------------------------

CREATE FUNCTION entitlement_groups_users_id_agg_f
(id1 uuid, id2 uuid, user_id uuid, entitlement_group_id uuid)
RETURNS uuid AS $$
BEGIN
  IF id1 IS NOT NULL AND id2 IS NOT NULL THEN
    RETURN uuid_generate_v3(uuid_nil(), user_id::TEXT || inventory_pool_id::TEXT);
  ELSIF id1 IS NOT NULL THEN
    RETURN id1;
  ELSE
    RETURN id2;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE entitlement_groups_users_id_agg (uuid, uuid, uuid)
( sfunc =  entitlement_groups_users_id_agg_f,
  stype = uuid
);


-- type aggreagate ----------------------------------------------------------------------

CREATE FUNCTION entitlement_groups_users_type_agg_f (tp1 text, tp2 text)
RETURNS text AS $$
BEGIN
  IF tp1 IS NOT NULL AND tp2 IS NOT NULL THEN
    RETURN 'mixed';
  ELSIF tp1 IS NOT NULL THEN
    RETURN tp1;
  ELSE
    RETURN tp2 ;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE entitlement_groups_users_type_agg (text)
( sfunc = entitlement_groups_users_type_agg_f,
  stype = text
);




-- entitlement_groups_users view -----------------------------------------------

CREATE VIEW entitlement_groups_users AS
    SELECT
      entitlement_groups_users_id_agg(id, user_id, entitlement_group_id) AS id,
      entitlement_groups_users_type_agg(type) AS type,
      entitlement_group_id,
      user_id
    FROM entitlement_groups_users_unified
    GROUP BY (entitlement_group_id, user_id);




-- INSERT on view entitlement_groups_users -------------------------------------

CREATE FUNCTION entitlement_groups_users_on_insert_f()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id iS NULL then
    NEW.id = uuid_generate_v4();
  END IF;
  INSERT INTO entitlement_groups_direct_users(id, user_id, entitlement_group_id)
    VALUES (NEW.id, NEW.user_id, NEW.entitlement_group_id);
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER entitlement_groups_users_on_insert_t
INSTEAD OF insert ON entitlement_groups_users
FOR EACH ROW EXECUTE PROCEDURE entitlement_groups_users_on_insert_f();


-- DELETE on view entitlement_groups_users view ------------------------------------------

CREATE OR REPLACE FUNCTION entitlement_groups_users_on_delete_f()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM entitlement_groups_direct_users WHERE id = OLD.id) THEN
    RAISE EXCEPTION 'entitlement_groups_direct_users can not be deleted from entitlement_groups_users with id % when entitlement_groups_users represents mixed or group rights', NEW.id;
  ELSE
    DELETE FROM entitlement_groups_direct_users WHERE id = OLD.id;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER entitlement_groups_users_on_delete_t
INSTEAD OF DELETE ON entitlement_groups_users
FOR EACH ROW EXECUTE PROCEDURE entitlement_groups_users_on_delete_f();

