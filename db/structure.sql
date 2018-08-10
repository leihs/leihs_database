--
-- PostgreSQL database dump
--

-- Dumped from database version 10.4
-- Dumped by pg_dump version 10.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
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
-- Name: reservation_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.reservation_status AS ENUM (
    'unsubmitted',
    'submitted',
    'rejected',
    'approved',
    'signed',
    'closed'
);


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
   NEW.searchable = COALESCE(NEW.lastname::text, '') || ' ' || COALESCE(NEW.firstname::text, '') || ' ' || COALESCE(NEW.email::text, '') || ' ' || COALESCE(NEW.badge_id::text, '') || ' ' || COALESCE(NEW.org_id::text, '') ;
   RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_rights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_rights (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    inventory_pool_id uuid,
    suspended_until date,
    suspended_reason text,
    deleted_at date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying NOT NULL,
    CONSTRAINT check_allowed_roles CHECK (((role)::text = ANY ((ARRAY['customer'::character varying, 'group_manager'::character varying, 'lending_manager'::character varying, 'inventory_manager'::character varying])::text[])))
);


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
    content_type character varying,
    filename character varying,
    size integer,
    item_id uuid,
    content text,
    metadata json
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
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying,
    class_name character varying,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT false
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
-- Name: database_authentications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.database_authentications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    login character varying NOT NULL,
    crypted_password character varying(40),
    salt character varying(40),
    user_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delegations_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delegations_users (
    delegation_id uuid NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: disabled_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disabled_fields (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    field_id character varying NOT NULL,
    inventory_pool_id uuid NOT NULL
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
-- Name: entitlement_groups_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entitlement_groups_users (
    user_id uuid,
    entitlement_group_id uuid
);


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
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text,
    org_id character varying,
    searchable text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
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
    automatic_access boolean,
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
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying,
    locale_name character varying,
    "default" boolean,
    active boolean
);


--
-- Name: mail_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mail_templates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inventory_pool_id uuid,
    language_id uuid NOT NULL,
    name character varying NOT NULL,
    format character varying NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_template_template boolean NOT NULL,
    type text NOT NULL,
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
    updated_at timestamp without time zone NOT NULL
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
    metadata json
);


