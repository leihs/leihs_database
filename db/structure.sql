--
-- PostgreSQL database dump
--

-- Dumped from database version 10.13
-- Dumped by pg_dump version 10.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: access_rights_on_delete_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.access_rights_on_delete_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM direct_access_rights WHERE id = OLD.id) THEN
    RAISE EXCEPTION 'direct_access_rights can not be deleted from access_rights with id % when access_rights represents mixed or group rights', NEW.id;
  ELSE
    DELETE FROM direct_access_rights WHERE id = OLD.id;
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: access_rights_on_insert_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.access_rights_on_insert_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.id iS NULL then
    NEW.id = uuid_generate_v4();
  END IF;
  INSERT INTO direct_access_rights(id, user_id, inventory_pool_id, role)
    VALUES (NEW.id, NEW.user_id, NEW.inventory_pool_id, NEW.role);
  RETURN NEW;
END;
$$;


--
-- Name: access_rights_on_update_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.access_rights_on_update_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM direct_access_rights WHERE id = NEW.id) THEN
    RAISE EXCEPTION 'direct_access_rights can not be updated from access_rights with id % when access_rights represents mixed or group rights', NEW.id;
  ELSE
    UPDATE direct_access_rights SET role = NEW.role WHERE direct_access_rights.id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: ar_uuid_agg_f(uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ar_uuid_agg_f(id1 uuid, id2 uuid, user_id uuid, inventory_pool_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF id1 IS NOT NULL AND id2 IS NOT NULL THEN
    RETURN uuid_generate_v3(uuid_nil(), user_id::TEXT || inventory_pool_id::TEXT);
  ELSIF id1 IS NOT NULL THEN
    RETURN id1;
  ELSE
    RETURN id2;
  END IF;
END;
$$;


--
-- Name: audit_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    changed JSONB;
    j_new JSONB := '{}'::JSONB;
    j_old JSONB := '{}'::JSONB;
    pkey TEXT;
    pkey_col TEXT := (
                SELECT attname
                FROM pg_index
                JOIN pg_attribute ON
                    attrelid = indrelid
                    AND attnum = ANY(indkey)
                WHERE indrelid = TG_RELID AND indisprimary);
BEGIN
  IF (TG_OP = 'DELETE') THEN
    j_old := row_to_json(OLD)::JSONB;
    pkey := j_old ->> pkey_col;
  ELSIF (TG_OP = 'INSERT') THEN
    j_new := row_to_json(NEW)::JSONB;
    pkey := j_new ->> pkey_col;
  ELSIF (TG_OP = 'UPDATE') THEN
    j_old := row_to_json(OLD)::JSONB;
    j_new := row_to_json(NEW)::JSONB;
    pkey := j_old ->> pkey_col;
  END IF;
  changed := jsonb_changed(j_old, j_new);
  if ( changed <> '{}'::JSONB ) THEN
    INSERT INTO audited_changes (tg_op, table_name, changed, pkey)
      VALUES (TG_OP, TG_TABLE_NAME, changed, pkey);
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: check_closed_reservations_contract_state(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_closed_reservations_contract_state() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          NEW.status = 'closed' AND
          NOT EXISTS(
            SELECT 1
            FROM reservations
            WHERE contract_id = NEW.contract_id AND status != 'closed')
          ) AND
          (SELECT state FROM contracts WHERE contracts.id = NEW.contract_id) != 'closed'
        THEN
          RAISE EXCEPTION 'If all reservations are closed then the contract must be closed as well';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_contract_has_at_least_one_reservation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_contract_has_at_least_one_reservation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1
          FROM reservations
          WHERE contract_id = NEW.id)
        THEN
          RAISE EXCEPTION 'contract must have at least one reservation';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_exactly_one_default_language(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_exactly_one_default_language() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF ((SELECT count(*) FROM languages WHERE "default") != 1 OR
      EXISTS (SELECT TRUE FROM languages WHERE "default" and not active))
  THEN
    RAISE EXCEPTION 'There must be exactly one default language which is also active.';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: check_general_building_id_for_general_room(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_general_building_id_for_general_room() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          OLD.general IS TRUE
          AND OLD.building_id != NEW.building_id
          )
          THEN RAISE EXCEPTION
            'Building ID cannot be changed for a general room';
        END IF;
        RETURN NEW;
      END;
      $$;


--
-- Name: check_item_line_state_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_item_line_state_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          (NEW.type = 'ItemLine' AND NEW.status = 'submitted' AND EXISTS (
            SELECT 1
            FROM orders
            WHERE id = NEW.order_id AND state <> 'submitted')) OR
          (NEW.type = 'ItemLine' AND NEW.status = 'rejected' AND EXISTS (
            SELECT 1
            FROM orders
            WHERE id = NEW.order_id AND state <> 'rejected')) OR
          (NEW.type = 'ItemLine' AND NEW.status IN ('approved', 'signed', 'closed') AND EXISTS (
            SELECT 1
            FROM orders
            WHERE id = NEW.order_id AND state <> 'approved'))
        )
        THEN
          RAISE EXCEPTION 'state between item line and order is inconsistent';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_option_line_state_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_option_line_state_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          NEW.type = 'OptionLine' AND EXISTS (
            SELECT 1
            FROM orders
            WHERE id = NEW.order_id)
        )
        THEN
          RAISE EXCEPTION 'option line cannot belong to an order';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_parent_id_for_organization_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_parent_id_for_organization_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          SELECT true
          FROM procurement_organizations
          WHERE id = NEW.organization_id 
            AND parent_id IS NULL 
        ) THEN
          RAISE EXCEPTION 'Associated organization must have a parent.';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_presence_of_workday_for_inventory_pool(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_presence_of_workday_for_inventory_pool() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT true
          FROM workdays
          WHERE inventory_pool_id = NEW.id
        ) THEN
          RAISE EXCEPTION 'An inventory pool must have a workday.';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_reservation_contract_inventory_pool_id_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_reservation_contract_inventory_pool_id_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          NEW.inventory_pool_id != (
            SELECT inventory_pool_id
            FROM contracts
            WHERE id = NEW.contract_id)
        )
        THEN
          RAISE EXCEPTION 'inventory_pool_id between reservation and contract is inconsistent';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_reservation_contract_user_id_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_reservation_contract_user_id_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          NEW.user_id != (
            SELECT user_id
            FROM contracts
            WHERE id = NEW.contract_id)
        )
        THEN
          RAISE EXCEPTION 'user_id between reservation and contract is inconsistent';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_reservation_order_inventory_pool_id_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_reservation_order_inventory_pool_id_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          NEW.inventory_pool_id != (
            SELECT inventory_pool_id
            FROM orders
            WHERE id = NEW.order_id)
        )
        THEN
          RAISE EXCEPTION 'inventory_pool_id between reservation and order is inconsistent';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_reservation_order_user_id_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_reservation_order_user_id_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          NEW.user_id != (
            SELECT user_id
            FROM orders
            WHERE id = NEW.order_id)
        )
        THEN
          RAISE EXCEPTION 'user_id between reservation and order is inconsistent';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: check_reservations_contracts_state_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_reservations_contracts_state_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          NEW.state = 'closed' AND (
            SELECT count(*)
            FROM reservations
            WHERE contract_id = NEW.id AND status != 'closed') > 0
        )
        THEN
          RAISE EXCEPTION 'all reservations of a closed contract must be closed as well';
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: clean_email(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clean_email() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.email = nullif(trim(NEW.email),'');
  RETURN NEW;
END;
$$;


--
-- Name: delegations_users_id_agg_f(uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delegations_users_id_agg_f(id1 uuid, id2 uuid, user_id uuid, delegation_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF id1 IS NOT NULL AND id2 IS NOT NULL THEN
    RETURN uuid_generate_v3(uuid_nil(), user_id::TEXT || delegation_id::TEXT);
  ELSIF id1 IS NOT NULL THEN
    RETURN id1;
  ELSE
    RETURN id2;
  END IF;
END;
$$;


--
-- Name: delegations_users_on_delete_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delegations_users_on_delete_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM delegations_direct_users WHERE id = OLD.id) THEN
    RAISE EXCEPTION 'delegations_direct_users can not be deleted from delegations_users with id % when delegations_users represents mixed or group rights', NEW.id;
  ELSE
    DELETE FROM delegations_direct_users WHERE id = OLD.id;
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: delegations_users_on_insert_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delegations_users_on_insert_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.id iS NULL then
    NEW.id = uuid_generate_v4();
  END IF;
  INSERT INTO delegations_direct_users(id, user_id, delegation_id)
    VALUES (NEW.id, NEW.user_id, NEW.delegation_id);
  RETURN NEW;
END;
$$;


--
-- Name: delegations_users_type_agg_f(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delegations_users_type_agg_f(tp1 text, tp2 text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF tp1 IS NOT NULL AND tp2 IS NOT NULL THEN
    RETURN 'mixed';
  ELSIF tp1 IS NOT NULL THEN
    RETURN tp1;
  ELSE
    RETURN tp2 ;
  END IF;
END;
$$;


--
-- Name: delete_empty_order(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        result text;
      BEGIN
        IF (
          NOT EXISTS (
            SELECT 1
            FROM reservations
            WHERE reservations.order_id = OLD.order_id
        ))
        THEN
          DELETE FROM orders WHERE orders.id = OLD.order_id;
        END IF;

        RETURN OLD;
      END;
      $$;


--
-- Name: delete_obsolete_user_password_resets_1(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_obsolete_user_password_resets_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            DELETE FROM user_password_resets
            WHERE user_id = NEW.user_id;

            RETURN NEW;
          END;
          $$;


--
-- Name: delete_obsolete_user_password_resets_2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_obsolete_user_password_resets_2() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF NEW.authentication_system_id = 'password' THEN
              DELETE FROM user_password_resets
              WHERE user_id = NEW.user_id;
            END IF;

            RETURN NEW;
          END;
          $$;


--
-- Name: delete_procurement_users_filters_after_users(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_procurement_users_filters_after_users() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF
    (EXISTS
      (SELECT 1
       FROM procurement_users_filters
       WHERE procurement_users_filters.user_id = OLD.id))
  THEN
    DELETE FROM procurement_users_filters
    WHERE procurement_users_filters.user_id = OLD.id;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: ensure_general_building_cannot_be_deleted(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_general_building_cannot_be_deleted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (OLD.id = 'abae04c5-d767-425e-acc2-7ce04df645d1')
          THEN RAISE EXCEPTION
            'Building with ID = abae04c5-d767-425e-acc2-7ce04df645d1 cannot be deleted.';
        END IF;
        RETURN NEW;
      END;
      $$;


--
-- Name: ensure_general_room_cannot_be_deleted(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_general_room_cannot_be_deleted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (
          OLD.general IS TRUE
          AND EXISTS (SELECT 1 FROM buildings WHERE id = OLD.building_id)
          )
          THEN RAISE EXCEPTION
            'There must be a general room for every building.';
        END IF;
        RETURN NEW;
      END;
      $$;


--
-- Name: entitlement_groups_users_id_agg_f(uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.entitlement_groups_users_id_agg_f(id1 uuid, id2 uuid, user_id uuid, entitlement_group_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF id1 IS NOT NULL AND id2 IS NOT NULL THEN
    RETURN uuid_generate_v3(uuid_nil(), user_id::TEXT || inventory_pool_id::TEXT);
  ELSIF id1 IS NOT NULL THEN
    RETURN id1;
  ELSE
    RETURN id2;
  END IF;
END;
$$;


--
-- Name: entitlement_groups_users_on_delete_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.entitlement_groups_users_on_delete_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM entitlement_groups_direct_users WHERE id = OLD.id) THEN
    RAISE EXCEPTION 'entitlement_groups_direct_users can not be deleted from entitlement_groups_users with id % when entitlement_groups_users represents mixed or group rights', NEW.id;
  ELSE
    DELETE FROM entitlement_groups_direct_users WHERE id = OLD.id;
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: entitlement_groups_users_on_insert_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.entitlement_groups_users_on_insert_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.id iS NULL then
    NEW.id = uuid_generate_v4();
  END IF;
  INSERT INTO entitlement_groups_direct_users(id, user_id, entitlement_group_id)
    VALUES (NEW.id, NEW.user_id, NEW.entitlement_group_id);
  RETURN NEW;
END;
$$;


--
-- Name: entitlement_groups_users_type_agg_f(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.entitlement_groups_users_type_agg_f(tp1 text, tp2 text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF tp1 IS NOT NULL AND tp2 IS NOT NULL THEN
    RETURN 'mixed';
  ELSIF tp1 IS NOT NULL THEN
    RETURN tp1;
  ELSE
    RETURN tp2 ;
  END IF;
END;
$$;


--
-- Name: fields_delete_check_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fields_delete_check_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

  IF (
    NOT OLD.dynamic
  )
  THEN
    RAISE EXCEPTION 'Cannot delete field which is not dynamic.';
    RETURN OLD;
  END IF;


  IF (
    -- Check if there is an item which uses the field.
    EXISTS (
      SELECT 1
      FROM items
      WHERE items.properties::jsonb ? (OLD.data::json#>>'{attribute,1}')
    )
  )
  THEN
    RAISE EXCEPTION 'Cannot delete field which is still in use.';
    RETURN OLD;
  END IF;

  RETURN OLD;
END;
$$;


--
-- Name: fields_insert_check_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fields_insert_check_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN

        IF (
          not NEW.dynamic
        )
        THEN
          RAISE EXCEPTION 'New fields must always be dynamic.';
          RETURN NEW;
        END IF;

              IF (NEW.dynamic and not -- At least one character after underline.
(
  NEW.id like 'properties\__%'
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_properties_id_format !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (
    -- No other attributes in data than these ones.
    array['attribute', 'default', 'forPackage', 'group', 'label', 'permissions', 'target_type', 'type', 'values']
    @>
    array(select json_object_keys(NEW.data::json))
  )
  and
  (
    -- These keys are always mandatory (some can be null, check further checks, but the keys must exist).
    NEW.data::jsonb ?& array['type', 'group', 'label', 'attribute', 'permissions']
  )
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_data_json_keys !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not -- The attribute must have the right format.
(
  NEW.data::json->'attribute' is not null
  and json_typeof(NEW.data::json->'attribute') = 'array'
  and json_array_length(NEW.data::json->'attribute') = 2
  and (NEW.data::json#>>'{attribute,0}') = 'properties'
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_attributes_format !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not -- The attribute name must match the id.
(
  NEW.id = 'properties_' || (NEW.data::json#>>'{attribute,1}')
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_attribute_name !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->'permissions') is not null
  and (NEW.data::json->'permissions'->>'role') is not null
  and (NEW.data::json->'permissions'->>'owner') is not null
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_permissions !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'type') is not null
  and (NEW.data::json->>'type') in ('text', 'date', 'select', 'textarea', 'radio', 'checkbox')
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_type !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'label') is not null
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_label !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'target_type') is null
  or (NEW.data::json->>'target_type') in ('item', 'license')
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_target_type !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'required') is null
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_required !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (
    not (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')
    and NEW.data::json->'values' is null

  )
  or
  (

    (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')


    and json_typeof(NEW.data::json->'values') = 'array'

    -- There should not exist values which do not match the expected properties.
    and not exists (

      -- The values as a json row list.
      with vs as (
      	select jsonb_array_elements(NEW.data::jsonb->'values') as v
      ),

      -- The values as an array row list.
      arr as (
      	select
      		array_to_json(array(
      			select jsonb_object_keys(v::jsonb)
      		)) as arr
      	from
      		vs
      )

      -- Find the ones which have not 2 keys or not the expected properties.
      select
      	*
      from
      	arr
      where
      	json_array_length(arr) <> 2
      	or not (arr::jsonb @> '["label","value"]'::jsonb)
    )

  )

)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_values !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (

  not (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')

  or (
    (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')

    and (

      with vs as (
        select jsonb_array_elements(NEW.data::jsonb->'values') as v
      )

      select
      (

        -- We need to wrap it otherwise count will not count null values.
        select count(*) from (
          select
              distinct v::json->>'value'
          from
              vs v
        ) as sub
      )

      =

      (
        -- We need to wrap it otherwise count will not count null values.
        select count(*) from (
          select
              v::json->>'value'
          from
              vs v
        ) as sub
      )

    )
  )

)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_distinct_values !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  -- Check default only for radio and select.
  (
    not (NEW.data::json->>'type') in ('radio', 'select')
    and NEW.data::json->'default' is null
  )
  or
  (
    (NEW.data::json->>'type') in ('radio', 'select')

    and

    (
      (NEW.data::json->'values' is null)
      and
      (NEW.data::json->'default' is null)

      or

      (NEW.data::json->'values' is not null)
      and
      (NEW.data::json->'default' is not null)
      and 1 = (

        with vs as (
          select jsonb_array_elements(NEW.data::jsonb->'values') as v
        )

        -- Check that there exists a value equal to the default value or both are null.
        select
          count(*)
        from
          vs v
        where
          (v::json->>'value') = (NEW.data::jsonb->>'default')
          or (v::json->>'value') is null and (NEW.data::jsonb->>'default') is null

      )
    )
  )
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_default !!!!!'; RETURN NEW;
      END IF;


        RETURN NEW;
      END;
      $$;


--
-- Name: fields_update_check_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fields_update_check_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN

        IF (
          not NEW.dynamic
          and not (
            -- Id may not change.
            NEW.id = OLD.id

            and
            -- Data must be same as before except the label, permissions.role and permission.owner.
            jsonb_pretty(NEW.data::jsonb)
            =
            jsonb_pretty(
              jsonb_set(
                jsonb_set(
                  jsonb_set(
                    OLD.data::jsonb,
                    '{label}',
                    (NEW.data::jsonb->'label'),
                    false
                  ),
                  '{permissions,role}',
                  (NEW.data::jsonb->'permissions'->'role'),
                  false
                ),
                '{permissions,owner}',
                (NEW.data::jsonb->'permissions'->'owner'),
                false
              )
            )
          )
        )
        THEN
          RAISE EXCEPTION 'None dynamic fields only allow to change the attributes active, position, data.label, data.permissions.role and data.permissions.owner.';
          RETURN NEW;
        END IF;

              IF (NEW.dynamic and not -- At least one character after underline.
(
  NEW.id like 'properties\__%'
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_properties_id_format !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (
    -- No other attributes in data than these ones.
    array['attribute', 'default', 'forPackage', 'group', 'label', 'permissions', 'target_type', 'type', 'values']
    @>
    array(select json_object_keys(NEW.data::json))
  )
  and
  (
    -- These keys are always mandatory (some can be null, check further checks, but the keys must exist).
    NEW.data::jsonb ?& array['type', 'group', 'label', 'attribute', 'permissions']
  )
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_data_json_keys !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not -- The attribute must have the right format.
(
  NEW.data::json->'attribute' is not null
  and json_typeof(NEW.data::json->'attribute') = 'array'
  and json_array_length(NEW.data::json->'attribute') = 2
  and (NEW.data::json#>>'{attribute,0}') = 'properties'
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_attributes_format !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not -- The attribute name must match the id.
(
  NEW.id = 'properties_' || (NEW.data::json#>>'{attribute,1}')
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_attribute_name !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->'permissions') is not null
  and (NEW.data::json->'permissions'->>'role') is not null
  and (NEW.data::json->'permissions'->>'owner') is not null
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_permissions !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'type') is not null
  and (NEW.data::json->>'type') in ('text', 'date', 'select', 'textarea', 'radio', 'checkbox')
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_type !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'label') is not null
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_label !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'target_type') is null
  or (NEW.data::json->>'target_type') in ('item', 'license')
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_target_type !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (NEW.data::json->>'required') is null
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_required !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  (
    not (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')
    and NEW.data::json->'values' is null

  )
  or
  (

    (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')


    and json_typeof(NEW.data::json->'values') = 'array'

    -- There should not exist values which do not match the expected properties.
    and not exists (

      -- The values as a json row list.
      with vs as (
      	select jsonb_array_elements(NEW.data::jsonb->'values') as v
      ),

      -- The values as an array row list.
      arr as (
      	select
      		array_to_json(array(
      			select jsonb_object_keys(v::jsonb)
      		)) as arr
      	from
      		vs
      )

      -- Find the ones which have not 2 keys or not the expected properties.
      select
      	*
      from
      	arr
      where
      	json_array_length(arr) <> 2
      	or not (arr::jsonb @> '["label","value"]'::jsonb)
    )

  )

)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_values !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (

  not (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')

  or (
    (NEW.data::json->>'type') in ('radio', 'select', 'checkbox')

    and (

      with vs as (
        select jsonb_array_elements(NEW.data::jsonb->'values') as v
      )

      select
      (

        -- We need to wrap it otherwise count will not count null values.
        select count(*) from (
          select
              distinct v::json->>'value'
          from
              vs v
        ) as sub
      )

      =

      (
        -- We need to wrap it otherwise count will not count null values.
        select count(*) from (
          select
              v::json->>'value'
          from
              vs v
        ) as sub
      )

    )
  )

)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_distinct_values !!!!!'; RETURN NEW;
      END IF;

      IF (NEW.dynamic and not (
  -- Check default only for radio and select.
  (
    not (NEW.data::json->>'type') in ('radio', 'select')
    and NEW.data::json->'default' is null
  )
  or
  (
    (NEW.data::json->>'type') in ('radio', 'select')

    and

    (
      (NEW.data::json->'values' is null)
      and
      (NEW.data::json->'default' is null)

      or

      (NEW.data::json->'values' is not null)
      and
      (NEW.data::json->'default' is not null)
      and 1 = (

        with vs as (
          select jsonb_array_elements(NEW.data::jsonb->'values') as v
        )

        -- Check that there exists a value equal to the default value or both are null.
        select
          count(*)
        from
          vs v
        where
          (v::json->>'value') = (NEW.data::jsonb->>'default')
          or (v::json->>'value') is null and (NEW.data::jsonb->>'default') is null

      )
    )
  )
)
)
      THEN RAISE EXCEPTION '!!!!! CHECK TRIGGER check_default !!!!!'; RETURN NEW;
      END IF;



        IF (
          NEW.dynamic
          and not (

            (

              -- We do not check the values, if no item uses this field. Otherwise if the field is already used, existing values must not change.
              not EXISTS (
                SELECT 1
                FROM items
                WHERE items.properties::jsonb ? (NEW.data::json#>>'{attribute,1}')
              )

              -- If the values were null, the values will have to be null again.
              or (
                (NEW.data::json->'values') is null
                and
                (OLD.data::json->'values') is null
              )

              -- If there were values, we will need the same count of values again or more.
              -- The old values must be contained in the new values.
              or (
                json_array_length(NEW.data::json->'values') >= json_array_length(OLD.data::json->'values')
                and
                (select array_agg(v::jsonb->'value') from (select jsonb_array_elements(NEW.data::jsonb->'values') as v) as vs)
                @>
                (select array_agg(v::jsonb->'value') from (select jsonb_array_elements(OLD.data::jsonb->'values') as v) as vs)
              )

            )
          )
        )
        THEN
          RAISE EXCEPTION 'New field is not valid.';
          RETURN NEW;
        END IF;

        RETURN NEW;
      END;
      $$;


--
-- Name: groups_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.groups_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.name::text, '') || ' ' || COALESCE(NEW.org_id::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: hex_to_int(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.hex_to_int(hexval character varying) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
      DECLARE
        result bigint;
      BEGIN
        EXECUTE 'SELECT x''' || hexval || '''::bigint' INTO result;
        RETURN result;
      END;
      $$;


--
-- Name: increase_counter_for_new_procurement_request_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increase_counter_for_new_procurement_request_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE procurement_requests_counters
  SET counter = counter + 1
  WHERE id = (
    SELECT prc.id
    FROM procurement_requests_counters AS prc
    WHERE prc.prefix = (
      SELECT pbp.name
      FROM procurement_budget_periods AS pbp
      WHERE pbp.id = NEW.budget_period_id
    )
  );

  RETURN NULL;
END;
$$;


--
-- Name: insert_counter_for_new_procurement_budget_period_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_counter_for_new_procurement_budget_period_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT true
    FROM procurement_requests_counters
    WHERE prefix = NEW.name
  ) THEN
    INSERT INTO procurement_requests_counters(prefix, counter, created_by_budget_period_id)
    VALUES (NEW.name, 0, NEW.id);
  END IF;

  RETURN NULL;
END;
$$;


--
-- Name: jsonb_changed(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.jsonb_changed(jold jsonb, jnew jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  result JSONB := '{}'::JSONB;
  k TEXT;
  v_new JSONB;
  v_old JSONB;
BEGIN
  FOR k IN SELECT * FROM jsonb_object_keys(jold || jnew) LOOP
    if jnew ? k
      THEN v_new := jnew -> k;
      ELSE v_new := 'null'::JSONB; END IF;
    if jold ? k
      THEN v_old := jold -> k;
      ELSE v_old := 'null'::JSONB; END IF;
    IF k = 'updated_at' THEN CONTINUE; END IF;
    IF v_new = v_old THEN CONTINUE; END IF;
    result := result || jsonb_build_object(k, jsonb_build_array(v_old, v_new));
  END LOOP;
  RETURN result;
END;
$$;


--
-- Name: orders_insert_check_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.orders_insert_check_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.customer_order_id IS NULL) THEN
    RAISE EXCEPTION 'customer_order_id cannot be null for a new order.';
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: origin_table_agg_f(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.origin_table_agg_f(ot1 text, ot2 text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF ot1 IS NOT NULL AND ot2 IS NOT NULL THEN
    RETURN 'mixed';
  ELSIF ot1 IS NOT NULL THEN
    RETURN ot1;
  ELSE
    RETURN ot2 ;
  END IF;
END;
$$;


--
-- Name: populate_all_users_group_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.populate_all_users_group_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        INSERT INTO groups_users(group_id, user_id)
SELECT '4dd87663-f731-5766-b97d-9494889ca66c', id
FROM users
WHERE delegator_user_id IS NULL
ON CONFLICT DO NOTHING;

        RETURN NULL;
      END;
      $$;


--
-- Name: prevent_deleting_all_users_group_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_deleting_all_users_group_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF ( OLD.id = '4dd87663-f731-5766-b97d-9494889ca66c' )
  THEN
    RAISE EXCEPTION 'Deleting this specific group is not allowed.';
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: role_agg_f(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.role_agg_f(role1 text, role2 text) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: set_short_id_for_new_procurement_request_f(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_short_id_for_new_procurement_request_f() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.short_id = (
    SELECT tmp.prefix || '.' || CASE
                                             WHEN tmp.counter > 999 THEN tmp.counter::text
                                             ELSE lpad(tmp.counter::text, 3, '0')
                                           END
    FROM (
      SELECT prc.prefix, prc.counter + 1 AS counter
      FROM procurement_requests_counters AS prc
      JOIN procurement_budget_periods AS pbp ON prc.prefix = pbp.name
      WHERE pbp.id = NEW.budget_period_id
    ) AS tmp
  );

  RETURN NEW;
END;
$$;


--
-- Name: txid(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.txid() RETURNS uuid
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN uuid_generate_v5(uuid_nil(), current_date::TEXT || ' ' || txid_current()::TEXT);
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$;


--
-- Name: users_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.users_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.firstname::text, '') || ' ' || COALESCE(NEW.lastname::text, '') || ' ' || COALESCE(NEW.email::text, '') || ' ' || COALESCE(NEW.login::text, '') || ' ' || COALESCE(NEW.badge_id::text, '') || ' ' || COALESCE(NEW.org_id::text, '') || ' ' || COALESCE(NEW.lastname::text, '') || ' ' || COALESCE(NEW.firstname::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: ar_uuid_agg(uuid, uuid, uuid); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.ar_uuid_agg(uuid, uuid, uuid) (
    SFUNC = public.ar_uuid_agg_f,
    STYPE = uuid
);


--
-- Name: delegations_users_id_agg(uuid, uuid, uuid); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.delegations_users_id_agg(uuid, uuid, uuid) (
    SFUNC = public.delegations_users_id_agg_f,
    STYPE = uuid
);


--
-- Name: delegations_users_type_agg(text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.delegations_users_type_agg(text) (
    SFUNC = public.delegations_users_type_agg_f,
    STYPE = text
);


--
-- Name: entitlement_groups_users_id_agg(uuid, uuid, uuid); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.entitlement_groups_users_id_agg(uuid, uuid, uuid) (
    SFUNC = public.entitlement_groups_users_id_agg_f,
    STYPE = uuid
);


--
-- Name: entitlement_groups_users_type_agg(text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.entitlement_groups_users_type_agg(text) (
    SFUNC = public.entitlement_groups_users_type_agg_f,
    STYPE = text
);


--
-- Name: origin_table_agg(text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.origin_table_agg(text) (
    SFUNC = public.origin_table_agg_f,
    STYPE = text
);


--
-- Name: role_agg(text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.role_agg(text) (
    SFUNC = public.role_agg_f,
    STYPE = text
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: direct_access_rights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.direct_access_rights (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    inventory_pool_id uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    role character varying NOT NULL,
    CONSTRAINT check_allowed_roles CHECK (((role)::text = ANY ((ARRAY['customer'::character varying, 'group_manager'::character varying, 'lending_manager'::character varying, 'inventory_manager'::character varying])::text[])))
);


--
-- Name: group_access_rights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_access_rights (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    group_id uuid NOT NULL,
    inventory_pool_id uuid NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT check_allowed_roles CHECK ((role = ANY (ARRAY['customer'::text, 'group_manager'::text, 'lending_manager'::text, 'inventory_manager'::text])))
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text,
    org_id character varying,
    searchable text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    admin_protected boolean DEFAULT false NOT NULL,
    system_admin_protected boolean DEFAULT false NOT NULL,
    organization text DEFAULT 'local'::text NOT NULL,
    CONSTRAINT check_org_domain_like CHECK ((organization ~ '^[A-Za-z0-9]+[A-Za-z0-9.-]+[A-Za-z0-9]+$'::text)),
    CONSTRAINT groups_org_id_may_not_contain_at_sign CHECK (((org_id)::text !~~* '%@%'::text)),
    CONSTRAINT groups_protected_hierarchy CHECK ((NOT ((system_admin_protected = true) AND (admin_protected = false))))
);


--
-- Name: groups_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups_users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    group_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: unified_access_rights; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.unified_access_rights AS
 SELECT direct_access_rights.id,
    'direct_access_rights'::text AS origin_table,
    direct_access_rights.id AS direct_access_right_id,
    NULL::uuid AS group_access_right_id,
    direct_access_rights.user_id,
    direct_access_rights.inventory_pool_id,
    direct_access_rights.role,
    direct_access_rights.created_at,
    direct_access_rights.updated_at
   FROM public.direct_access_rights
UNION
 SELECT group_access_rights.id,
    'group_access_rights'::text AS origin_table,
    NULL::uuid AS direct_access_right_id,
    group_access_rights.id AS group_access_right_id,
    groups_users.user_id,
    group_access_rights.inventory_pool_id,
    group_access_rights.role,
    group_access_rights.created_at,
    group_access_rights.updated_at
   FROM ((public.group_access_rights
     JOIN public.groups ON ((groups.id = group_access_rights.group_id)))
     JOIN public.groups_users ON ((groups_users.group_id = groups.id)));


--
-- Name: access_rights; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.access_rights AS
 SELECT public.ar_uuid_agg(unified_access_rights.id, unified_access_rights.user_id, unified_access_rights.inventory_pool_id) AS id,
    public.origin_table_agg(unified_access_rights.origin_table) AS origin_table,
    unified_access_rights.inventory_pool_id,
    unified_access_rights.user_id,
    public.role_agg((unified_access_rights.role)::text) AS role
   FROM public.unified_access_rights
  GROUP BY unified_access_rights.inventory_pool_id, unified_access_rights.user_id;


--
-- Name: accessories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accessories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    model_id uuid,
    name character varying NOT NULL,
    quantity integer
);


--
-- Name: accessories_inventory_pools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accessories_inventory_pools (
    accessory_id uuid,
    inventory_pool_id uuid
);


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    street character varying,
    zip_code character varying,
    city character varying,
    country_code character varying,
    latitude double precision,
    longitude double precision
);


--
-- Name: api_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token_hash text NOT NULL,
    token_part character varying(5) NOT NULL,
    scope_read boolean DEFAULT true NOT NULL,
    scope_write boolean DEFAULT false NOT NULL,
    scope_admin_read boolean DEFAULT false NOT NULL,
    scope_admin_write boolean DEFAULT false NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '1 year'::interval) NOT NULL,
    scope_system_admin_read boolean DEFAULT false NOT NULL,
    scope_system_admin_write boolean DEFAULT false NOT NULL,
    CONSTRAINT sensible_scope_admin_read CHECK (((NOT scope_admin_read) OR (scope_admin_read AND scope_read))),
    CONSTRAINT sensible_scrope_admin_write CHECK (((NOT scope_admin_write) OR (scope_admin_write AND scope_admin_read))),
    CONSTRAINT sensible_scrope_write CHECK (((NOT scope_write) OR (scope_write AND scope_read)))
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    model_id uuid,
    content_type character varying NOT NULL,
    filename character varying NOT NULL,
    size integer NOT NULL,
    item_id uuid,
    content text NOT NULL,
    metadata json,
    CONSTRAINT check_model_id_or_item_id_not_null CHECK (((model_id IS NOT NULL) OR (item_id IS NOT NULL))),
    CONSTRAINT check_non_empty_content CHECK ((content !~ '^\s*$'::text)),
    CONSTRAINT check_non_empty_content_type CHECK (((content_type)::text !~ '^\s*$'::text)),
    CONSTRAINT check_non_empty_filename CHECK (((filename)::text !~ '^\s*$'::text)),
    CONSTRAINT check_size_greater_than_zero CHECK ((size > 0))
);


--
-- Name: audited_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audited_changes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    txid uuid DEFAULT public.txid() NOT NULL,
    tg_op text NOT NULL,
    table_name text NOT NULL,
    changed jsonb,
    created_at timestamp with time zone DEFAULT now(),
    pkey text
);


--
-- Name: audited_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audited_requests (
    txid uuid DEFAULT public.txid() NOT NULL,
    user_id uuid,
    path text,
    method text,
    created_at timestamp with time zone DEFAULT now(),
    http_uid text,
    CONSTRAINT check_absolute_path CHECK ((path ~ '^/.*$'::text))
);


--
-- Name: audited_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audited_responses (
    txid uuid NOT NULL,
    status integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audits (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    auditable_id uuid,
    auditable_type character varying,
    associated_id uuid,
    associated_type character varying,
    user_id uuid,
    user_type character varying,
    username character varying,
    action character varying,
    audited_changes text,
    version integer DEFAULT 0,
    comment character varying,
    remote_address character varying,
    request_uuid character varying,
    created_at timestamp without time zone
);


--
-- Name: authentication_systems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authentication_systems (
    id character varying NOT NULL,
    name character varying NOT NULL,
    description text,
    type character varying NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    internal_private_key text,
    internal_public_key text,
    external_public_key text,
    external_sign_in_url text,
    send_email boolean DEFAULT true NOT NULL,
    send_org_id boolean DEFAULT false NOT NULL,
    send_login boolean DEFAULT false NOT NULL,
    shortcut_sign_in_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    external_sign_out_url text,
    sign_up_email_match text,
    CONSTRAINT check_shortcut_sing_in CHECK (((shortcut_sign_in_enabled = false) OR ((type)::text = 'external'::text))),
    CONSTRAINT check_valid_type CHECK (((type)::text = ANY ((ARRAY['password'::character varying, 'external'::character varying])::text[]))),
    CONSTRAINT simple_id CHECK (((id)::text ~ '^[a-z][a-z0-9_-]*$'::text))
);


--
-- Name: authentication_systems_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authentication_systems_groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    group_id uuid NOT NULL,
    authentication_system_id character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: authentication_systems_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authentication_systems_users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    data text,
    authentication_system_id character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: buildings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.buildings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    code character varying
);


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contracts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    compact_id text NOT NULL,
    note text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    state text NOT NULL,
    user_id uuid NOT NULL,
    inventory_pool_id uuid NOT NULL,
    purpose text NOT NULL,
    CONSTRAINT check_valid_state CHECK ((state = ANY (ARRAY['open'::text, 'closed'::text])))
);


--
-- Name: customer_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_orders (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    purpose text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    title text NOT NULL,
    CONSTRAINT non_blank_purpose CHECK ((purpose !~ '^ *$'::text)),
    CONSTRAINT non_blank_title CHECK ((title !~ '^ *$'::text))
);


--
-- Name: delegations_direct_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delegations_direct_users (
    delegation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL
);


--
-- Name: delegations_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delegations_groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    group_id uuid NOT NULL,
    delegation_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: delegations_users_unified; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.delegations_users_unified AS
 SELECT delegations_direct_users.id,
    'direct_delegation'::text AS type,
    delegations_direct_users.user_id,
    delegations_direct_users.delegation_id
   FROM public.delegations_direct_users
UNION
 SELECT delegations_groups.id,
    'group_delegation'::text AS type,
    groups_users.user_id,
    delegations_groups.delegation_id
   FROM ((public.delegations_groups
     JOIN public.groups ON ((groups.id = delegations_groups.group_id)))
     JOIN public.groups_users ON ((groups_users.group_id = groups.id)));


--
-- Name: delegations_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.delegations_users AS
 SELECT public.delegations_users_id_agg(delegations_users_unified.id, delegations_users_unified.user_id, delegations_users_unified.delegation_id) AS id,
    public.delegations_users_type_agg(delegations_users_unified.type) AS type,
    delegations_users_unified.delegation_id,
    delegations_users_unified.user_id
   FROM public.delegations_users_unified
  GROUP BY delegations_users_unified.delegation_id, delegations_users_unified.user_id;


--
-- Name: disabled_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disabled_fields (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    field_id character varying NOT NULL,
    inventory_pool_id uuid NOT NULL
);


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emails (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    subject text NOT NULL,
    body text NOT NULL,
    from_address text NOT NULL,
    trials integer DEFAULT 0 NOT NULL,
    code integer,
    error text,
    message text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_code CHECK ((((trials = 0) AND (code IS NULL)) OR ((trials <> 0) AND (code IS NOT NULL)))),
    CONSTRAINT check_error CHECK ((((trials = 0) AND (error IS NULL)) OR ((trials <> 0) AND (code IS NOT NULL)))),
    CONSTRAINT check_message CHECK ((((trials = 0) AND (message IS NULL)) OR ((trials <> 0) AND (code IS NOT NULL))))
);


--
-- Name: entitlement_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entitlement_groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    inventory_pool_id uuid NOT NULL,
    is_verification_required boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: entitlement_groups_direct_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entitlement_groups_direct_users (
    user_id uuid,
    entitlement_group_id uuid,
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL
);


--
-- Name: entitlement_groups_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entitlement_groups_groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    group_id uuid NOT NULL,
    entitlement_group_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: entitlement_groups_users_unified; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.entitlement_groups_users_unified AS
 SELECT entitlement_groups_direct_users.id,
    'direct_entitlement'::text AS type,
    entitlement_groups_direct_users.user_id,
    entitlement_groups_direct_users.entitlement_group_id
   FROM public.entitlement_groups_direct_users
UNION
 SELECT entitlement_groups_groups.id,
    'group_entitlement'::text AS type,
    groups_users.user_id,
    entitlement_groups_groups.entitlement_group_id
   FROM ((public.entitlement_groups_groups
     JOIN public.groups ON ((groups.id = entitlement_groups_groups.group_id)))
     JOIN public.groups_users ON ((groups_users.group_id = groups.id)));


--
-- Name: entitlement_groups_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.entitlement_groups_users AS
 SELECT public.entitlement_groups_users_id_agg(entitlement_groups_users_unified.id, entitlement_groups_users_unified.user_id, entitlement_groups_users_unified.entitlement_group_id) AS id,
    public.entitlement_groups_users_type_agg(entitlement_groups_users_unified.type) AS type,
    entitlement_groups_users_unified.entitlement_group_id,
    entitlement_groups_users_unified.user_id
   FROM public.entitlement_groups_users_unified
  GROUP BY entitlement_groups_users_unified.entitlement_group_id, entitlement_groups_users_unified.user_id;


--
-- Name: entitlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entitlements (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    model_id uuid NOT NULL,
    entitlement_group_id uuid NOT NULL,
    quantity integer NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: favorite_models; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorite_models (
    user_id uuid NOT NULL,
    model_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fields (
    id character varying(50) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "position" integer NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    dynamic boolean DEFAULT false NOT NULL
);


--
-- Name: hidden_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hidden_fields (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    field_id character varying,
    user_id uuid
);


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holidays (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inventory_pool_id uuid,
    start_date date,
    end_date date,
    name character varying
);


--
-- Name: images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.images (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    target_id uuid,
    target_type character varying,
    content_type character varying,
    filename character varying,
    size integer,
    parent_id uuid,
    content text,
    thumbnail boolean DEFAULT false,
    metadata json
);


--
-- Name: inventory_pools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_pools (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text,
    contact_details character varying,
    contract_description character varying,
    contract_url character varying,
    logo_url character varying,
    default_contract_note text,
    shortname character varying NOT NULL,
    email character varying NOT NULL,
    color text,
    print_contracts boolean DEFAULT true,
    opening_hours text,
    address_id uuid,
    automatic_suspension boolean DEFAULT false NOT NULL,
    automatic_suspension_reason text,
    required_purpose boolean DEFAULT true,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: inventory_pools_model_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_pools_model_groups (
    inventory_pool_id uuid,
    model_group_id uuid
);


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inventory_code character varying NOT NULL,
    serial_number character varying,
    model_id uuid NOT NULL,
    supplier_id uuid,
    owner_id uuid NOT NULL,
    inventory_pool_id uuid NOT NULL,
    parent_id uuid,
    invoice_number character varying,
    invoice_date date,
    last_check date,
    retired date,
    retired_reason character varying,
    price numeric(8,2),
    is_broken boolean DEFAULT false,
    is_incomplete boolean DEFAULT false,
    is_borrowable boolean DEFAULT false,
    status_note text,
    needs_permission boolean DEFAULT false,
    is_inventory_relevant boolean DEFAULT false,
    responsible character varying,
    insurance_number character varying,
    note text,
    name text,
    user_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    shelf text,
    room_id uuid NOT NULL,
    properties jsonb DEFAULT '{}'::jsonb,
    item_version character varying
);


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.languages (
    name character varying,
    locale character varying NOT NULL,
    "default" boolean,
    active boolean
);


--
-- Name: mail_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mail_templates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inventory_pool_id uuid,
    name character varying NOT NULL,
    format character varying NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_template_template boolean NOT NULL,
    type text NOT NULL,
    language_locale text NOT NULL,
    CONSTRAINT mail_templates_check CHECK ((((inventory_pool_id IS NULL) AND (is_template_template IS TRUE)) OR ((inventory_pool_id IS NOT NULL) AND (is_template_template IS FALSE))))
);


--
-- Name: model_group_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.model_group_links (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    parent_id uuid,
    child_id uuid,
    label character varying
);


--
-- Name: model_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.model_groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    type character varying,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: model_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.model_links (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    model_group_id uuid NOT NULL,
    model_id uuid NOT NULL,
    quantity integer DEFAULT 1 NOT NULL
);


--
-- Name: models; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.models (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    type character varying DEFAULT 'Model'::character varying NOT NULL,
    manufacturer character varying,
    product character varying NOT NULL,
    version character varying,
    description text,
    internal_description text,
    info_url character varying,
    rental_price numeric(8,2),
    maintenance_period integer DEFAULT 0,
    is_package boolean DEFAULT false,
    technical_detail text,
    hand_over_note text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cover_image_id uuid
);


--
-- Name: models_compatibles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.models_compatibles (
    model_id uuid,
    compatible_id uuid
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    title character varying DEFAULT ''::character varying,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: numerators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.numerators (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    item integer
);


--
-- Name: old_empty_contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.old_empty_contracts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    compact_id text NOT NULL,
    note text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.options (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inventory_pool_id uuid NOT NULL,
    inventory_code character varying DEFAULT (public.uuid_generate_v4())::text NOT NULL,
    manufacturer character varying,
    product character varying NOT NULL,
    version character varying,
    price numeric(8,2)
);


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    inventory_pool_id uuid NOT NULL,
    purpose text,
    state text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reject_reason character varying,
    customer_order_id uuid NOT NULL,
    CONSTRAINT check_state_and_reject_reason_consistency CHECK ((((state = ANY (ARRAY['submitted'::text, 'approved'::text, 'rejected'::text])) AND (reject_reason IS NULL)) OR ((state = 'rejected'::text) AND (reject_reason IS NOT NULL)))),
    CONSTRAINT check_valid_state CHECK ((state = ANY (ARRAY['submitted'::text, 'approved'::text, 'rejected'::text])))
);


--
-- Name: procurement_admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_admins (
    user_id uuid NOT NULL
);


--
-- Name: procurement_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_attachments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    request_id uuid,
    filename character varying,
    content_type character varying,
    size integer,
    content text,
    metadata json,
    exiftool_version character varying,
    exiftool_options character varying
);


--
-- Name: procurement_budget_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_budget_limits (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    budget_period_id uuid NOT NULL,
    main_category_id uuid NOT NULL,
    amount_cents integer DEFAULT 0 NOT NULL,
    amount_currency character varying DEFAULT 'USD'::character varying NOT NULL
);


--
-- Name: procurement_budget_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_budget_periods (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    inspection_start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT procurement_budget_periods_name CHECK (((name)::text ~* '^[-_a-zA-Z0-9]+$'::text))
);


--
-- Name: procurement_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    main_category_id uuid,
    general_ledger_account character varying,
    cost_center character varying,
    procurement_account character varying,
    CONSTRAINT name_is_not_blank CHECK (((name)::text !~ '^\s*$'::text))
);


--
-- Name: procurement_category_inspectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_category_inspectors (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    category_id uuid NOT NULL
);


--
-- Name: procurement_category_viewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_category_viewers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    category_id uuid NOT NULL
);


--
-- Name: procurement_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_images (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    main_category_id uuid NOT NULL,
    content_type character varying NOT NULL,
    content character varying NOT NULL,
    filename character varying NOT NULL,
    size integer,
    metadata json,
    exiftool_version character varying,
    exiftool_options character varying
);


--
-- Name: procurement_main_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_main_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    CONSTRAINT name_is_not_blank CHECK (((name)::text !~ '^\s*$'::text))
);


--
-- Name: procurement_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_organizations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    shortname character varying,
    parent_id uuid
);


--
-- Name: procurement_requesters_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_requesters_organizations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid NOT NULL
);


--
-- Name: procurement_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    budget_period_id uuid NOT NULL,
    category_id uuid NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    model_id uuid,
    supplier_id uuid,
    template_id uuid,
    article_name text,
    article_number character varying,
    requested_quantity integer NOT NULL,
    approved_quantity integer,
    order_quantity integer,
    price_cents bigint DEFAULT 0 NOT NULL,
    price_currency character varying DEFAULT 'USD'::character varying NOT NULL,
    priority character varying DEFAULT 'normal'::character varying NOT NULL,
    replacement boolean DEFAULT true NOT NULL,
    supplier_name character varying,
    receiver character varying,
    motivation character varying NOT NULL,
    inspection_comment character varying,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    inspector_priority character varying DEFAULT 'medium'::character varying NOT NULL,
    room_id uuid NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    accounting_type character varying DEFAULT 'aquisition'::character varying NOT NULL,
    internal_order_number character varying,
    short_id text,
    CONSTRAINT article_name_is_not_blank CHECK ((article_name !~ '^\s*$'::text)),
    CONSTRAINT check_allowed_priorities CHECK (((priority)::text = ANY ((ARRAY['normal'::character varying, 'high'::character varying])::text[]))),
    CONSTRAINT check_either_model_id_or_article_name CHECK ((((model_id IS NOT NULL) AND (article_name IS NULL)) OR ((model_id IS NULL) AND (article_name IS NOT NULL)))),
    CONSTRAINT check_either_supplier_id_or_supplier_name CHECK ((((supplier_id IS NOT NULL) AND (supplier_name IS NULL)) OR ((supplier_id IS NULL) AND (supplier_name IS NOT NULL)) OR ((supplier_id IS NULL) AND (supplier_name IS NULL)))),
    CONSTRAINT check_inspector_priority CHECK (((inspector_priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'mandatory'::character varying])::text[]))),
    CONSTRAINT check_internal_order_number_if_type_investment CHECK ((NOT (((accounting_type)::text = 'investment'::text) AND (internal_order_number IS NULL)))),
    CONSTRAINT check_max_javascript_int CHECK (((price_cents)::double precision < ((2)::double precision ^ (52)::double precision))),
    CONSTRAINT check_valid_accounting_type CHECK (((accounting_type)::text = ANY ((ARRAY['aquisition'::character varying, 'investment'::character varying])::text[]))),
    CONSTRAINT supplier_name_is_not_blank CHECK (((supplier_name)::text !~ '^\s*$'::text))
);


--
-- Name: procurement_requests_counters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_requests_counters (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    prefix text NOT NULL,
    counter integer DEFAULT 0 NOT NULL,
    created_by_budget_period_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: procurement_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_settings (
    id integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    contact_url character varying,
    inspection_comments jsonb DEFAULT '[]'::jsonb,
    CONSTRAINT oneandonly CHECK ((id = 0))
);


--
-- Name: procurement_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_templates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    model_id uuid,
    supplier_id uuid,
    article_name text,
    article_number character varying,
    price_cents integer DEFAULT 0 NOT NULL,
    price_currency character varying DEFAULT 'USD'::character varying NOT NULL,
    supplier_name character varying,
    category_id uuid NOT NULL,
    CONSTRAINT article_name_is_not_blank CHECK ((article_name !~ '^\s*$'::text)),
    CONSTRAINT check_either_model_id_or_article_name CHECK ((((model_id IS NOT NULL) AND (article_name IS NULL)) OR ((model_id IS NULL) AND (article_name IS NOT NULL)))),
    CONSTRAINT check_either_supplier_id_or_supplier_name CHECK ((((supplier_id IS NOT NULL) AND (supplier_name IS NULL)) OR ((supplier_id IS NULL) AND (supplier_name IS NOT NULL)) OR ((supplier_id IS NULL) AND (supplier_name IS NULL)))),
    CONSTRAINT supplier_name_is_not_blank CHECK (((supplier_name)::text !~ '^\s*$'::text))
);


--
-- Name: procurement_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_uploads (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    size integer NOT NULL,
    content text NOT NULL,
    metadata json NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    exiftool_version character varying,
    exiftool_options character varying
);


--
-- Name: procurement_users_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_users_filters (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    filter json NOT NULL
);


--
-- Name: properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    model_id uuid,
    key character varying NOT NULL,
    value character varying NOT NULL
);


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    contract_id uuid,
    inventory_pool_id uuid NOT NULL,
    user_id uuid NOT NULL,
    delegated_user_id uuid,
    handed_over_by_user_id uuid,
    type character varying DEFAULT 'ItemLine'::character varying NOT NULL,
    status text NOT NULL,
    item_id uuid,
    model_id uuid,
    quantity integer DEFAULT 1,
    start_date date,
    end_date date,
    returned_date date,
    option_id uuid,
    returned_to_user_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    order_id uuid,
    line_purpose text,
    CONSTRAINT check_allowed_statuses CHECK ((status = ANY (ARRAY['draft'::text, 'unsubmitted'::text, 'submitted'::text, 'rejected'::text, 'approved'::text, 'signed'::text, 'closed'::text]))),
    CONSTRAINT check_order_id_for_different_statuses_of_item_line CHECK (((((type)::text = 'ItemLine'::text) AND (((status = ANY (ARRAY['draft'::text, 'unsubmitted'::text])) AND (order_id IS NULL)) OR ((status = ANY (ARRAY['submitted'::text, 'rejected'::text])) AND (order_id IS NOT NULL)) OR (status = ANY (ARRAY['approved'::text, 'signed'::text, 'closed'::text])))) OR (((type)::text = 'OptionLine'::text) AND (status = ANY (ARRAY['approved'::text, 'signed'::text, 'closed'::text]))))),
    CONSTRAINT check_valid_status_and_contract_id CHECK ((((status = ANY (ARRAY['draft'::text, 'unsubmitted'::text, 'submitted'::text, 'approved'::text, 'rejected'::text])) AND (contract_id IS NULL)) OR ((status = ANY (ARRAY['signed'::text, 'closed'::text])) AND (contract_id IS NOT NULL))))
);


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text,
    building_id uuid NOT NULL,
    general boolean DEFAULT false NOT NULL,
    CONSTRAINT check_non_empty_name CHECK (((name)::text !~ '^\s*$'::text))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    local_currency_string character varying,
    contract_lending_party_string text,
    email_signature character varying,
    deliver_received_order_notifications boolean,
    user_image_url character varying,
    ldap_config character varying,
    logo_url character varying,
    time_zone character varying DEFAULT 'Bern'::character varying NOT NULL,
    disable_manage_section boolean DEFAULT false NOT NULL,
    disable_manage_section_message text,
    disable_borrow_section boolean DEFAULT false NOT NULL,
    disable_borrow_section_message text,
    text text,
    timeout_minutes integer DEFAULT 30 NOT NULL,
    custom_head_tag text,
    documentation_link character varying DEFAULT ''::character varying,
    id integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    maximum_reservation_time integer,
    CONSTRAINT id_is_zero CHECK ((id = 0))
);


--
-- Name: smtp_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.smtp_settings (
    id integer DEFAULT 0 NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    address text,
    authentication_type text DEFAULT 'plain'::text,
    default_from_address text DEFAULT 'noreply'::text NOT NULL,
    domain text,
    enable_starttls_auto boolean DEFAULT false NOT NULL,
    openssl_verify_mode text DEFAULT 'none'::text NOT NULL,
    password text,
    port integer,
    sender_address text,
    username text,
    CONSTRAINT id_is_zero CHECK ((id = 0))
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    note text DEFAULT ''::text
);


--
-- Name: suspensions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suspensions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    inventory_pool_id uuid,
    suspended_until date DEFAULT (now() + '10000 years'::interval) NOT NULL,
    suspended_reason text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: system_and_security_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_and_security_settings (
    id integer DEFAULT 0 NOT NULL,
    accept_server_secret_as_universal_password boolean DEFAULT true NOT NULL,
    external_base_url character varying,
    sessions_force_secure boolean DEFAULT false NOT NULL,
    sessions_force_uniqueness boolean DEFAULT false NOT NULL,
    sessions_max_lifetime_secs integer DEFAULT 432000,
    CONSTRAINT id_is_zero CHECK ((id = 0))
);


--
-- Name: user_password_resets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_password_resets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    used_user_param text NOT NULL,
    token text NOT NULL,
    valid_until timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    token_hash text NOT NULL,
    user_id uuid,
    delegation_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    meta_data jsonb,
    authentication_system_id text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    login character varying,
    firstname text,
    lastname character varying,
    phone character varying,
    org_id character varying,
    email character varying,
    badge_id character varying,
    address character varying,
    city character varying,
    zip character varying,
    country character varying,
    settings character varying(1024),
    delegator_user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    account_enabled boolean DEFAULT true NOT NULL,
    password_sign_in_enabled boolean DEFAULT true NOT NULL,
    url character varying,
    img256_url character varying(100000),
    img32_url character varying(10000),
    img_digest text,
    is_admin boolean DEFAULT false NOT NULL,
    extended_info jsonb,
    searchable text DEFAULT ''::text NOT NULL,
    secondary_email text,
    language_locale text,
    admin_protected boolean DEFAULT false NOT NULL,
    is_system_admin boolean DEFAULT false NOT NULL,
    pool_protected boolean DEFAULT false NOT NULL,
    system_admin_protected boolean DEFAULT false NOT NULL,
    organization text DEFAULT 'local'::text NOT NULL,
    CONSTRAINT check_org_domain_like CHECK ((organization ~ '^[A-Za-z0-9]+[A-Za-z0-9.-]+[A-Za-z0-9]+$'::text)),
    CONSTRAINT email_must_contain_at_sign CHECK (((email)::text ~~* '%@%'::text)),
    CONSTRAINT login_is_simple CHECK (((login)::text ~ '^[a-z0-9]+$'::text)),
    CONSTRAINT users_admin_hierarchy CHECK ((NOT ((is_system_admin = true) AND (is_admin = false)))),
    CONSTRAINT users_org_id_may_not_contain_at_sign CHECK (((org_id)::text !~~* '%@%'::text)),
    CONSTRAINT users_protected_hierarchy CHECK ((NOT ((system_admin_protected = true) AND (admin_protected = false))))
);


--
-- Name: visits; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.visits AS
 SELECT public.uuid_generate_v5(public.uuid_ns_dns(), concat_ws('_'::text, visit_reservations.user_id, visit_reservations.inventory_pool_id, visit_reservations.status, visit_reservations.date)) AS id,
    visit_reservations.user_id,
    visit_reservations.inventory_pool_id,
    visit_reservations.date,
    visit_reservations.visit_type AS type,
        CASE
            WHEN (visit_reservations.status = 'submitted'::text) THEN false
            WHEN (visit_reservations.status = ANY (ARRAY['approved'::text, 'signed'::text])) THEN true
            ELSE NULL::boolean
        END AS is_approved,
    sum(visit_reservations.quantity) AS quantity,
    bool_or(visit_reservations.with_user_to_verify) AS with_user_to_verify,
    bool_or(visit_reservations.with_user_and_model_to_verify) AS with_user_and_model_to_verify,
    array_agg(visit_reservations.id) AS reservation_ids
   FROM ( SELECT reservations.id,
            reservations.user_id,
            reservations.inventory_pool_id,
                CASE
                    WHEN (reservations.status = ANY (ARRAY['submitted'::text, 'approved'::text])) THEN reservations.start_date
                    WHEN (reservations.status = 'signed'::text) THEN reservations.end_date
                    ELSE NULL::date
                END AS date,
                CASE
                    WHEN (reservations.status = ANY (ARRAY['submitted'::text, 'approved'::text])) THEN 'hand_over'::text
                    WHEN (reservations.status = 'signed'::text) THEN 'take_back'::text
                    ELSE NULL::text
                END AS visit_type,
            reservations.status,
            reservations.quantity,
            (EXISTS ( SELECT 1
                   FROM (public.entitlement_groups_direct_users
                     JOIN public.entitlement_groups ON ((entitlement_groups.id = entitlement_groups_direct_users.entitlement_group_id)))
                  WHERE ((entitlement_groups_direct_users.user_id = reservations.user_id) AND (entitlement_groups.is_verification_required IS TRUE)))) AS with_user_to_verify,
            (EXISTS ( SELECT 1
                   FROM ((public.entitlements
                     JOIN public.entitlement_groups ON ((entitlement_groups.id = entitlements.entitlement_group_id)))
                     JOIN public.entitlement_groups_direct_users ON ((entitlement_groups_direct_users.entitlement_group_id = entitlement_groups.id)))
                  WHERE ((entitlements.model_id = reservations.model_id) AND (entitlement_groups_direct_users.user_id = reservations.user_id) AND (entitlement_groups.is_verification_required IS TRUE)))) AS with_user_and_model_to_verify
           FROM public.reservations
          WHERE (reservations.status = ANY (ARRAY['submitted'::text, 'approved'::text, 'signed'::text]))) visit_reservations
  GROUP BY visit_reservations.user_id, visit_reservations.inventory_pool_id, visit_reservations.date, visit_reservations.visit_type, visit_reservations.status;


--
-- Name: workdays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workdays (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inventory_pool_id uuid NOT NULL,
    monday boolean DEFAULT true NOT NULL,
    tuesday boolean DEFAULT true NOT NULL,
    wednesday boolean DEFAULT true NOT NULL,
    thursday boolean DEFAULT true NOT NULL,
    friday boolean DEFAULT true NOT NULL,
    saturday boolean DEFAULT false NOT NULL,
    sunday boolean DEFAULT false NOT NULL,
    reservation_advance_days integer DEFAULT 0 NOT NULL,
    max_visits jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: direct_access_rights access_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_access_rights
    ADD CONSTRAINT access_rights_pkey PRIMARY KEY (id);


--
-- Name: accessories accessories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accessories
    ADD CONSTRAINT accessories_pkey PRIMARY KEY (id);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: audited_changes audited_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audited_changes
    ADD CONSTRAINT audited_changes_pkey PRIMARY KEY (id);


--
-- Name: audited_requests audited_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audited_requests
    ADD CONSTRAINT audited_requests_pkey PRIMARY KEY (txid);


--
-- Name: audited_responses audited_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audited_responses
    ADD CONSTRAINT audited_responses_pkey PRIMARY KEY (txid);


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: authentication_systems_groups authentication_systems_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems_groups
    ADD CONSTRAINT authentication_systems_groups_pkey PRIMARY KEY (id);


--
-- Name: authentication_systems authentication_systems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems
    ADD CONSTRAINT authentication_systems_pkey PRIMARY KEY (id);


--
-- Name: authentication_systems_users authentication_systems_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems_users
    ADD CONSTRAINT authentication_systems_users_pkey PRIMARY KEY (id);


--
-- Name: buildings buildings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.buildings
    ADD CONSTRAINT buildings_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: customer_orders customer_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_orders
    ADD CONSTRAINT customer_orders_pkey PRIMARY KEY (id);


--
-- Name: delegations_direct_users delegations_direct_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_direct_users
    ADD CONSTRAINT delegations_direct_users_pkey PRIMARY KEY (id);


--
-- Name: delegations_groups delegations_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_groups
    ADD CONSTRAINT delegations_groups_pkey PRIMARY KEY (id);


--
-- Name: disabled_fields disabled_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_fields
    ADD CONSTRAINT disabled_fields_pkey PRIMARY KEY (id);


--
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: entitlement_groups_direct_users entitlement_groups_direct_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_direct_users
    ADD CONSTRAINT entitlement_groups_direct_users_pkey PRIMARY KEY (id);


--
-- Name: entitlement_groups_groups entitlement_groups_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_groups
    ADD CONSTRAINT entitlement_groups_groups_pkey PRIMARY KEY (id);


--
-- Name: fields fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (id);


--
-- Name: group_access_rights group_access_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_access_rights
    ADD CONSTRAINT group_access_rights_pkey PRIMARY KEY (id);


--
-- Name: entitlement_groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey1 PRIMARY KEY (id);


--
-- Name: groups_users groups_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT groups_users_pkey PRIMARY KEY (id);


--
-- Name: hidden_fields hidden_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hidden_fields
    ADD CONSTRAINT hidden_fields_pkey PRIMARY KEY (id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: inventory_pools inventory_pools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_pools
    ADD CONSTRAINT inventory_pools_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (locale);


--
-- Name: mail_templates mail_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_templates
    ADD CONSTRAINT mail_templates_pkey PRIMARY KEY (id);


--
-- Name: model_group_links model_group_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_group_links
    ADD CONSTRAINT model_group_links_pkey PRIMARY KEY (id);


--
-- Name: model_groups model_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_groups
    ADD CONSTRAINT model_groups_pkey PRIMARY KEY (id);


--
-- Name: model_links model_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_links
    ADD CONSTRAINT model_links_pkey PRIMARY KEY (id);


--
-- Name: models models_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models
    ADD CONSTRAINT models_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: numerators numerators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.numerators
    ADD CONSTRAINT numerators_pkey PRIMARY KEY (id);


--
-- Name: old_empty_contracts old_empty_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.old_empty_contracts
    ADD CONSTRAINT old_empty_contracts_pkey PRIMARY KEY (id);


--
-- Name: options options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: entitlements partitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT partitions_pkey PRIMARY KEY (id);


--
-- Name: procurement_requesters_organizations procurement_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requesters_organizations
    ADD CONSTRAINT procurement_accesses_pkey PRIMARY KEY (id);


--
-- Name: procurement_attachments procurement_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_attachments
    ADD CONSTRAINT procurement_attachments_pkey PRIMARY KEY (id);


--
-- Name: procurement_budget_limits procurement_budget_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_budget_limits
    ADD CONSTRAINT procurement_budget_limits_pkey PRIMARY KEY (id);


--
-- Name: procurement_budget_periods procurement_budget_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_budget_periods
    ADD CONSTRAINT procurement_budget_periods_pkey PRIMARY KEY (id);


--
-- Name: procurement_categories procurement_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_categories
    ADD CONSTRAINT procurement_categories_pkey PRIMARY KEY (id);


--
-- Name: procurement_category_inspectors procurement_category_inspectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_category_inspectors
    ADD CONSTRAINT procurement_category_inspectors_pkey PRIMARY KEY (id);


--
-- Name: procurement_category_viewers procurement_category_viewers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_category_viewers
    ADD CONSTRAINT procurement_category_viewers_pkey PRIMARY KEY (id);


--
-- Name: procurement_images procurement_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_images
    ADD CONSTRAINT procurement_images_pkey PRIMARY KEY (id);


--
-- Name: procurement_main_categories procurement_main_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_main_categories
    ADD CONSTRAINT procurement_main_categories_pkey PRIMARY KEY (id);


--
-- Name: procurement_organizations procurement_organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_organizations
    ADD CONSTRAINT procurement_organizations_pkey PRIMARY KEY (id);


--
-- Name: procurement_requests_counters procurement_requests_counters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests_counters
    ADD CONSTRAINT procurement_requests_counters_pkey PRIMARY KEY (id);


--
-- Name: procurement_requests procurement_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT procurement_requests_pkey PRIMARY KEY (id);


--
-- Name: procurement_settings procurement_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_settings
    ADD CONSTRAINT procurement_settings_pkey PRIMARY KEY (id);


--
-- Name: procurement_templates procurement_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_templates
    ADD CONSTRAINT procurement_templates_pkey PRIMARY KEY (id);


--
-- Name: procurement_uploads procurement_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_uploads
    ADD CONSTRAINT procurement_uploads_pkey PRIMARY KEY (id);


--
-- Name: procurement_users_filters procurement_users_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_users_filters
    ADD CONSTRAINT procurement_users_filters_pkey PRIMARY KEY (id);


--
-- Name: properties properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: smtp_settings smtp_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smtp_settings
    ADD CONSTRAINT smtp_settings_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: suspensions suspensions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suspensions
    ADD CONSTRAINT suspensions_pkey PRIMARY KEY (id);


--
-- Name: system_and_security_settings system_and_security_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_and_security_settings
    ADD CONSTRAINT system_and_security_settings_pkey PRIMARY KEY (id);


--
-- Name: user_password_resets user_password_resets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_password_resets
    ADD CONSTRAINT user_password_resets_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: workdays workdays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workdays
    ADD CONSTRAINT workdays_pkey PRIMARY KEY (id);


--
-- Name: associated_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX associated_index ON public.audits USING btree (associated_id, associated_type);


--
-- Name: auditable_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditable_index ON public.audits USING btree (auditable_id, auditable_type);


--
-- Name: audited_changes_changed_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_changes_changed_idx ON public.audited_changes USING gin (to_tsvector('english'::regconfig, changed));


--
-- Name: audited_changes_table_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_changes_table_name ON public.audited_changes USING btree (table_name);


--
-- Name: audited_changes_tg_op; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_changes_tg_op ON public.audited_changes USING btree (tg_op);


--
-- Name: audited_changes_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_changes_txid ON public.audited_changes USING btree (txid);


--
-- Name: audited_requests_method; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_requests_method ON public.audited_requests USING btree (method);


--
-- Name: audited_requests_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_requests_txid ON public.audited_requests USING btree (txid);


--
-- Name: audited_requests_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_requests_url ON public.audited_requests USING btree (path);


--
-- Name: audited_requests_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_requests_user_id ON public.audited_requests USING btree (user_id);


--
-- Name: audited_responses_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audited_responses_txid ON public.audited_responses USING btree (txid);


--
-- Name: case_insensitive_inventory_code_for_items; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX case_insensitive_inventory_code_for_items ON public.items USING btree (lower((inventory_code)::text));


--
-- Name: case_insensitive_inventory_code_for_options; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX case_insensitive_inventory_code_for_options ON public.options USING btree (lower((inventory_code)::text));


--
-- Name: delegations_groups_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX delegations_groups_idx ON public.delegations_groups USING btree (delegation_id, group_id);


--
-- Name: entitlement_groups_groups_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX entitlement_groups_groups_idx ON public.entitlement_groups_groups USING btree (entitlement_group_id, group_id);


--
-- Name: groups_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_searchable_idx ON public.groups USING gin (searchable public.gin_trgm_ops);


--
-- Name: groups_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_to_tsvector_idx ON public.groups USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: idx_auth_sys_groups; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_auth_sys_groups ON public.authentication_systems_groups USING btree (group_id, authentication_system_id);


--
-- Name: idx_auth_sys_users; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_auth_sys_users ON public.authentication_systems_users USING btree (user_id, authentication_system_id);


--
-- Name: idx_group_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_group_name ON public.groups USING btree (lower((name)::text));


--
-- Name: idx_groups_organization_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_groups_organization_org_id ON public.groups USING btree ((((organization || '_'::text) || (org_id)::text)));


--
-- Name: idx_procurement_category_viewers_uc; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_procurement_category_viewers_uc ON public.procurement_category_viewers USING btree (user_id, category_id);


--
-- Name: idx_procurement_group_inspectors_uc; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_procurement_group_inspectors_uc ON public.procurement_category_inspectors USING btree (user_id, category_id);


--
-- Name: idx_user_egroup; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_user_egroup ON public.entitlement_groups_direct_users USING btree (user_id, entitlement_group_id);


--
-- Name: idx_users_organization_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_users_organization_org_id ON public.users USING btree ((((organization || '_'::text) || (org_id)::text)));


--
-- Name: index_access_rights_on_pool_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_access_rights_on_pool_id_and_user_id ON public.direct_access_rights USING btree (inventory_pool_id, user_id);


--
-- Name: index_accessories_inventory_pools; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accessories_inventory_pools ON public.accessories_inventory_pools USING btree (accessory_id, inventory_pool_id);


--
-- Name: index_accessories_inventory_pools_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accessories_inventory_pools_on_inventory_pool_id ON public.accessories_inventory_pools USING btree (inventory_pool_id);


--
-- Name: index_accessories_on_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accessories_on_model_id ON public.accessories USING btree (model_id);


--
-- Name: index_addresses_szcc; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_addresses_szcc ON public.addresses USING btree (street, zip_code, city, country_code);


--
-- Name: index_attachments_on_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_model_id ON public.attachments USING btree (model_id);


--
-- Name: index_audited_changes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audited_changes_on_created_at ON public.audited_changes USING btree (created_at);


--
-- Name: index_audited_requests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audited_requests_on_created_at ON public.audited_requests USING btree (created_at);


--
-- Name: index_audited_responses_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audited_responses_on_created_at ON public.audited_responses USING btree (created_at);


--
-- Name: index_audited_responses_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audited_responses_on_status ON public.audited_responses USING btree (status);


--
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_created_at ON public.audits USING btree (created_at);


--
-- Name: index_audits_on_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_request_uuid ON public.audits USING btree (request_uuid);


--
-- Name: index_authentication_systems_groups_on_authentication_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentication_systems_groups_on_authentication_system_id ON public.authentication_systems_groups USING btree (authentication_system_id);


--
-- Name: index_authentication_systems_groups_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentication_systems_groups_on_group_id ON public.authentication_systems_groups USING btree (group_id);


--
-- Name: index_authentication_systems_users_on_authentication_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentication_systems_users_on_authentication_system_id ON public.authentication_systems_users USING btree (authentication_system_id);


--
-- Name: index_authentication_systems_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentication_systems_users_on_user_id ON public.authentication_systems_users USING btree (user_id);


--
-- Name: index_contracts_on_compact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contracts_on_compact_id ON public.contracts USING btree (compact_id);


--
-- Name: index_contracts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_created_at ON public.contracts USING btree (created_at);


--
-- Name: index_contracts_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_inventory_pool_id ON public.contracts USING btree (inventory_pool_id);


--
-- Name: index_contracts_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_state ON public.contracts USING btree (state);


--
-- Name: index_contracts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_user_id ON public.contracts USING btree (user_id);


--
-- Name: index_delegations_groups_on_delegation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delegations_groups_on_delegation_id ON public.delegations_groups USING btree (delegation_id);


--
-- Name: index_delegations_groups_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delegations_groups_on_group_id ON public.delegations_groups USING btree (group_id);


--
-- Name: index_delegations_users_on_delegation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delegations_users_on_delegation_id ON public.delegations_direct_users USING btree (delegation_id);


--
-- Name: index_delegations_users_on_user_id_and_delegation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_delegations_users_on_user_id_and_delegation_id ON public.delegations_direct_users USING btree (user_id, delegation_id);


--
-- Name: index_direct_access_rights_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_direct_access_rights_on_inventory_pool_id ON public.direct_access_rights USING btree (inventory_pool_id);


--
-- Name: index_direct_access_rights_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_direct_access_rights_on_role ON public.direct_access_rights USING btree (role);


--
-- Name: index_disabled_fields_on_field_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disabled_fields_on_field_id ON public.disabled_fields USING btree (field_id);


--
-- Name: index_disabled_fields_on_field_id_and_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_disabled_fields_on_field_id_and_inventory_pool_id ON public.disabled_fields USING btree (field_id, inventory_pool_id);


--
-- Name: index_disabled_fields_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disabled_fields_on_inventory_pool_id ON public.disabled_fields USING btree (inventory_pool_id);


--
-- Name: index_entitlement_groups_groups_on_entitlement_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlement_groups_groups_on_entitlement_group_id ON public.entitlement_groups_groups USING btree (entitlement_group_id);


--
-- Name: index_entitlement_groups_groups_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlement_groups_groups_on_group_id ON public.entitlement_groups_groups USING btree (group_id);


--
-- Name: index_entitlement_groups_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlement_groups_on_inventory_pool_id ON public.entitlement_groups USING btree (inventory_pool_id);


--
-- Name: index_entitlement_groups_on_is_verification_required; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlement_groups_on_is_verification_required ON public.entitlement_groups USING btree (is_verification_required);


--
-- Name: index_entitlement_groups_users_on_entitlement_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlement_groups_users_on_entitlement_group_id ON public.entitlement_groups_direct_users USING btree (entitlement_group_id);


--
-- Name: index_entitlements_on_entitlement_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlements_on_entitlement_group_id ON public.entitlements USING btree (entitlement_group_id);


--
-- Name: index_entitlements_on_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlements_on_model_id ON public.entitlements USING btree (model_id);


--
-- Name: index_favorite_models_on_user_id_and_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_models_on_user_id_and_model_id ON public.favorite_models USING btree (user_id, model_id);


--
-- Name: index_fields_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fields_on_active ON public.fields USING btree (active);


--
-- Name: index_group_access_rights_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_access_rights_on_group_id ON public.group_access_rights USING btree (group_id);


--
-- Name: index_group_access_rights_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_access_rights_on_inventory_pool_id ON public.group_access_rights USING btree (inventory_pool_id);


--
-- Name: index_group_access_rights_on_inventory_pool_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_access_rights_on_inventory_pool_id_and_group_id ON public.group_access_rights USING btree (inventory_pool_id, group_id);


--
-- Name: index_groups_users_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_users_on_group_id ON public.groups_users USING btree (group_id);


--
-- Name: index_groups_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_users_on_user_id ON public.groups_users USING btree (user_id);


--
-- Name: index_groups_users_on_user_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_users_on_user_id_and_group_id ON public.groups_users USING btree (user_id, group_id);


--
-- Name: index_holidays_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_holidays_on_inventory_pool_id ON public.holidays USING btree (inventory_pool_id);


--
-- Name: index_holidays_on_start_date_and_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_holidays_on_start_date_and_end_date ON public.holidays USING btree (start_date, end_date);


--
-- Name: index_images_on_target_id_and_target_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_images_on_target_id_and_target_type ON public.images USING btree (target_id, target_type);


--
-- Name: index_inventory_pools_model_groups_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_pools_model_groups_on_inventory_pool_id ON public.inventory_pools_model_groups USING btree (inventory_pool_id);


--
-- Name: index_inventory_pools_model_groups_on_model_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_pools_model_groups_on_model_group_id ON public.inventory_pools_model_groups USING btree (model_group_id);


--
-- Name: index_inventory_pools_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_inventory_pools_on_name ON public.inventory_pools USING btree (name);


--
-- Name: index_items_on_inventory_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_items_on_inventory_code ON public.items USING btree (inventory_code);


--
-- Name: index_items_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_inventory_pool_id ON public.items USING btree (inventory_pool_id);


--
-- Name: index_items_on_is_borrowable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_is_borrowable ON public.items USING btree (is_borrowable);


--
-- Name: index_items_on_is_broken; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_is_broken ON public.items USING btree (is_broken);


--
-- Name: index_items_on_is_incomplete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_is_incomplete ON public.items USING btree (is_incomplete);


--
-- Name: index_items_on_model_id_and_retired_and_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_model_id_and_retired_and_inventory_pool_id ON public.items USING btree (model_id, retired, inventory_pool_id);


--
-- Name: index_items_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_owner_id ON public.items USING btree (owner_id);


--
-- Name: index_items_on_parent_id_and_retired; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_parent_id_and_retired ON public.items USING btree (parent_id, retired);


--
-- Name: index_items_on_retired; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_retired ON public.items USING btree (retired);


--
-- Name: index_items_on_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_items_on_supplier_id ON public.items USING btree (supplier_id);


--
-- Name: index_languages_on_active_and_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_languages_on_active_and_default ON public.languages USING btree (active, "default");


--
-- Name: index_languages_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_languages_on_name ON public.languages USING btree (name);


--
-- Name: index_model_group_links_on_child_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_model_group_links_on_child_id ON public.model_group_links USING btree (child_id);


--
-- Name: index_model_group_links_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_model_group_links_on_parent_id ON public.model_group_links USING btree (parent_id);


--
-- Name: index_model_groups_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_model_groups_on_type ON public.model_groups USING btree (type);


--
-- Name: index_model_links_on_model_group_id_and_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_model_links_on_model_group_id_and_model_id ON public.model_links USING btree (model_group_id, model_id);


--
-- Name: index_model_links_on_model_id_and_model_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_model_links_on_model_id_and_model_group_id ON public.model_links USING btree (model_id, model_group_id);


--
-- Name: index_models_compatibles_on_compatible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_models_compatibles_on_compatible_id ON public.models_compatibles USING btree (compatible_id);


--
-- Name: index_models_compatibles_on_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_models_compatibles_on_model_id ON public.models_compatibles USING btree (model_id);


--
-- Name: index_models_on_is_package; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_models_on_is_package ON public.models USING btree (is_package);


--
-- Name: index_models_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_models_on_type ON public.models USING btree (type);


--
-- Name: index_notifications_on_created_at_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_created_at_and_user_id ON public.notifications USING btree (created_at, user_id);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_user_id ON public.notifications USING btree (user_id);


--
-- Name: index_old_empty_contracts_on_compact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_old_empty_contracts_on_compact_id ON public.old_empty_contracts USING btree (compact_id);


--
-- Name: index_on_budget_period_id_and_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_on_budget_period_id_and_category_id ON public.procurement_budget_limits USING btree (budget_period_id, main_category_id);


--
-- Name: index_on_user_id_and_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_on_user_id_and_organization_id ON public.procurement_requesters_organizations USING btree (user_id, organization_id);


--
-- Name: index_options_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_options_on_inventory_pool_id ON public.options USING btree (inventory_pool_id);


--
-- Name: index_orders_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_created_at ON public.orders USING btree (created_at);


--
-- Name: index_orders_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_inventory_pool_id ON public.orders USING btree (inventory_pool_id);


--
-- Name: index_orders_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_state ON public.orders USING btree (state);


--
-- Name: index_orders_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_user_id ON public.orders USING btree (user_id);


--
-- Name: index_procurement_admins_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_procurement_admins_on_user_id ON public.procurement_admins USING btree (user_id);


--
-- Name: index_procurement_budget_periods_on_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_procurement_budget_periods_on_end_date ON public.procurement_budget_periods USING btree (end_date);


--
-- Name: index_procurement_categories_on_main_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_procurement_categories_on_main_category_id ON public.procurement_categories USING btree (main_category_id);


--
-- Name: index_procurement_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_procurement_categories_on_name ON public.procurement_categories USING btree (name);


--
-- Name: index_procurement_main_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_procurement_main_categories_on_name ON public.procurement_main_categories USING btree (name);


--
-- Name: index_procurement_organizations_on_name_and_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_procurement_organizations_on_name_and_parent_id ON public.procurement_organizations USING btree (name, parent_id);


--
-- Name: index_procurement_requests_counters_on_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_procurement_requests_counters_on_prefix ON public.procurement_requests_counters USING btree (prefix);


--
-- Name: index_procurement_requests_on_short_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_procurement_requests_on_short_id ON public.procurement_requests USING btree (short_id);


--
-- Name: index_procurement_users_filters_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_procurement_users_filters_on_user_id ON public.procurement_users_filters USING btree (user_id);


--
-- Name: index_properties_on_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_properties_on_model_id ON public.properties USING btree (model_id);


--
-- Name: index_reservations_on_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_contract_id ON public.reservations USING btree (contract_id);


--
-- Name: index_reservations_on_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_end_date ON public.reservations USING btree (end_date);


--
-- Name: index_reservations_on_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_item_id ON public.reservations USING btree (item_id);


--
-- Name: index_reservations_on_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_model_id ON public.reservations USING btree (model_id);


--
-- Name: index_reservations_on_option_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_option_id ON public.reservations USING btree (option_id);


--
-- Name: index_reservations_on_returned_date_and_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_returned_date_and_contract_id ON public.reservations USING btree (returned_date, contract_id);


--
-- Name: index_reservations_on_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_start_date ON public.reservations USING btree (start_date);


--
-- Name: index_reservations_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_status ON public.reservations USING btree (status);


--
-- Name: index_reservations_on_type_and_contract_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_type_and_contract_id ON public.reservations USING btree (type, contract_id);


--
-- Name: index_suppliers_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_suppliers_on_name ON public.suppliers USING btree (name);


--
-- Name: index_suspensions_on_suspended_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_suspensions_on_suspended_until ON public.suspensions USING btree (suspended_until);


--
-- Name: index_suspensions_on_user_id_and_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_suspensions_on_user_id_and_inventory_pool_id ON public.suspensions USING btree (user_id, inventory_pool_id);


--
-- Name: index_user_password_resets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_password_resets_on_user_id ON public.user_password_resets USING btree (user_id);


--
-- Name: index_user_sessions_on_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_sessions_on_token_hash ON public.user_sessions USING btree (token_hash);


--
-- Name: index_user_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_sessions_on_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: index_workdays_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_workdays_on_inventory_pool_id ON public.workdays USING btree (inventory_pool_id);


--
-- Name: rooms_unique_building_id_general_true; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rooms_unique_building_id_general_true ON public.rooms USING btree (building_id, general) WHERE (general IS TRUE);


--
-- Name: rooms_unique_name_and_building_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rooms_unique_name_and_building_id ON public.rooms USING btree ((((lower((name)::text) || ' '::text) || building_id)));


--
-- Name: unique_name_procurement_budget_periods; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_name_procurement_budget_periods ON public.procurement_budget_periods USING btree (lower((name)::text));


--
-- Name: user_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_index ON public.audits USING btree (user_id, user_type);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_idx ON public.users USING btree (lower((email)::text));


--
-- Name: users_login_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_login_idx ON public.users USING btree (lower((login)::text));


--
-- Name: users_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_searchable_idx ON public.users USING gin (searchable public.gin_trgm_ops);


--
-- Name: users_secondary_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_secondary_email_idx ON public.users USING btree (lower(secondary_email));


--
-- Name: users_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_to_tsvector_idx ON public.users USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: access_rights access_rights_on_delete_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER access_rights_on_delete_t INSTEAD OF DELETE ON public.access_rights FOR EACH ROW EXECUTE PROCEDURE public.access_rights_on_delete_f();


--
-- Name: access_rights access_rights_on_insert_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER access_rights_on_insert_t INSTEAD OF INSERT ON public.access_rights FOR EACH ROW EXECUTE PROCEDURE public.access_rights_on_insert_f();


--
-- Name: access_rights access_rights_on_update_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER access_rights_on_update_t INSTEAD OF UPDATE ON public.access_rights FOR EACH ROW EXECUTE PROCEDURE public.access_rights_on_update_f();


--
-- Name: api_tokens audited_change_on_api_tokens; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_api_tokens AFTER INSERT OR DELETE OR UPDATE ON public.api_tokens FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: authentication_systems audited_change_on_authentication_systems; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_authentication_systems AFTER INSERT OR DELETE OR UPDATE ON public.authentication_systems FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: authentication_systems_groups audited_change_on_authentication_systems_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_authentication_systems_groups AFTER INSERT OR DELETE OR UPDATE ON public.authentication_systems_groups FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: authentication_systems_users audited_change_on_authentication_systems_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_authentication_systems_users AFTER INSERT OR DELETE OR UPDATE ON public.authentication_systems_users FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: contracts audited_change_on_contracts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_contracts AFTER INSERT OR DELETE OR UPDATE ON public.contracts FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: delegations_direct_users audited_change_on_delegations_direct_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_delegations_direct_users AFTER INSERT OR DELETE OR UPDATE ON public.delegations_direct_users FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: delegations_groups audited_change_on_delegations_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_delegations_groups AFTER INSERT OR DELETE OR UPDATE ON public.delegations_groups FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: direct_access_rights audited_change_on_direct_access_rights; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_direct_access_rights AFTER INSERT OR DELETE OR UPDATE ON public.direct_access_rights FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: entitlement_groups audited_change_on_entitlement_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_entitlement_groups AFTER INSERT OR DELETE OR UPDATE ON public.entitlement_groups FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: entitlement_groups_direct_users audited_change_on_entitlement_groups_direct_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_entitlement_groups_direct_users AFTER INSERT OR DELETE OR UPDATE ON public.entitlement_groups_direct_users FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: entitlement_groups_groups audited_change_on_entitlement_groups_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_entitlement_groups_groups AFTER INSERT OR DELETE OR UPDATE ON public.entitlement_groups_groups FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: group_access_rights audited_change_on_group_access_rights; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_group_access_rights AFTER INSERT OR DELETE OR UPDATE ON public.group_access_rights FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: groups audited_change_on_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_groups AFTER INSERT OR DELETE OR UPDATE ON public.groups FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: groups_users audited_change_on_groups_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_groups_users AFTER INSERT OR DELETE OR UPDATE ON public.groups_users FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: inventory_pools audited_change_on_inventory_pools; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_inventory_pools AFTER INSERT OR DELETE OR UPDATE ON public.inventory_pools FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: items audited_change_on_items; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_items AFTER INSERT OR DELETE OR UPDATE ON public.items FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: languages audited_change_on_languages; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_languages AFTER INSERT OR DELETE OR UPDATE ON public.languages FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: models audited_change_on_models; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_models AFTER INSERT OR DELETE OR UPDATE ON public.models FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: orders audited_change_on_orders; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_orders AFTER INSERT OR DELETE OR UPDATE ON public.orders FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: reservations audited_change_on_reservations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_reservations AFTER INSERT OR DELETE OR UPDATE ON public.reservations FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: settings audited_change_on_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_settings AFTER INSERT OR DELETE OR UPDATE ON public.settings FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: smtp_settings audited_change_on_smtp_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_smtp_settings AFTER INSERT OR DELETE OR UPDATE ON public.smtp_settings FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: suspensions audited_change_on_suspensions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_suspensions AFTER INSERT OR DELETE OR UPDATE ON public.suspensions FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: system_and_security_settings audited_change_on_system_and_security_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_system_and_security_settings AFTER INSERT OR DELETE OR UPDATE ON public.system_and_security_settings FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: user_password_resets audited_change_on_user_password_resets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_user_password_resets AFTER INSERT OR DELETE OR UPDATE ON public.user_password_resets FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: user_sessions audited_change_on_user_sessions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_user_sessions AFTER INSERT OR DELETE OR UPDATE ON public.user_sessions FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: users audited_change_on_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audited_change_on_users AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE public.audit_change();


--
-- Name: users clean_email; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER clean_email AFTER INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE public.clean_email();


--
-- Name: delegations_users delegations_users_on_delete_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delegations_users_on_delete_t INSTEAD OF DELETE ON public.delegations_users FOR EACH ROW EXECUTE PROCEDURE public.delegations_users_on_delete_f();


--
-- Name: delegations_users delegations_users_on_insert_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delegations_users_on_insert_t INSTEAD OF INSERT ON public.delegations_users FOR EACH ROW EXECUTE PROCEDURE public.delegations_users_on_insert_f();


--
-- Name: entitlement_groups_users entitlement_groups_users_on_delete_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER entitlement_groups_users_on_delete_t INSTEAD OF DELETE ON public.entitlement_groups_users FOR EACH ROW EXECUTE PROCEDURE public.entitlement_groups_users_on_delete_f();


--
-- Name: entitlement_groups_users entitlement_groups_users_on_insert_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER entitlement_groups_users_on_insert_t INSTEAD OF INSERT ON public.entitlement_groups_users FOR EACH ROW EXECUTE PROCEDURE public.entitlement_groups_users_on_insert_f();


--
-- Name: fields fields_insert_check_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fields_insert_check_trigger BEFORE INSERT ON public.fields FOR EACH ROW EXECUTE PROCEDURE public.fields_insert_check_function();


--
-- Name: fields fields_update_check_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fields_update_check_trigger BEFORE UPDATE ON public.fields FOR EACH ROW EXECUTE PROCEDURE public.fields_update_check_function();


--
-- Name: procurement_requests increase_counter_for_new_procurement_request_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER increase_counter_for_new_procurement_request_t AFTER INSERT ON public.procurement_requests FOR EACH ROW EXECUTE PROCEDURE public.increase_counter_for_new_procurement_request_f();


--
-- Name: procurement_budget_periods insert_counter_for_new_procurement_budget_period_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER insert_counter_for_new_procurement_budget_period_t AFTER INSERT OR UPDATE ON public.procurement_budget_periods FOR EACH ROW EXECUTE PROCEDURE public.insert_counter_for_new_procurement_budget_period_f();


--
-- Name: orders orders_insert_check_function_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER orders_insert_check_function_trigger BEFORE INSERT ON public.orders FOR EACH ROW EXECUTE PROCEDURE public.orders_insert_check_function();


--
-- Name: users populate_all_users_group_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER populate_all_users_group_t AFTER INSERT ON public.users FOR EACH STATEMENT EXECUTE PROCEDURE public.populate_all_users_group_f();


--
-- Name: groups prevent_deleting_all_users_group_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_deleting_all_users_group_t BEFORE DELETE ON public.groups FOR EACH ROW EXECUTE PROCEDURE public.prevent_deleting_all_users_group_f();


--
-- Name: procurement_requests set_short_id_for_new_procurement_request_t; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_short_id_for_new_procurement_request_t BEFORE INSERT ON public.procurement_requests FOR EACH ROW EXECUTE PROCEDURE public.set_short_id_for_new_procurement_request_f();


--
-- Name: reservations trigger_check_closed_reservations_contract_state; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_closed_reservations_contract_state AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_closed_reservations_contract_state();


--
-- Name: contracts trigger_check_contract_has_at_least_one_reservation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_contract_has_at_least_one_reservation AFTER INSERT OR UPDATE ON public.contracts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_contract_has_at_least_one_reservation();


--
-- Name: languages trigger_check_exactly_one_default_language; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_exactly_one_default_language AFTER INSERT OR DELETE OR UPDATE ON public.languages DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_exactly_one_default_language();


--
-- Name: rooms trigger_check_general_building_id_for_general_room; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_general_building_id_for_general_room AFTER UPDATE ON public.rooms NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.check_general_building_id_for_general_room();


--
-- Name: reservations trigger_check_item_line_state_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_item_line_state_consistency AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_item_line_state_consistency();


--
-- Name: reservations trigger_check_option_line_state_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_option_line_state_consistency AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_option_line_state_consistency();


--
-- Name: procurement_requesters_organizations trigger_check_parent_id_for_organization_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_parent_id_for_organization_id AFTER INSERT OR UPDATE ON public.procurement_requesters_organizations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_parent_id_for_organization_id();


--
-- Name: inventory_pools trigger_check_presence_of_workday_for_inventory_pool; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_presence_of_workday_for_inventory_pool AFTER INSERT OR UPDATE ON public.inventory_pools DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_presence_of_workday_for_inventory_pool();


--
-- Name: reservations trigger_check_reservation_contract_inventory_pool_id_consistenc; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_reservation_contract_inventory_pool_id_consistenc AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_reservation_contract_inventory_pool_id_consistency();


--
-- Name: reservations trigger_check_reservation_contract_user_id_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_reservation_contract_user_id_consistency AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_reservation_contract_user_id_consistency();


--
-- Name: reservations trigger_check_reservation_order_inventory_pool_id_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_reservation_order_inventory_pool_id_consistency AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_reservation_order_inventory_pool_id_consistency();


--
-- Name: reservations trigger_check_reservation_order_user_id_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_reservation_order_user_id_consistency AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_reservation_order_user_id_consistency();


--
-- Name: contracts trigger_check_reservations_contracts_state_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_reservations_contracts_state_consistency AFTER INSERT OR UPDATE ON public.contracts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_reservations_contracts_state_consistency();


--
-- Name: reservations trigger_delete_empty_order; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_order AFTER DELETE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.delete_empty_order();


--
-- Name: authentication_systems_users trigger_delete_obsolete_user_password_resets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_obsolete_user_password_resets AFTER INSERT OR UPDATE ON public.authentication_systems_users FOR EACH ROW EXECUTE PROCEDURE public.delete_obsolete_user_password_resets_2();


--
-- Name: user_password_resets trigger_delete_obsolete_user_password_resets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_obsolete_user_password_resets BEFORE INSERT ON public.user_password_resets FOR EACH ROW EXECUTE PROCEDURE public.delete_obsolete_user_password_resets_1();


--
-- Name: users trigger_delete_procurement_users_filters_after_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_procurement_users_filters_after_users AFTER DELETE ON public.users DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.delete_procurement_users_filters_after_users();


--
-- Name: buildings trigger_ensure_general_building_cannot_be_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_ensure_general_building_cannot_be_deleted AFTER DELETE ON public.buildings NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.ensure_general_building_cannot_be_deleted();


--
-- Name: rooms trigger_ensure_general_room_cannot_be_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_ensure_general_room_cannot_be_deleted AFTER DELETE ON public.rooms NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE public.ensure_general_room_cannot_be_deleted();


--
-- Name: fields trigger_fields_delete_check_function; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_fields_delete_check_function BEFORE DELETE ON public.fields FOR EACH ROW EXECUTE PROCEDURE public.fields_delete_check_function();


--
-- Name: groups update_searchable_column_of_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_groups BEFORE INSERT OR UPDATE ON public.groups FOR EACH ROW EXECUTE PROCEDURE public.groups_update_searchable_column();


--
-- Name: users update_searchable_column_of_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_users BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE public.users_update_searchable_column();


--
-- Name: authentication_systems update_updated_at_column_of_authentication_systems; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_authentication_systems BEFORE UPDATE ON public.authentication_systems FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: authentication_systems_groups update_updated_at_column_of_authentication_systems_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_authentication_systems_groups BEFORE UPDATE ON public.authentication_systems_groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: authentication_systems_users update_updated_at_column_of_authentication_systems_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_authentication_systems_users BEFORE UPDATE ON public.authentication_systems_users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: delegations_groups update_updated_at_column_of_delegations_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_delegations_groups BEFORE UPDATE ON public.delegations_groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: entitlement_groups_groups update_updated_at_column_of_entitlement_groups_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_entitlement_groups_groups BEFORE UPDATE ON public.entitlement_groups_groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: group_access_rights update_updated_at_column_of_group_access_rights; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_group_access_rights BEFORE UPDATE ON public.group_access_rights FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: groups update_updated_at_column_of_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_groups BEFORE UPDATE ON public.groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: procurement_requests_counters update_updated_at_column_of_procurement_requests_counters; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_procurement_requests_counters BEFORE UPDATE ON public.procurement_requests_counters FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: settings update_updated_at_column_of_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_settings BEFORE UPDATE ON public.settings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: suspensions update_updated_at_column_of_suspensions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_suspensions BEFORE UPDATE ON public.suspensions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: users update_updated_at_column_of_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_users BEFORE UPDATE ON public.users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: hidden_fields fk_rails_00a4ef0c4f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hidden_fields
    ADD CONSTRAINT fk_rails_00a4ef0c4f FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions fk_rails_033055139d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT fk_rails_033055139d FOREIGN KEY (authentication_system_id) REFERENCES public.authentication_systems(id) ON DELETE CASCADE;


--
-- Name: items fk_rails_042cf7b23c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_042cf7b23c FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: procurement_organizations fk_rails_0731e8b712; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_organizations
    ADD CONSTRAINT fk_rails_0731e8b712 FOREIGN KEY (parent_id) REFERENCES public.procurement_organizations(id);


--
-- Name: items fk_rails_0ed18b3bf9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_0ed18b3bf9 FOREIGN KEY (model_id) REFERENCES public.models(id);


--
-- Name: model_links fk_rails_11add1a9a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_links
    ADD CONSTRAINT fk_rails_11add1a9a3 FOREIGN KEY (model_group_id) REFERENCES public.model_groups(id) ON DELETE CASCADE;


--
-- Name: reservations fk_rails_151794e412; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_151794e412 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: contracts fk_rails_1bf8633565; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT fk_rails_1bf8633565 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: procurement_budget_limits fk_rails_1c5f9021ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_budget_limits
    ADD CONSTRAINT fk_rails_1c5f9021ad FOREIGN KEY (main_category_id) REFERENCES public.procurement_main_categories(id) ON DELETE CASCADE;


--
-- Name: disabled_fields fk_rails_1d39ce9bb5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_fields
    ADD CONSTRAINT fk_rails_1d39ce9bb5 FOREIGN KEY (field_id) REFERENCES public.fields(id) ON DELETE CASCADE;


--
-- Name: procurement_requests fk_rails_214a7de1ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_214a7de1ff FOREIGN KEY (model_id) REFERENCES public.models(id);


--
-- Name: suspensions fk_rails_244571cbc2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suspensions
    ADD CONSTRAINT fk_rails_244571cbc2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: orders fk_rails_251099155b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_251099155b FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: entitlement_groups_groups fk_rails_34e85ae630; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_groups
    ADD CONSTRAINT fk_rails_34e85ae630 FOREIGN KEY (entitlement_group_id) REFERENCES public.entitlement_groups(id);


--
-- Name: entitlement_groups_groups fk_rails_35f9f6c9e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_groups
    ADD CONSTRAINT fk_rails_35f9f6c9e0 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: procurement_attachments fk_rails_396a61ca60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_attachments
    ADD CONSTRAINT fk_rails_396a61ca60 FOREIGN KEY (request_id) REFERENCES public.procurement_requests(id) ON DELETE CASCADE;


--
-- Name: reservations fk_rails_3cc4562273; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_3cc4562273 FOREIGN KEY (handed_over_by_user_id) REFERENCES public.users(id);


--
-- Name: hidden_fields fk_rails_3dac013d86; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hidden_fields
    ADD CONSTRAINT fk_rails_3dac013d86 FOREIGN KEY (field_id) REFERENCES public.fields(id) ON DELETE CASCADE;


--
-- Name: entitlements fk_rails_44495fc6cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT fk_rails_44495fc6cf FOREIGN KEY (entitlement_group_id) REFERENCES public.entitlement_groups(id);


--
-- Name: entitlement_groups fk_rails_45f96f9df2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups
    ADD CONSTRAINT fk_rails_45f96f9df2 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: procurement_templates fk_rails_46cc05bf71; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_templates
    ADD CONSTRAINT fk_rails_46cc05bf71 FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: reservations fk_rails_48a92fce51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_48a92fce51 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: model_group_links fk_rails_48e1ccdd03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_group_links
    ADD CONSTRAINT fk_rails_48e1ccdd03 FOREIGN KEY (child_id) REFERENCES public.model_groups(id) ON DELETE CASCADE;


--
-- Name: procurement_requests fk_rails_4c51bafad3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_4c51bafad3 FOREIGN KEY (organization_id) REFERENCES public.procurement_organizations(id);


--
-- Name: users fk_rails_4cc2fddb7b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_4cc2fddb7b FOREIGN KEY (language_locale) REFERENCES public.languages(locale);


--
-- Name: reservations fk_rails_4d0c0195f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_4d0c0195f0 FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: entitlement_groups_direct_users fk_rails_4e63edbd27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_direct_users
    ADD CONSTRAINT fk_rails_4e63edbd27 FOREIGN KEY (entitlement_group_id) REFERENCES public.entitlement_groups(id);


--
-- Name: groups_users fk_rails_4e63edbd27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT fk_rails_4e63edbd27 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: procurement_requests fk_rails_51707743b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_51707743b7 FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: items fk_rails_538506beaf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_538506beaf FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: accessories fk_rails_54c6f19548; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accessories
    ADD CONSTRAINT fk_rails_54c6f19548 FOREIGN KEY (model_id) REFERENCES public.models(id) ON DELETE CASCADE;


--
-- Name: suspensions fk_rails_564631fd04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suspensions
    ADD CONSTRAINT fk_rails_564631fd04 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: authentication_systems_users fk_rails_5a92563444; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems_users
    ADD CONSTRAINT fk_rails_5a92563444 FOREIGN KEY (authentication_system_id) REFERENCES public.authentication_systems(id);


--
-- Name: models fk_rails_5aa4f56a65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models
    ADD CONSTRAINT fk_rails_5aa4f56a65 FOREIGN KEY (cover_image_id) REFERENCES public.images(id);


--
-- Name: models_compatibles fk_rails_5c311e46b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models_compatibles
    ADD CONSTRAINT fk_rails_5c311e46b1 FOREIGN KEY (model_id) REFERENCES public.models(id);


--
-- Name: reservations fk_rails_5cc2043d96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_5cc2043d96 FOREIGN KEY (returned_to_user_id) REFERENCES public.users(id);


--
-- Name: mail_templates fk_rails_5d00b5b086; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_templates
    ADD CONSTRAINT fk_rails_5d00b5b086 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id) ON DELETE CASCADE;


--
-- Name: procurement_images fk_rails_62917a6a8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_images
    ADD CONSTRAINT fk_rails_62917a6a8f FOREIGN KEY (main_category_id) REFERENCES public.procurement_main_categories(id) ON DELETE CASCADE;


--
-- Name: entitlements fk_rails_69c88ff594; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT fk_rails_69c88ff594 FOREIGN KEY (model_id) REFERENCES public.models(id) ON DELETE CASCADE;


--
-- Name: inventory_pools fk_rails_6a55965722; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_pools
    ADD CONSTRAINT fk_rails_6a55965722 FOREIGN KEY (address_id) REFERENCES public.addresses(id);


--
-- Name: inventory_pools_model_groups fk_rails_6a7781d99f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_pools_model_groups
    ADD CONSTRAINT fk_rails_6a7781d99f FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: mail_templates fk_rails_6e53f12ad6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_templates
    ADD CONSTRAINT fk_rails_6e53f12ad6 FOREIGN KEY (language_locale) REFERENCES public.languages(locale);


--
-- Name: reservations fk_rails_6f10314351; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_6f10314351 FOREIGN KEY (delegated_user_id) REFERENCES public.users(id);


--
-- Name: attachments fk_rails_753607b7c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT fk_rails_753607b7c1 FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: procurement_requests_counters fk_rails_7d83a14766; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests_counters
    ADD CONSTRAINT fk_rails_7d83a14766 FOREIGN KEY (created_by_budget_period_id) REFERENCES public.procurement_budget_periods(id) ON DELETE CASCADE;


--
-- Name: procurement_admins fk_rails_7f23ec3f14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_admins
    ADD CONSTRAINT fk_rails_7f23ec3f14 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: entitlement_groups_direct_users fk_rails_8546c71994; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_direct_users
    ADD CONSTRAINT fk_rails_8546c71994 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: groups_users fk_rails_8546c71994; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT fk_rails_8546c71994 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: items fk_rails_8757b4d49c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_8757b4d49c FOREIGN KEY (owner_id) REFERENCES public.inventory_pools(id);


--
-- Name: user_sessions fk_rails_8987cee3fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT fk_rails_8987cee3fd FOREIGN KEY (delegation_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: reservations fk_rails_8dc1da71d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_8dc1da71d1 FOREIGN KEY (contract_id) REFERENCES public.contracts(id) ON DELETE CASCADE;


--
-- Name: customer_orders fk_rails_90249e6b2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_orders
    ADD CONSTRAINT fk_rails_90249e6b2c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: items fk_rails_9353db44a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_9353db44a2 FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: reservations fk_rails_943a884838; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_943a884838 FOREIGN KEY (model_id) REFERENCES public.models(id);


--
-- Name: accessories_inventory_pools fk_rails_9511c9a747; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accessories_inventory_pools
    ADD CONSTRAINT fk_rails_9511c9a747 FOREIGN KEY (accessory_id) REFERENCES public.accessories(id);


--
-- Name: group_access_rights fk_rails_975fee0026; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_access_rights
    ADD CONSTRAINT fk_rails_975fee0026 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: model_links fk_rails_9b7295b085; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_links
    ADD CONSTRAINT fk_rails_9b7295b085 FOREIGN KEY (model_id) REFERENCES public.models(id) ON DELETE CASCADE;


--
-- Name: procurement_category_viewers fk_rails_9e16e3bd5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_category_viewers
    ADD CONSTRAINT fk_rails_9e16e3bd5d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_sessions fk_rails_9fa262d742; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT fk_rails_9fa262d742 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: authentication_systems_users fk_rails_9fe924475a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems_users
    ADD CONSTRAINT fk_rails_9fe924475a FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: workdays fk_rails_a18bc267df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workdays
    ADD CONSTRAINT fk_rails_a18bc267df FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id) ON DELETE CASCADE;


--
-- Name: rooms fk_rails_a3957b23a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT fk_rails_a3957b23a8 FOREIGN KEY (building_id) REFERENCES public.buildings(id) ON DELETE CASCADE;


--
-- Name: delegations_groups fk_rails_a507ac19bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_groups
    ADD CONSTRAINT fk_rails_a507ac19bd FOREIGN KEY (delegation_id) REFERENCES public.users(id);


--
-- Name: properties fk_rails_a52b96ad3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT fk_rails_a52b96ad3d FOREIGN KEY (model_id) REFERENCES public.models(id) ON DELETE CASCADE;


--
-- Name: disabled_fields fk_rails_a62b923fbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_fields
    ADD CONSTRAINT fk_rails_a62b923fbd FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id) ON DELETE CASCADE;


--
-- Name: reservations fk_rails_a863d81c8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_a863d81c8a FOREIGN KEY (option_id) REFERENCES public.options(id);


--
-- Name: procurement_categories fk_rails_a8a841ddeb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_categories
    ADD CONSTRAINT fk_rails_a8a841ddeb FOREIGN KEY (main_category_id) REFERENCES public.procurement_main_categories(id) ON DELETE CASCADE;


--
-- Name: favorite_models fk_rails_adcbeea1cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_models
    ADD CONSTRAINT fk_rails_adcbeea1cb FOREIGN KEY (model_id) REFERENCES public.models(id) ON DELETE CASCADE;


--
-- Name: authentication_systems_groups fk_rails_ae3d1b0414; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems_groups
    ADD CONSTRAINT fk_rails_ae3d1b0414 FOREIGN KEY (authentication_system_id) REFERENCES public.authentication_systems(id);


--
-- Name: notifications fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: direct_access_rights fk_rails_b36d97eb0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_access_rights
    ADD CONSTRAINT fk_rails_b36d97eb0c FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id) ON DELETE CASCADE;


--
-- Name: procurement_requests fk_rails_b6213e1ee9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_b6213e1ee9 FOREIGN KEY (budget_period_id) REFERENCES public.procurement_budget_periods(id);


--
-- Name: procurement_requests fk_rails_b740f37e3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_b740f37e3d FOREIGN KEY (category_id) REFERENCES public.procurement_categories(id);


--
-- Name: procurement_budget_limits fk_rails_beb637d785; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_budget_limits
    ADD CONSTRAINT fk_rails_beb637d785 FOREIGN KEY (budget_period_id) REFERENCES public.procurement_budget_periods(id) ON DELETE CASCADE;


--
-- Name: procurement_requests fk_rails_bf7bec026c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_bf7bec026c FOREIGN KEY (template_id) REFERENCES public.procurement_templates(id);


--
-- Name: procurement_requesters_organizations fk_rails_c116e35025; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requesters_organizations
    ADD CONSTRAINT fk_rails_c116e35025 FOREIGN KEY (organization_id) REFERENCES public.procurement_organizations(id);


--
-- Name: holidays fk_rails_c189a29194; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT fk_rails_c189a29194 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id) ON DELETE CASCADE;


--
-- Name: orders fk_rails_c6bc8a139b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_c6bc8a139b FOREIGN KEY (customer_order_id) REFERENCES public.customer_orders(id);


--
-- Name: group_access_rights fk_rails_c74a24670e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_access_rights
    ADD CONSTRAINT fk_rails_c74a24670e FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: user_password_resets fk_rails_c84bfcc8b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_password_resets
    ADD CONSTRAINT fk_rails_c84bfcc8b6 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: inventory_pools_model_groups fk_rails_cb04742a0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_pools_model_groups
    ADD CONSTRAINT fk_rails_cb04742a0b FOREIGN KEY (model_group_id) REFERENCES public.model_groups(id);


--
-- Name: model_group_links fk_rails_d4425f3184; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_group_links
    ADD CONSTRAINT fk_rails_d4425f3184 FOREIGN KEY (parent_id) REFERENCES public.model_groups(id) ON DELETE CASCADE;


--
-- Name: procurement_category_viewers fk_rails_d7441d6a05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_category_viewers
    ADD CONSTRAINT fk_rails_d7441d6a05 FOREIGN KEY (category_id) REFERENCES public.procurement_categories(id) ON DELETE CASCADE;


--
-- Name: authentication_systems_groups fk_rails_dcba69d719; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems_groups
    ADD CONSTRAINT fk_rails_dcba69d719 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: models_compatibles fk_rails_e63411efbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models_compatibles
    ADD CONSTRAINT fk_rails_e63411efbd FOREIGN KEY (compatible_id) REFERENCES public.models(id);


--
-- Name: procurement_templates fk_rails_e6aab61827; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_templates
    ADD CONSTRAINT fk_rails_e6aab61827 FOREIGN KEY (model_id) REFERENCES public.models(id);


--
-- Name: accessories_inventory_pools fk_rails_e9daa88f6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accessories_inventory_pools
    ADD CONSTRAINT fk_rails_e9daa88f6c FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: favorite_models fk_rails_ecb05addb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_models
    ADD CONSTRAINT fk_rails_ecb05addb0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: procurement_users_filters fk_rails_ecc9c968b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_users_filters
    ADD CONSTRAINT fk_rails_ecc9c968b6 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: procurement_category_inspectors fk_rails_ed1149b98d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_category_inspectors
    ADD CONSTRAINT fk_rails_ed1149b98d FOREIGN KEY (category_id) REFERENCES public.procurement_categories(id) ON DELETE CASCADE;


--
-- Name: items fk_rails_ed5bf219ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT fk_rails_ed5bf219ac FOREIGN KEY (parent_id) REFERENCES public.items(id) ON DELETE SET NULL;


--
-- Name: contracts fk_rails_f191b5ed7a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT fk_rails_f191b5ed7a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: procurement_requests fk_rails_f365098d3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_f365098d3c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: procurement_requests fk_rails_f60a954ec5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_requests
    ADD CONSTRAINT fk_rails_f60a954ec5 FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: delegations_groups fk_rails_f6b29853e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_groups
    ADD CONSTRAINT fk_rails_f6b29853e0 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: attachments fk_rails_f6d36cd48e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT fk_rails_f6d36cd48e FOREIGN KEY (model_id) REFERENCES public.models(id) ON DELETE CASCADE;


--
-- Name: procurement_category_inspectors fk_rails_f80c94fb1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_category_inspectors
    ADD CONSTRAINT fk_rails_f80c94fb1e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: orders fk_rails_f868b47f6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_f868b47f6a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: options fk_rails_fd8397be78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT fk_rails_fd8397be78 FOREIGN KEY (inventory_pool_id) REFERENCES public.inventory_pools(id);


--
-- Name: procurement_templates fk_rails_fe27b0b24a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_templates
    ADD CONSTRAINT fk_rails_fe27b0b24a FOREIGN KEY (category_id) REFERENCES public.procurement_categories(id);


--
-- Name: direct_access_rights fkey_access_rights_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_access_rights
    ADD CONSTRAINT fkey_access_rights_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: delegations_direct_users fkey_delegations_users_delegation_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_direct_users
    ADD CONSTRAINT fkey_delegations_users_delegation_id FOREIGN KEY (delegation_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: delegations_direct_users fkey_delegations_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_direct_users
    ADD CONSTRAINT fkey_delegations_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: images fkey_images_images_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT fkey_images_images_parent_id FOREIGN KEY (parent_id) REFERENCES public.images(id);


--
-- Name: users fkey_users_delegators; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fkey_users_delegators FOREIGN KEY (delegator_user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('0'),
('1'),
('10'),
('100'),
('101'),
('102'),
('103'),
('104'),
('105'),
('106'),
('107'),
('108'),
('109'),
('11'),
('110'),
('111'),
('112'),
('113'),
('114'),
('115'),
('116'),
('117'),
('118'),
('119'),
('12'),
('120'),
('121'),
('122'),
('13'),
('2'),
('200'),
('201'),
('202'),
('203'),
('204'),
('205'),
('206'),
('207'),
('208'),
('209'),
('210'),
('211'),
('212'),
('213'),
('214'),
('215'),
('216'),
('217'),
('218'),
('219'),
('220'),
('221'),
('222'),
('223'),
('300'),
('301'),
('302'),
('303'),
('304'),
('305'),
('306'),
('307'),
('308'),
('309'),
('310'),
('311'),
('312'),
('313'),
('314'),
('315'),
('316'),
('317'),
('318'),
('319'),
('320'),
('321'),
('322'),
('4'),
('5'),
('500'),
('501'),
('502'),
('503'),
('504'),
('505'),
('506'),
('507'),
('508'),
('509'),
('510'),
('511'),
('512'),
('513'),
('514'),
('515'),
('516'),
('517'),
('518'),
('519'),
('520'),
('521'),
('522'),
('523'),
('524'),
('525'),
('526'),
('530'),
('531'),
('532'),
('533'),
('534'),
('535'),
('536'),
('537'),
('538'),
('539'),
('540'),
('541'),
('542'),
('543'),
('544'),
('545'),
('546'),
('547'),
('548'),
('549'),
('550'),
('551'),
('552'),
('553'),
('554'),
('555'),
('556'),
('557'),
('578'),
('579'),
('580'),
('581'),
('582'),
('583'),
('584'),
('585'),
('586'),
('587'),
('588'),
('589'),
('590'),
('591'),
('592'),
('6'),
('7'),
('8'),
('9');


