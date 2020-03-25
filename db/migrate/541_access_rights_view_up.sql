-- id aggregate ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION ar_uuid_agg_f (id1 uuid, id2 uuid)
RETURNS uuid AS $$
BEGIN
  IF id1 IS NOT NULL AND id2 IS NOT NULL THEN
    RETURN uuid_nil();
  ELSIF id1 IS NOT NULL THEN
    RETURN id1;
  ELSE
    RETURN id2;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE ar_uuid_agg (uuid)
( sfunc = ar_uuid_agg_f,
  stype = uuid
);


-- origin_table aggregate ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION origin_table_agg_f (ot1 text, ot2 text)
RETURNS text AS $$
BEGIN
  IF ot1 IS NOT NULL AND ot2 IS NOT NULL THEN
    RETURN 'mixed';
  ELSIF ot1 IS NOT NULL THEN
    RETURN ot1;
  ELSE
    RETURN ot2 ;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE origin_table_agg (text)
( sfunc = origin_table_agg_f,
  stype = text
);



-- role aggregate -------------------------------------------------------------

CREATE OR REPLACE FUNCTION role_agg_f (role1 text, role2 text)
RETURNS text AS $$
BEGIN
  IF role1 = 'inventory_manager' OR role2 = 'inventory_manager' THEN
    RETURN 'inventory_manager';
  ELSIF role1 = 'lending_manager' OR role2 = 'lending_manager' THEN
    RETURN 'lending_manager';
  ELSIF role1 = 'group_manager' OR role2 = 'group_manager' THEN
    RETURN 'group_manager';
  ELSIF role1 = 'customer' OR role2 = 'customer' THEN
    RETURN 'customer';
    -- ELSE
    -- RAISE 'no role condition matched';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE role_agg (text)
( sfunc = role_agg_f,
  stype = text
);


-- access_rights view ---------------------------------------------------------

CREATE VIEW access_rights AS
    SELECT
      ar_uuid_agg(id) AS id,
      origin_table_agg(origin_table) AS origin_table,
      inventory_pool_id,
      user_id,
      role_agg(role) AS role
    FROM unified_access_rights
    GROUP BY (inventory_pool_id, user_id);



-- INSERT on view access_rights view ------------------------------------------

CREATE OR REPLACE FUNCTION access_rights_on_insert_f()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id iS NULL then
    NEW.id = uuid_generate_v4();
  END IF;
  INSERT INTO direct_access_rights(id, user_id, inventory_pool_id, role)
    VALUES (NEW.id, NEW.user_id, NEW.inventory_pool_id, NEW.role);
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER access_rights_on_insert_t
INSTEAD OF insert ON access_rights
FOR EACH ROW EXECUTE PROCEDURE access_rights_on_insert_f();


-- DELETE on view access_rights view ------------------------------------------

CREATE OR REPLACE FUNCTION access_rights_on_delete_f()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM direct_access_rights WHERE id = OLD.id) THEN
    RAISE EXCEPTION 'direct_access_rights can not be deleted from access_rights with id % when access_rights represents mixed or group rights', NEW.id;
  ELSE
    DELETE FROM direct_access_rights WHERE id = OLD.id;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER access_rights_on_delete_t
INSTEAD OF DELETE ON access_rights
FOR EACH ROW EXECUTE PROCEDURE access_rights_on_delete_f();


-- UPDATE on view access_rights view ------------------------------------------

CREATE OR REPLACE FUNCTION access_rights_on_update_f()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM direct_access_rights WHERE id = NEW.id) THEN
    RAISE EXCEPTION 'direct_access_rights can not be updated from access_rights with id % when access_rights represents mixed or group rights', NEW.id;
  ELSE
    UPDATE direct_access_rights SET role = NEW.role WHERE direct_access_rights.id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER access_rights_on_update_t
INSTEAD OF UPDATE ON access_rights
FOR EACH ROW EXECUTE PROCEDURE access_rights_on_update_f();