--
-- Name: procurement_budget_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.procurement_budget_limits (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    budget_period_id uuid NOT NULL,
    main_category_id uuid NOT NULL,
    amount_cents integer DEFAULT 0 NOT NULL,
    amount_currency character varying DEFAULT 'CHF'::character varying NOT NULL
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
    updated_at timestamp without time zone DEFAULT now() NOT NULL
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
    metadata json
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
    price_cents integer DEFAULT 0 NOT NULL,
    price_currency character varying DEFAULT 'CHF'::character varying NOT NULL,
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
    CONSTRAINT article_name_is_not_blank CHECK ((article_name !~ '^\s*$'::text)),
    CONSTRAINT check_allowed_priorities CHECK (((priority)::text = ANY ((ARRAY['normal'::character varying, 'high'::character varying])::text[]))),
    CONSTRAINT check_either_model_id_or_article_name CHECK ((((model_id IS NOT NULL) AND (article_name IS NULL)) OR ((model_id IS NULL) AND (article_name IS NOT NULL)))),
    CONSTRAINT check_either_supplier_id_or_supplier_name CHECK ((((supplier_id IS NOT NULL) AND (supplier_name IS NULL)) OR ((supplier_id IS NULL) AND (supplier_name IS NOT NULL)) OR ((supplier_id IS NULL) AND (supplier_name IS NULL)))),
    CONSTRAINT check_inspector_priority CHECK (((inspector_priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'mandatory'::character varying])::text[]))),
    CONSTRAINT check_internal_order_number_if_type_investment CHECK ((NOT (((accounting_type)::text = 'investment'::text) AND (internal_order_number IS NULL)))),
    CONSTRAINT check_valid_accounting_type CHECK (((accounting_type)::text = ANY ((ARRAY['aquisition'::character varying, 'investment'::character varying])::text[]))),
    CONSTRAINT supplier_name_is_not_blank CHECK (((supplier_name)::text !~ '^\s*$'::text))
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
    price_currency character varying DEFAULT 'CHF'::character varying NOT NULL,
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
    created_at timestamp without time zone DEFAULT now() NOT NULL
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
    status public.reservation_status NOT NULL,
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
    CONSTRAINT check_order_id_for_different_statuses_of_item_line CHECK (((((type)::text = 'ItemLine'::text) AND (((status = 'unsubmitted'::public.reservation_status) AND (order_id IS NULL)) OR ((status = ANY (ARRAY['submitted'::public.reservation_status, 'rejected'::public.reservation_status])) AND (order_id IS NOT NULL)) OR (status = ANY (ARRAY['approved'::public.reservation_status, 'signed'::public.reservation_status, 'closed'::public.reservation_status])))) OR (((type)::text = 'OptionLine'::text) AND (status = ANY (ARRAY['approved'::public.reservation_status, 'signed'::public.reservation_status, 'closed'::public.reservation_status]))))),
    CONSTRAINT check_valid_status_and_contract_id CHECK ((((status = ANY (ARRAY['unsubmitted'::public.reservation_status, 'submitted'::public.reservation_status, 'approved'::public.reservation_status, 'rejected'::public.reservation_status])) AND (contract_id IS NULL)) OR ((status = ANY (ARRAY['signed'::public.reservation_status, 'closed'::public.reservation_status])) AND (contract_id IS NOT NULL))))
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
    smtp_address character varying,
    smtp_port integer,
    smtp_domain character varying,
    local_currency_string character varying,
    contract_terms text,
    contract_lending_party_string text,
    email_signature character varying,
    default_email character varying,
    deliver_received_order_notifications boolean,
    user_image_url character varying,
    ldap_config character varying,
    logo_url character varying,
    mail_delivery_method character varying,
    smtp_username character varying,
    smtp_password character varying,
    smtp_enable_starttls_auto boolean DEFAULT false NOT NULL,
    smtp_openssl_verify_mode character varying DEFAULT 'none'::character varying NOT NULL,
    time_zone character varying DEFAULT 'Bern'::character varying NOT NULL,
    disable_manage_section boolean DEFAULT false NOT NULL,
    disable_manage_section_message text,
    disable_borrow_section boolean DEFAULT false NOT NULL,
    disable_borrow_section_message text,
    text text,
    timeout_minutes integer DEFAULT 30 NOT NULL,
    external_base_url character varying,
    custom_head_tag text,
    sessions_max_lifetime_secs integer DEFAULT 432000,
    sessions_force_uniqueness boolean DEFAULT true NOT NULL,
    sessions_force_secure boolean DEFAULT false NOT NULL,
    documentation_link character varying DEFAULT ''::character varying,
    id integer DEFAULT 0 NOT NULL,
    accept_server_secret_as_universal_password boolean DEFAULT true NOT NULL,
    shibboleth_enabled boolean DEFAULT false NOT NULL,
    shibboleth_login_path text DEFAULT '/Shibboleth.sso/Login'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT id_is_zero CHECK ((id = 0))
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    note text DEFAULT ''::text
);


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    token_hash text NOT NULL,
    user_id uuid,
    delegation_id uuid,
    created_at timestamp with time zone DEFAULT now()
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
    authentication_system_id uuid,
    org_id character varying,
    email character varying,
    badge_id character varying,
    address character varying,
    city character varying,
    zip character varying,
    country character varying,
    language_id uuid,
    extended_info text,
    settings character varying(1024),
    delegator_user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    searchable text DEFAULT ''::text NOT NULL,
    account_enabled boolean DEFAULT true NOT NULL,
    password_sign_in_enabled boolean DEFAULT true NOT NULL,
    url character varying,
    pw_hash text DEFAULT public.crypt((public.gen_random_uuid())::text, public.gen_salt('bf'::text)) NOT NULL,
    img256_url character varying(100000),
    img32_url character varying(10000),
    img_digest text,
    is_admin boolean DEFAULT false NOT NULL
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
            WHEN (visit_reservations.status = 'submitted'::public.reservation_status) THEN false
            WHEN (visit_reservations.status = ANY (ARRAY['approved'::public.reservation_status, 'signed'::public.reservation_status])) THEN true
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
                    WHEN (reservations.status = ANY (ARRAY['submitted'::public.reservation_status, 'approved'::public.reservation_status])) THEN reservations.start_date
                    WHEN (reservations.status = 'signed'::public.reservation_status) THEN reservations.end_date
                    ELSE NULL::date
                END AS date,
                CASE
                    WHEN (reservations.status = ANY (ARRAY['submitted'::public.reservation_status, 'approved'::public.reservation_status])) THEN 'hand_over'::text
                    WHEN (reservations.status = 'signed'::public.reservation_status) THEN 'take_back'::text
                    ELSE NULL::text
                END AS visit_type,
            reservations.status,
            reservations.quantity,
            (EXISTS ( SELECT 1
                   FROM (public.entitlement_groups_users
                     JOIN public.entitlement_groups ON ((entitlement_groups.id = entitlement_groups_users.entitlement_group_id)))
                  WHERE ((entitlement_groups_users.user_id = reservations.user_id) AND (entitlement_groups.is_verification_required IS TRUE)))) AS with_user_to_verify,
            (EXISTS ( SELECT 1
                   FROM ((public.entitlements
                     JOIN public.entitlement_groups ON ((entitlement_groups.id = entitlements.entitlement_group_id)))
                     JOIN public.entitlement_groups_users ON ((entitlement_groups_users.entitlement_group_id = entitlement_groups.id)))
                  WHERE ((entitlements.model_id = reservations.model_id) AND (entitlement_groups_users.user_id = reservations.user_id) AND (entitlement_groups.is_verification_required IS TRUE)))) AS with_user_and_model_to_verify
           FROM public.reservations
          WHERE (reservations.status = ANY (ARRAY['submitted'::public.reservation_status, 'approved'::public.reservation_status, 'signed'::public.reservation_status]))) visit_reservations
  GROUP BY visit_reservations.user_id, visit_reservations.inventory_pool_id, visit_reservations.date, visit_reservations.visit_type, visit_reservations.status;


