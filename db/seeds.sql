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
-- Data for Name: images; Type: TABLE DATA; Schema: public; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.images DISABLE TRIGGER ALL;



ALTER TABLE public.images ENABLE TRIGGER ALL;

--
-- Data for Name: models; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.models DISABLE TRIGGER ALL;



ALTER TABLE public.models ENABLE TRIGGER ALL;

--
-- Data for Name: accessories; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.accessories DISABLE TRIGGER ALL;



ALTER TABLE public.accessories ENABLE TRIGGER ALL;

--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.addresses DISABLE TRIGGER ALL;



ALTER TABLE public.addresses ENABLE TRIGGER ALL;

--
-- Data for Name: inventory_pools; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.inventory_pools DISABLE TRIGGER ALL;



ALTER TABLE public.inventory_pools ENABLE TRIGGER ALL;

--
-- Data for Name: accessories_inventory_pools; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.accessories_inventory_pools DISABLE TRIGGER ALL;



ALTER TABLE public.accessories_inventory_pools ENABLE TRIGGER ALL;

--
-- Data for Name: api_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.api_tokens DISABLE TRIGGER ALL;



ALTER TABLE public.api_tokens ENABLE TRIGGER ALL;

--
-- Data for Name: buildings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.buildings DISABLE TRIGGER ALL;

INSERT INTO public.buildings (id, name, code) VALUES ('abae04c5-d767-425e-acc2-7ce04df645d1', 'general building', NULL);


ALTER TABLE public.buildings ENABLE TRIGGER ALL;

--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.rooms DISABLE TRIGGER ALL;

INSERT INTO public.rooms (id, name, description, building_id, general) VALUES ('b8927fd2-014c-48c2-b095-fa1d5620debe', 'general room', NULL, 'abae04c5-d767-425e-acc2-7ce04df645d1', true);


ALTER TABLE public.rooms ENABLE TRIGGER ALL;

--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.suppliers DISABLE TRIGGER ALL;



ALTER TABLE public.suppliers ENABLE TRIGGER ALL;

--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.items DISABLE TRIGGER ALL;



ALTER TABLE public.items ENABLE TRIGGER ALL;

--
-- Data for Name: attachments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.attachments DISABLE TRIGGER ALL;



ALTER TABLE public.attachments ENABLE TRIGGER ALL;

--
-- Data for Name: audited_requests; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.audited_requests DISABLE TRIGGER ALL;



ALTER TABLE public.audited_requests ENABLE TRIGGER ALL;

--
-- Data for Name: audited_responses; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.audited_responses DISABLE TRIGGER ALL;



ALTER TABLE public.audited_responses ENABLE TRIGGER ALL;

--
-- Data for Name: authentication_systems; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.authentication_systems DISABLE TRIGGER ALL;

INSERT INTO public.authentication_systems (id, name, description, type, enabled, priority, internal_private_key, internal_public_key, external_public_key, external_sign_in_url, send_email, send_org_id, send_login, shortcut_sign_in_enabled, created_at, updated_at, external_sign_out_url, sign_up_email_match) VALUES ('password', 'leihs password', NULL, 'password', true, 0, NULL, NULL, NULL, NULL, true, false, false, false, '2020-11-05 13:50:39.546594+01', '2020-11-05 13:50:39.546594+01', NULL, NULL);


ALTER TABLE public.authentication_systems ENABLE TRIGGER ALL;

--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.groups DISABLE TRIGGER ALL;

INSERT INTO public.groups (id, name, description, org_id, searchable, created_at, updated_at, admin_protected, system_admin_protected, organization) VALUES ('4dd87663-f731-5766-b97d-9494889ca66c', 'All users', NULL, 'all-users', 'All users all-users', '2021-03-08 11:02:51.767533+01', '2021-03-08 11:02:51.779113+01', true, true, 'leihs-core');


ALTER TABLE public.groups ENABLE TRIGGER ALL;

--
-- Data for Name: authentication_systems_groups; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.authentication_systems_groups DISABLE TRIGGER ALL;



ALTER TABLE public.authentication_systems_groups ENABLE TRIGGER ALL;

--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.languages DISABLE TRIGGER ALL;

