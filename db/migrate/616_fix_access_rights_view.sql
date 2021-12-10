-- fixes 542_access_rights_view_up.sql

CREATE OR REPLACE FUNCTION ar_uuid_agg_f (id1 uuid, id2 uuid, user_id uuid, inventory_pool_id uuid) RETURNS uuid AS $$
BEGIN
  IF id1 IS NULL AND id2 IS NULL THEN
    RETURN uuid_generate_v3(uuid_nil(), user_id::TEXT || inventory_pool_id::TEXT);
  ELSIF id1 IS NOT NULL THEN
    RETURN id1;
  ELSE
    RETURN id2;
  END IF;
END;
$$ LANGUAGE plpgsql;