--
-- Name: workdays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workdays (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    inventory_pool_id uuid,
    monday boolean DEFAULT true,
    tuesday boolean DEFAULT true,
    wednesday boolean DEFAULT true,
    thursday boolean DEFAULT true,
    friday boolean DEFAULT true,
    saturday boolean DEFAULT false,
    sunday boolean DEFAULT false,
    reservation_advance_days integer DEFAULT 0,
    max_visits text
);


--
-- Name: access_rights access_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_rights
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
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: authentication_systems authentication_systems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_systems
    ADD CONSTRAINT authentication_systems_pkey PRIMARY KEY (id);


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
-- Name: database_authentications database_authentications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.database_authentications
    ADD CONSTRAINT database_authentications_pkey PRIMARY KEY (id);


--
-- Name: disabled_fields disabled_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disabled_fields
    ADD CONSTRAINT disabled_fields_pkey PRIMARY KEY (id);


--
-- Name: fields fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (id);


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
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


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
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


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
-- Name: case_insensitive_inventory_code_for_items; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX case_insensitive_inventory_code_for_items ON public.items USING btree (lower((inventory_code)::text));


--
-- Name: case_insensitive_inventory_code_for_options; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX case_insensitive_inventory_code_for_options ON public.options USING btree (lower((inventory_code)::text));


--
-- Name: groups_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_searchable_idx ON public.groups USING gin (searchable public.gin_trgm_ops);


--
-- Name: groups_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_to_tsvector_idx ON public.groups USING gin (to_tsvector('english'::regconfig, searchable));


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

CREATE UNIQUE INDEX idx_user_egroup ON public.entitlement_groups_users USING btree (user_id, entitlement_group_id);


--
-- Name: index_access_rights_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_rights_on_deleted_at ON public.access_rights USING btree (deleted_at);


--
-- Name: index_access_rights_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_rights_on_inventory_pool_id ON public.access_rights USING btree (inventory_pool_id);


--
-- Name: index_access_rights_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_rights_on_role ON public.access_rights USING btree (role);


--
-- Name: index_access_rights_on_suspended_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_rights_on_suspended_until ON public.access_rights USING btree (suspended_until);


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
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_created_at ON public.audits USING btree (created_at);


--
-- Name: index_audits_on_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_request_uuid ON public.audits USING btree (request_uuid);


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
-- Name: index_delegations_users_on_delegation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delegations_users_on_delegation_id ON public.delegations_users USING btree (delegation_id);


--
-- Name: index_delegations_users_on_user_id_and_delegation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_delegations_users_on_user_id_and_delegation_id ON public.delegations_users USING btree (user_id, delegation_id);


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

CREATE INDEX index_entitlement_groups_users_on_entitlement_group_id ON public.entitlement_groups_users USING btree (entitlement_group_id);


--
-- Name: index_entitlements_on_entitlement_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlements_on_entitlement_group_id ON public.entitlements USING btree (entitlement_group_id);