INSERT INTO public.languages (name, locale, "default", active) VALUES ('English (UK)', 'en-GB', true, true);
INSERT INTO public.languages (name, locale, "default", active) VALUES ('English (US)', 'en-US', false, true);
INSERT INTO public.languages (name, locale, "default", active) VALUES ('Deutsch', 'de-CH', false, true);
INSERT INTO public.languages (name, locale, "default", active) VALUES ('Züritüütsch', 'gsw-CH', false, true);


ALTER TABLE public.languages ENABLE TRIGGER ALL;

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.users DISABLE TRIGGER ALL;



ALTER TABLE public.users ENABLE TRIGGER ALL;

--
-- Data for Name: authentication_systems_users; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.authentication_systems_users DISABLE TRIGGER ALL;



ALTER TABLE public.authentication_systems_users ENABLE TRIGGER ALL;

--
-- Data for Name: contracts; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.contracts DISABLE TRIGGER ALL;



ALTER TABLE public.contracts ENABLE TRIGGER ALL;

--
-- Data for Name: customer_orders; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.customer_orders DISABLE TRIGGER ALL;



ALTER TABLE public.customer_orders ENABLE TRIGGER ALL;

--
-- Data for Name: delegations_direct_users; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.delegations_direct_users DISABLE TRIGGER ALL;



ALTER TABLE public.delegations_direct_users ENABLE TRIGGER ALL;

--
-- Data for Name: delegations_groups; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.delegations_groups DISABLE TRIGGER ALL;



ALTER TABLE public.delegations_groups ENABLE TRIGGER ALL;

--
-- Data for Name: direct_access_rights; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.direct_access_rights DISABLE TRIGGER ALL;



ALTER TABLE public.direct_access_rights ENABLE TRIGGER ALL;

--
-- Data for Name: fields; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.fields DISABLE TRIGGER ALL;

INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('inventory_code', true, 1, '{"type": "text", "group": null, "label": "Inventory Code", "required": true, "attribute": "inventory_code", "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('model_id', true, 2, '{"type": "autocomplete-search", "group": null, "label": "Model", "required": true, "attribute": ["model", "id"], "form_name": "model_id", "value_attr": "id", "search_attr": "search_term", "search_path": "models", "target_type": "item", "display_attr": "product", "display_attr_ext": "version", "item_value_label": ["model", "product"], "item_value_label_ext": ["model", "version"]}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('license_version', true, 3, '{"type": "text", "group": null, "label": "License Version", "attribute": ["item_version"], "permissions": {"role": "inventory_manager", "owner": "true"}, "target_type": "license"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('software_model_id', true, 3, '{"type": "autocomplete-search", "group": null, "label": "Software", "required": true, "attribute": ["model", "id"], "form_name": "model_id", "value_attr": "id", "search_attr": "search_term", "search_path": "software", "target_type": "license", "display_attr": "product", "display_attr_ext": "version", "item_value_label": ["model", "product"], "item_value_label_ext": ["model", "version"]}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('serial_number', true, 4, '{"type": "text", "group": "General Information", "label": "Serial Number", "attribute": "serial_number", "permissions": {"role": "lending_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_mac_address', true, 5, '{"type": "text", "group": "General Information", "label": "MAC-Address", "attribute": ["properties", "mac_address"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_imei_number', true, 6, '{"type": "text", "group": "General Information", "label": "IMEI-Number", "attribute": ["properties", "imei_number"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('name', true, 7, '{"type": "text", "group": "General Information", "label": "Name", "attribute": "name", "forPackage": true, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('note', true, 8, '{"type": "textarea", "group": "General Information", "label": "Note", "attribute": "note", "forPackage": true}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('retired', true, 9, '{"type": "select", "group": "Status", "label": "Retirement", "values": [{"label": "No", "value": false}, {"label": "Yes", "value": true}], "default": false, "attribute": "retired", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('retired_reason', true, 10, '{"type": "textarea", "group": "Status", "label": "Reason for Retirement", "required": true, "attribute": "retired_reason", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}, "visibility_dependency_value": "true", "visibility_dependency_field_id": "retired"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('is_broken', true, 11, '{"type": "radio", "group": "Status", "label": "Working order", "values": [{"label": "OK", "value": false}, {"label": "Broken", "value": true}], "default": false, "attribute": "is_broken", "forPackage": true, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('is_incomplete', true, 12, '{"type": "radio", "group": "Status", "label": "Completeness", "values": [{"label": "OK", "value": false}, {"label": "Incomplete", "value": true}], "default": false, "attribute": "is_incomplete", "forPackage": true, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('is_borrowable', true, 13, '{"type": "radio", "group": "Status", "label": "Borrowable", "values": [{"label": "OK", "value": true}, {"label": "Unborrowable", "value": false}], "default": false, "attribute": "is_borrowable", "forPackage": true}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('status_note', true, 14, '{"type": "textarea", "group": "Status", "label": "Status note", "attribute": "status_note", "forPackage": true, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('building_id', true, 15, '{"type": "autocomplete", "group": "Location", "label": "Building", "values": "all_buildings", "required": true, "attribute": ["room", "building_id"], "forPackage": true, "target_type": "item", "exclude_from_submit": true}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('room_id', true, 16, '{"type": "autocomplete", "group": "Location", "label": "Room", "required": true, "attribute": "room_id", "forPackage": true, "values_url": "/manage/rooms.json?building_id=$$$parent_value$$$", "target_type": "item", "values_label_method": "to_s", "values_dependency_field_id": "building_id"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('shelf', true, 17, '{"type": "text", "group": "Location", "label": "Shelf", "attribute": "shelf", "forPackage": true, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('is_inventory_relevant', true, 18, '{"type": "select", "group": "Inventory", "label": "Relevant for inventory", "values": [{"label": "No", "value": false}, {"label": "Yes", "value": true}], "default": true, "attribute": "is_inventory_relevant", "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('owner_id', true, 19, '{"type": "autocomplete", "group": "Inventory", "label": "Owner", "values": "all_inventory_pools", "attribute": ["owner", "id"], "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('last_check', true, 20, '{"type": "date", "group": "Inventory", "label": "Last Checked", "default": "today", "attribute": "last_check", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('inventory_pool_id', true, 21, '{"type": "autocomplete", "group": "Inventory", "label": "Responsible department", "values": "all_inventory_pools", "attribute": ["inventory_pool", "id"], "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('responsible', true, 22, '{"type": "text", "group": "Inventory", "label": "Responsible person", "attribute": "responsible", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('user_name', true, 23, '{"type": "text", "group": "Inventory", "label": "User/Typical usage", "attribute": "user_name", "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_reference', true, 24, '{"type": "radio", "group": "Invoice Information", "label": "Reference", "values": [{"label": "Running Account", "value": "invoice"}, {"label": "Investment", "value": "investment"}], "default": "invoice", "required": true, "attribute": ["properties", "reference"], "permissions": {"role": "inventory_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_project_number', true, 25, '{"type": "text", "group": "Invoice Information", "label": "Project Number", "required": true, "attribute": ["properties", "project_number"], "permissions": {"role": "inventory_manager", "owner": true}, "visibility_dependency_value": "investment", "visibility_dependency_field_id": "properties_reference"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('invoice_number', true, 26, '{"type": "text", "group": "Invoice Information", "label": "Invoice Number", "attribute": "invoice_number", "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('invoice_date', true, 27, '{"type": "date", "group": "Invoice Information", "label": "Invoice Date", "attribute": "invoice_date", "permissions": {"role": "lending_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('price', true, 28, '{"type": "text", "group": "Invoice Information", "label": "Initial Price", "currency": true, "attribute": "price", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('supplier_id', true, 29, '{"type": "autocomplete", "group": "Invoice Information", "label": "Supplier", "values": "all_suppliers", "attribute": ["supplier", "id"], "extensible": true, "permissions": {"role": "lending_manager", "owner": true}, "extended_key": ["supplier", "name"]}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_warranty_expiration', true, 30, '{"type": "date", "group": "Invoice Information", "label": "Warranty expiration", "attribute": ["properties", "warranty_expiration"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_contract_expiration', true, 31, '{"type": "date", "group": "Invoice Information", "label": "Contract expiration", "attribute": ["properties", "contract_expiration"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_activation_type', true, 32, '{"type": "select", "group": "General Information", "label": "Activation Type", "values": [{"label": "None", "value": "none"}, {"label": "Dongle", "value": "dongle"}, {"label": "Serial Number", "value": "serial_number"}, {"label": "License Server", "value": "license_server"}, {"label": "Challenge Response/System ID", "value": "challenge_response"}], "default": "none", "attribute": ["properties", "activation_type"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_dongle_id', true, 33, '{"type": "text", "group": "General Information", "label": "Dongle ID", "required": true, "attribute": ["properties", "dongle_id"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_value": "dongle", "visibility_dependency_field_id": "properties_activation_type"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_license_type', true, 34, '{"type": "select", "group": "General Information", "label": "License Type", "values": [{"label": "Free", "value": "free"}, {"label": "Single Workplace", "value": "single_workplace"}, {"label": "Multiple Workplace", "value": "multiple_workplace"}, {"label": "Site License", "value": "site_license"}, {"label": "Concurrent", "value": "concurrent"}], "default": "free", "attribute": ["properties", "license_type"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_total_quantity', true, 35, '{"type": "text", "group": "General Information", "label": "Total quantity", "attribute": ["properties", "total_quantity"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_quantity_allocations', true, 36, '{"type": "composite", "group": "General Information", "label": "Quantity allocations", "attribute": ["properties", "quantity_allocations"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "data_dependency_field_id": "properties_total_quantity", "visibility_dependency_field_id": "properties_total_quantity"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_operating_system', true, 37, '{"type": "checkbox", "group": "General Information", "label": "Operating System", "values": [{"label": "Windows", "value": "windows"}, {"label": "Mac OS X", "value": "mac_os_x"}, {"label": "Linux", "value": "linux"}, {"label": "iOS", "value": "ios"}], "attribute": ["properties", "operating_system"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_installation', true, 38, '{"type": "checkbox", "group": "General Information", "label": "Installation", "values": [{"label": "Citrix", "value": "citrix"}, {"label": "Local", "value": "local"}, {"label": "Web", "value": "web"}], "attribute": ["properties", "installation"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_license_expiration', true, 39, '{"type": "date", "group": "General Information", "label": "License expiration", "attribute": ["properties", "license_expiration"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_maintenance_contract', true, 40, '{"type": "select", "group": "Maintenance", "label": "Maintenance contract", "values": [{"label": "No", "value": "false"}, {"label": "Yes", "value": "true"}], "default": "false", "attribute": ["properties", "maintenance_contract"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_maintenance_expiration', true, 41, '{"type": "date", "group": "Maintenance", "label": "Maintenance expiration", "attribute": ["properties", "maintenance_expiration"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_value": "true", "visibility_dependency_field_id": "properties_maintenance_contract"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_maintenance_currency', true, 42, '{"type": "select", "group": "Maintenance", "label": "Currency", "values": "all_currencies", "default": "CHF", "attribute": ["properties", "maintenance_currency"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_field_id": "properties_maintenance_expiration"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_maintenance_price', true, 43, '{"type": "text", "group": "Maintenance", "label": "Price", "currency": true, "attribute": ["properties", "maintenance_price"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_field_id": "properties_maintenance_currency"}', false);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('properties_procured_by', true, 44, '{"type": "text", "group": "Invoice Information", "label": "Procured by", "attribute": ["properties", "procured_by"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}', true);
INSERT INTO public.fields (id, active, "position", data, dynamic) VALUES ('attachments', true, 45, '{"type": "attachment", "group": "General Information", "label": "Attachments", "attribute": "attachments", "permissions": {"role": "lending_manager", "owner": true}}', false);


ALTER TABLE public.fields ENABLE TRIGGER ALL;

--
-- Data for Name: disabled_fields; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.disabled_fields DISABLE TRIGGER ALL;



ALTER TABLE public.disabled_fields ENABLE TRIGGER ALL;

--
-- Data for Name: emails; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.emails DISABLE TRIGGER ALL;



ALTER TABLE public.emails ENABLE TRIGGER ALL;

--
-- Data for Name: entitlement_groups; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.entitlement_groups DISABLE TRIGGER ALL;



ALTER TABLE public.entitlement_groups ENABLE TRIGGER ALL;

--
-- Data for Name: entitlement_groups_direct_users; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.entitlement_groups_direct_users DISABLE TRIGGER ALL;



ALTER TABLE public.entitlement_groups_direct_users ENABLE TRIGGER ALL;

--
-- Data for Name: entitlement_groups_groups; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.entitlement_groups_groups DISABLE TRIGGER ALL;



ALTER TABLE public.entitlement_groups_groups ENABLE TRIGGER ALL;

--
-- Data for Name: entitlements; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.entitlements DISABLE TRIGGER ALL;



ALTER TABLE public.entitlements ENABLE TRIGGER ALL;

--
-- Data for Name: favorite_models; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.favorite_models DISABLE TRIGGER ALL;



ALTER TABLE public.favorite_models ENABLE TRIGGER ALL;

--
-- Data for Name: group_access_rights; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.group_access_rights DISABLE TRIGGER ALL;



ALTER TABLE public.group_access_rights ENABLE TRIGGER ALL;

--
-- Data for Name: groups_users; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.groups_users DISABLE TRIGGER ALL;



ALTER TABLE public.groups_users ENABLE TRIGGER ALL;

--
-- Data for Name: hidden_fields; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.hidden_fields DISABLE TRIGGER ALL;



ALTER TABLE public.hidden_fields ENABLE TRIGGER ALL;

--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.holidays DISABLE TRIGGER ALL;



ALTER TABLE public.holidays ENABLE TRIGGER ALL;

--
-- Data for Name: model_groups; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.model_groups DISABLE TRIGGER ALL;



ALTER TABLE public.model_groups ENABLE TRIGGER ALL;

--
-- Data for Name: inventory_pools_model_groups; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.inventory_pools_model_groups DISABLE TRIGGER ALL;



ALTER TABLE public.inventory_pools_model_groups ENABLE TRIGGER ALL;

--
-- Data for Name: mail_templates; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.mail_templates DISABLE TRIGGER ALL;

INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('91b0fff1-1264-429a-ba5c-a628641bf2b5', NULL, 'reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are overdue or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

Since we did not receive any request for renewal, we consequently demand the return of the items without further delay.

By not returning these items, you are blocking other people''s reservations. This is very unfair to the other clients and to the inventory manager, since you are causing a significant amount of trouble and annoyance.

You might receive an admonishment and be subject to late fees as well as the restriction of borrowing privileges. In case of recurrence you might be barred from the reservation system for up to 6 months.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.66507', '2021-04-21 11:18:46.66507', true, 'user', 'en-GB');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('6d22d1c8-38ad-4be0-8b03-7dada8ee0e03', NULL, 'reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are overdue or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

Since we did not receive any request for renewal, we consequently demand the return of the items without further delay.

By not returning these items, you are blocking other people''s reservations. This is very unfair to the other clients and to the inventory manager, since you are causing a significant amount of trouble and annoyance.

You might receive an admonishment and be subject to late fees as well as the restriction of borrowing privileges. In case of recurrence you might be barred from the reservation system for up to 6 months.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.672173', '2021-04-21 11:18:46.672173', true, 'user', 'en-US');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('872a30d5-b0c9-4100-b915-8d83445191e4', NULL, 'reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are overdue or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

Since we did not receive any request for renewal, we consequently demand the return of the items without further delay.

By not returning these items, you are blocking other people''s reservations. This is very unfair to the other clients and to the inventory manager, since you are causing a significant amount of trouble and annoyance.

You might receive an admonishment and be subject to late fees as well as the restriction of borrowing privileges. In case of recurrence you might be barred from the reservation system for up to 6 months.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.675096', '2021-04-21 11:18:46.675096', true, 'user', 'de-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('1399c847-28bf-4778-9584-2127fd17733d', NULL, 'reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are overdue or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

Since we did not receive any request for renewal, we consequently demand the return of the items without further delay.

By not returning these items, you are blocking other people''s reservations. This is very unfair to the other clients and to the inventory manager, since you are causing a significant amount of trouble and annoyance.

You might receive an admonishment and be subject to late fees as well as the restriction of borrowing privileges. In case of recurrence you might be barred from the reservation system for up to 6 months.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.677886', '2021-04-21 11:18:46.677886', true, 'user', 'gsw-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('a1bb0ddf-e1df-42ad-9dbd-ce6978af3a8e', NULL, 'deadline_soon_reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are due to be returned tomorrow or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

We are just sending you this little reminder because someone else is already waiting for some of these items.

In the interest of all our clients we ask you to observe the return dates.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.681011', '2021-04-21 11:18:46.681011', true, 'user', 'en-GB');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('f305ada7-3a1c-4171-9e7a-27b417978fc4', NULL, 'deadline_soon_reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are due to be returned tomorrow or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

We are just sending you this little reminder because someone else is already waiting for some of these items.

In the interest of all our clients we ask you to observe the return dates.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.683518', '2021-04-21 11:18:46.683518', true, 'user', 'en-US');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('8cf51778-26ac-4cae-af42-2c769b95b639', NULL, 'deadline_soon_reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are due to be returned tomorrow or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

We are just sending you this little reminder because someone else is already waiting for some of these items.

In the interest of all our clients we ask you to observe the return dates.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.685905', '2021-04-21 11:18:46.685905', true, 'user', 'de-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('29f61894-ffa8-41d1-a3f4-031448e25c89', NULL, 'deadline_soon_reminder', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

The following items are due to be returned tomorrow or need to be inspected:

{{ quantity }} item(s) due on {{ due_date | date: ''%d/%m/%Y'' }} at the inventory pool {{ inventory_pool.name }}
{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }} ({{ l.item_inventory_code }}), {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

== Are any of the above items your personal computer?

We kindly ask you to contact us as soon as possible. Your computer might need an update.

== "Are any of the above borrowed items?

We are just sending you this little reminder because someone else is already waiting for some of these items.

In the interest of all our clients we ask you to observe the return dates.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.688424', '2021-04-21 11:18:46.688424', true, 'user', 'gsw-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('98757b9e-9891-4363-b74f-3a2110931195', NULL, 'received', 'text', 'Dear leihs manager,

** This is an automatically generated response **

An order for the following items listed below was received in an inventory pool you are responsible for.

Inventory pool: {{ inventory_pool.name }}
User: {{ user.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

This order is still pending. Please log in to your leihs system and either approve or reject it.

The user who placed this order has received a similar e-mail message informing them that the order first needs to be approved before it is valid.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.691262', '2021-04-21 11:18:46.691262', true, 'order', 'en-GB');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('2865004b-00b4-4815-a4f6-4f39c48617bf', NULL, 'received', 'text', 'Dear leihs manager,

** This is an automatically generated response **

An order for the following items listed below was received in an inventory pool you are responsible for.

Inventory pool: {{ inventory_pool.name }}
User: {{ user.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

This order is still pending. Please log in to your leihs system and either approve or reject it.

The user who placed this order has received a similar e-mail message informing them that the order first needs to be approved before it is valid.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.69381', '2021-04-21 11:18:46.69381', true, 'order', 'en-US');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('00f6c4fa-9d85-4736-a51b-54a890d0d492', NULL, 'received', 'text', 'Dear leihs manager,

** This is an automatically generated response **

An order for the following items listed below was received in an inventory pool you are responsible for.

Inventory pool: {{ inventory_pool.name }}
User: {{ user.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

This order is still pending. Please log in to your leihs system and either approve or reject it.

The user who placed this order has received a similar e-mail message informing them that the order first needs to be approved before it is valid.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.696546', '2021-04-21 11:18:46.696546', true, 'order', 'de-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('01841af3-fc44-4b43-8e44-f9b8edbf1c42', NULL, 'received', 'text', 'Dear leihs manager,

** This is an automatically generated response **

An order for the following items listed below was received in an inventory pool you are responsible for.

Inventory pool: {{ inventory_pool.name }}
User: {{ user.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

This order is still pending. Please log in to your leihs system and either approve or reject it.

The user who placed this order has received a similar e-mail message informing them that the order first needs to be approved before it is valid.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.699276', '2021-04-21 11:18:46.699276', true, 'order', 'gsw-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('17570c6d-5888-409f-bfbb-49d667fb7dda', NULL, 'submitted', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items listed below was successfully submitted.

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

Unfortunately your order is still pending, but you will soon receive a confirmation of order by separate e-mail. You can view the status of your order through your leihs account.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.702694', '2021-04-21 11:18:46.702694', true, 'order', 'en-GB');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('5f75b6d3-60dd-4693-bff1-a055282b11b1', NULL, 'submitted', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items listed below was successfully submitted.

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

Unfortunately your order is still pending, but you will soon receive a confirmation of order by separate e-mail. You can view the status of your order through your leihs account.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.705521', '2021-04-21 11:18:46.705521', true, 'order', 'en-US');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('09a59f8c-97ad-4b66-9b82-da9423822046', NULL, 'submitted', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items listed below was successfully submitted.

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

Unfortunately your order is still pending, but you will soon receive a confirmation of order by separate e-mail. You can view the status of your order through your leihs account.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.708533', '2021-04-21 11:18:46.708533', true, 'order', 'de-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('96f1bfd3-fb9e-4489-ac8e-2135c685034d', NULL, 'submitted', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items listed below was successfully submitted.

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

Purpose:
{{ purpose }}

Unfortunately your order is still pending, but you will soon receive a confirmation of order by separate e-mail. You can view the status of your order through your leihs account.

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.711856', '2021-04-21 11:18:46.711856', true, 'order', 'gsw-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('a3248d8a-c153-4573-bb8e-f81238c48542', NULL, 'approved', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items has been confirmed by the inventory manager:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{% if comment %}

These are the comments of the inventory manager:

{{ comment }}

{% endif %}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.716005', '2021-04-21 11:18:46.716005', true, 'order', 'en-GB');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('cc3ca99d-5d08-4816-a7f8-1d464c60e338', NULL, 'approved', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items has been confirmed by the inventory manager:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{% if comment %}

These are the comments of the inventory manager:

{{ comment }}

{% endif %}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.730452', '2021-04-21 11:18:46.730452', true, 'order', 'en-US');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('bc72996d-d639-436d-940a-47c0e60aceec', NULL, 'approved', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items has been confirmed by the inventory manager:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{% if comment %}

These are the comments of the inventory manager:

{{ comment }}

{% endif %}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.733687', '2021-04-21 11:18:46.733687', true, 'order', 'de-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('99d4cb9b-abbf-4629-9c14-31275d8e0c91', NULL, 'approved', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order for the following items has been confirmed by the inventory manager:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{% if comment %}

These are the comments of the inventory manager:

{{ comment }}

{% endif %}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.736548', '2021-04-21 11:18:46.736548', true, 'order', 'gsw-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('6d6ec0f8-eda3-404f-b0dd-a8d9c0f68bd2', NULL, 'rejected', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order was rejected for the following reason:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{{ comment }}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.739877', '2021-04-21 11:18:46.739877', true, 'order', 'en-GB');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('30bed262-6deb-44c0-a8ea-4d5bb4ca3b1f', NULL, 'rejected', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order was rejected for the following reason:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{{ comment }}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.742632', '2021-04-21 11:18:46.742632', true, 'order', 'en-US');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('2b8655ee-a6c9-4468-91f0-7b0268d5506c', NULL, 'rejected', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order was rejected for the following reason:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{{ comment }}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.745393', '2021-04-21 11:18:46.745393', true, 'order', 'de-CH');
INSERT INTO public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) VALUES ('4025675b-11cf-4c00-8515-faa63fcffd90', NULL, 'rejected', 'text', 'Dear {{ user.name }},

** This is an automatically generated response **

Your order was rejected for the following reason:

Inventory pool: {{ inventory_pool.name }}

{% for l in reservations %}
* {{ l.quantity }} {{ l.model_name }}, {{ l.start_date | date: ''%d/%m/%Y'' }} - {{ l.end_date | date: ''%d/%m/%Y'' }}
{% endfor %}

{{ comment }}

Kind regards,

{{ email_signature }}

--
{{ inventory_pool.name }}
{{ inventory_pool.description }}
', '2021-04-21 11:18:46.748278', '2021-04-21 11:18:46.748278', true, 'order', 'gsw-CH');


ALTER TABLE public.mail_templates ENABLE TRIGGER ALL;

--
-- Data for Name: model_group_links; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.model_group_links DISABLE TRIGGER ALL;



ALTER TABLE public.model_group_links ENABLE TRIGGER ALL;

--
-- Data for Name: model_links; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.model_links DISABLE TRIGGER ALL;



ALTER TABLE public.model_links ENABLE TRIGGER ALL;

--
-- Data for Name: models_compatibles; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.models_compatibles DISABLE TRIGGER ALL;



ALTER TABLE public.models_compatibles ENABLE TRIGGER ALL;

--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.notifications DISABLE TRIGGER ALL;



ALTER TABLE public.notifications ENABLE TRIGGER ALL;

--
-- Data for Name: numerators; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.numerators DISABLE TRIGGER ALL;



ALTER TABLE public.numerators ENABLE TRIGGER ALL;

--
-- Data for Name: old_empty_contracts; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.old_empty_contracts DISABLE TRIGGER ALL;



ALTER TABLE public.old_empty_contracts ENABLE TRIGGER ALL;

--
-- Data for Name: options; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.options DISABLE TRIGGER ALL;



ALTER TABLE public.options ENABLE TRIGGER ALL;

--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.orders DISABLE TRIGGER ALL;



ALTER TABLE public.orders ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_admins; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_admins DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_admins ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_budget_periods; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_budget_periods DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_budget_periods ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_main_categories; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_main_categories DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_main_categories ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_categories; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_categories DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_categories ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_organizations; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_organizations DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_organizations ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_templates; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_templates DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_templates ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_requests; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_requests DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_requests ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_attachments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_attachments DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_attachments ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_budget_limits; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_budget_limits DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_budget_limits ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_category_inspectors; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_category_inspectors DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_category_inspectors ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_category_viewers; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_category_viewers DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_category_viewers ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_images; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_images DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_images ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_requesters_organizations; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_requesters_organizations DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_requesters_organizations ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_requests_counters; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_requests_counters DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_requests_counters ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_settings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_settings DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_settings ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_uploads; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_uploads DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_uploads ENABLE TRIGGER ALL;

--
-- Data for Name: procurement_users_filters; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.procurement_users_filters DISABLE TRIGGER ALL;



ALTER TABLE public.procurement_users_filters ENABLE TRIGGER ALL;

--
-- Data for Name: properties; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.properties DISABLE TRIGGER ALL;



ALTER TABLE public.properties ENABLE TRIGGER ALL;

--
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.reservations DISABLE TRIGGER ALL;



ALTER TABLE public.reservations ENABLE TRIGGER ALL;

--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.settings DISABLE TRIGGER ALL;

INSERT INTO public.settings (local_currency_string, contract_lending_party_string, email_signature, deliver_received_order_notifications, user_image_url, ldap_config, logo_url, time_zone, disable_manage_section, disable_manage_section_message, disable_borrow_section, disable_borrow_section_message, text, timeout_minutes, custom_head_tag, documentation_link, id, created_at, updated_at, maximum_reservation_time, lending_terms_acceptance_required_for_order, lending_terms_url, include_customer_email_in_contracts) VALUES ('GBP', NULL, 'Cheers,', false, NULL, NULL, NULL, 'Bern', false, NULL, false, NULL, NULL, 30, NULL, NULL, 0, '2020-11-05 13:50:29.190792+01', '2020-11-05 13:50:29.190792+01', NULL, false, NULL, false);


ALTER TABLE public.settings ENABLE TRIGGER ALL;

--
-- Data for Name: smtp_settings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.smtp_settings DISABLE TRIGGER ALL;

INSERT INTO public.smtp_settings (id, enabled, address, authentication_type, default_from_address, domain, enable_starttls_auto, openssl_verify_mode, password, port, sender_address, username) VALUES (0, false, 'localhost', 'plain', 'your.lending.desk@example.com', 'localhost', false, 'none', NULL, 25, NULL, NULL);


ALTER TABLE public.smtp_settings ENABLE TRIGGER ALL;

--
-- Data for Name: suspensions; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.suspensions DISABLE TRIGGER ALL;



ALTER TABLE public.suspensions ENABLE TRIGGER ALL;

--
-- Data for Name: system_and_security_settings; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.system_and_security_settings DISABLE TRIGGER ALL;

INSERT INTO public.system_and_security_settings (id, accept_server_secret_as_universal_password, external_base_url, sessions_force_secure, sessions_force_uniqueness, sessions_max_lifetime_secs, instance_element) VALUES (0, true, NULL, false, false, 432000, NULL);


ALTER TABLE public.system_and_security_settings ENABLE TRIGGER ALL;

--
-- Data for Name: translations_default; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.translations_default DISABLE TRIGGER ALL;



ALTER TABLE public.translations_default ENABLE TRIGGER ALL;

--
-- Data for Name: translations_instance; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.translations_instance DISABLE TRIGGER ALL;



ALTER TABLE public.translations_instance ENABLE TRIGGER ALL;

--
-- Data for Name: translations_user; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.translations_user DISABLE TRIGGER ALL;



ALTER TABLE public.translations_user ENABLE TRIGGER ALL;

--
-- Data for Name: user_password_resets; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.user_password_resets DISABLE TRIGGER ALL;



ALTER TABLE public.user_password_resets ENABLE TRIGGER ALL;

--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.user_sessions DISABLE TRIGGER ALL;



ALTER TABLE public.user_sessions ENABLE TRIGGER ALL;

--
-- Data for Name: workdays; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.workdays DISABLE TRIGGER ALL;



ALTER TABLE public.workdays ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

