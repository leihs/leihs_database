ALTER TABLE delegations_users RENAME TO delegations_direct_users;
ALTER TABLE delegations_direct_users ADD id uuid PRIMARY KEY DEFAULT uuid_generate_v4();

CREATE VIEW delegations_users_unified AS
    SELECT
      id AS id,
      'direct_delegation' AS "type",
      user_id AS user_id,
      delegation_id AS delegation_id
    FROM delegations_direct_users
  UNION
    SELECT
      delegations_groups.id AS id,
      'group_delegation' AS "type",
      groups_users.user_id as user_id,
      delegations_groups.delegation_id AS delegation_id
    FROM delegations_groups
    INNER JOIN groups ON groups.id = delegations_groups.group_id
    INNER JOIN groups_users ON groups_users.group_id = groups.id;


-- id aggregate ---------------------------------------------------------------

CREATE FUNCTION delegations_users_id_agg_f
(id1 uuid, id2 uuid, user_id uuid, delegation_id uuid)
RETURNS uuid AS $$
BEGIN
  IF id1 IS NOT NULL AND id2 IS NOT NULL THEN
    RETURN uuid_generate_v3(uuid_nil(), user_id::TEXT || delegation_id::TEXT);
  ELSIF id1 IS NOT NULL THEN
    RETURN id1;
  ELSE
    RETURN id2;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE delegations_users_id_agg (uuid, uuid, uuid)
( sfunc =  delegations_users_id_agg_f,
  stype = uuid
);


-- type aggreagate ----------------------------------------------------------------------

CREATE FUNCTION delegations_users_type_agg_f (tp1 text, tp2 text)
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

CREATE AGGREGATE delegations_users_type_agg (text)
( sfunc = delegations_users_type_agg_f,
  stype = text
);




-- delegations_users view -----------------------------------------------

CREATE VIEW delegations_users AS
    SELECT
      delegations_users_id_agg(id, user_id, delegation_id) AS id,
      delegations_users_type_agg(type) AS type,
      delegation_id,
      user_id
    FROM delegations_users_unified
    GROUP BY (delegation_id, user_id);




-- INSERT on view delegations_users -------------------------------------

CREATE FUNCTION delegations_users_on_insert_f()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id iS NULL then
    NEW.id = uuid_generate_v4();
  END IF;
  INSERT INTO delegations_direct_users(id, user_id, delegation_id)
    VALUES (NEW.id, NEW.user_id, NEW.delegation_id);
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delegations_users_on_insert_t
INSTEAD OF insert ON delegations_users
FOR EACH ROW EXECUTE PROCEDURE delegations_users_on_insert_f();


-- DELETE on view delegations_users view ------------------------------------------

CREATE OR REPLACE FUNCTION delegations_users_on_delete_f()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM delegations_direct_users WHERE id = OLD.id) THEN
    RAISE EXCEPTION 'delegations_direct_users can not be deleted from delegations_users with id % when delegations_users represents mixed or group rights', NEW.id;
  ELSE
    DELETE FROM delegations_direct_users WHERE id = OLD.id;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delegations_users_on_delete_t
INSTEAD OF DELETE ON delegations_users
FOR EACH ROW EXECUTE PROCEDURE delegations_users_on_delete_f();