--
-- Name: index_entitlements_on_model_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_entitlements_on_model_id ON public.entitlements USING btree (model_id);


--
-- Name: index_fields_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fields_on_active ON public.fields USING btree (active);


--
-- Name: index_groups_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_org_id ON public.groups USING btree (org_id);


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
-- Name: index_on_user_id_and_inventory_pool_id_and_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_user_id_and_inventory_pool_id_and_deleted_at ON public.access_rights USING btree (user_id, inventory_pool_id, deleted_at);


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
-- Name: index_user_sessions_on_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_sessions_on_token_hash ON public.user_sessions USING btree (token_hash);


--
-- Name: index_user_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_sessions_on_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: index_users_on_authentication_system_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_authentication_system_id ON public.users USING btree (authentication_system_id);


--
-- Name: index_workdays_on_inventory_pool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workdays_on_inventory_pool_id ON public.workdays USING btree (inventory_pool_id);


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
-- Name: users_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_org_id_idx ON public.users USING btree (org_id);


--
-- Name: users_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_searchable_idx ON public.users USING gin (searchable public.gin_trgm_ops);


--
-- Name: users_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_to_tsvector_idx ON public.users USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: fields fields_insert_check_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fields_insert_check_trigger BEFORE INSERT ON public.fields FOR EACH ROW EXECUTE PROCEDURE public.fields_insert_check_function();


--
-- Name: fields fields_update_check_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fields_update_check_trigger BEFORE UPDATE ON public.fields FOR EACH ROW EXECUTE PROCEDURE public.fields_update_check_function();


--
-- Name: reservations trigger_check_closed_reservations_contract_state; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_closed_reservations_contract_state AFTER INSERT OR UPDATE ON public.reservations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_closed_reservations_contract_state();


--
-- Name: contracts trigger_check_contract_has_at_least_one_reservation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_contract_has_at_least_one_reservation AFTER INSERT OR UPDATE ON public.contracts DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_contract_has_at_least_one_reservation();


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
-- Name: groups update_updated_at_column_of_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_groups BEFORE UPDATE ON public.groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: settings update_updated_at_column_of_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_settings BEFORE UPDATE ON public.settings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


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
-- Name: users fk_rails_330f34f125; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_330f34f125 FOREIGN KEY (authentication_system_id) REFERENCES public.authentication_systems(id);


--
-- Name: procurement_attachments fk_rails_396a61ca60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_attachments
    ADD CONSTRAINT fk_rails_396a61ca60 FOREIGN KEY (request_id) REFERENCES public.procurement_requests(id);


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
-- Name: mail_templates fk_rails_3e8b923972; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_templates
    ADD CONSTRAINT fk_rails_3e8b923972 FOREIGN KEY (language_id) REFERENCES public.languages(id) ON DELETE CASCADE;


--
-- Name: entitlements fk_rails_44495fc6cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT fk_rails_44495fc6cf FOREIGN KEY (entitlement_group_id) REFERENCES public.entitlement_groups(id);


--
-- Name: users fk_rails_45f4f12508; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_45f4f12508 FOREIGN KEY (language_id) REFERENCES public.languages(id);


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
-- Name: reservations fk_rails_4d0c0195f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_4d0c0195f0 FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: entitlement_groups_users fk_rails_4e63edbd27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_users
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
-- Name: procurement_admins fk_rails_7f23ec3f14; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.procurement_admins
    ADD CONSTRAINT fk_rails_7f23ec3f14 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: entitlement_groups_users fk_rails_8546c71994; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlement_groups_users
    ADD CONSTRAINT fk_rails_8546c71994 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: groups_users fk_rails_8546c71994; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT fk_rails_8546c71994 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: database_authentications fk_rails_85650bffa9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.database_authentications
    ADD CONSTRAINT fk_rails_85650bffa9 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


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
-- Name: notifications fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: access_rights fk_rails_b36d97eb0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_rights
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
-- Name: access_rights fkey_access_rights_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_rights
    ADD CONSTRAINT fkey_access_rights_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: delegations_users fkey_delegations_users_delegation_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_users
    ADD CONSTRAINT fkey_delegations_users_delegation_id FOREIGN KEY (delegation_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: delegations_users fkey_delegations_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delegations_users
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
('4'),
('5'),
('500'),
('501'),
('502'),
('503'),
('504'),
('6'),
('7'),
('8'),
('9');


