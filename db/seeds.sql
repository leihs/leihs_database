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
-- Data for Name: images; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.images (id, target_id, target_type, content_type, filename, size, parent_id, content, thumbnail, metadata) FROM stdin;
\.


--
-- Data for Name: models; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.models (id, type, manufacturer, product, version, description, internal_description, info_url, rental_price, maintenance_period, is_package, technical_detail, hand_over_note, created_at, updated_at, cover_image_id) FROM stdin;
\.


--
-- Data for Name: accessories; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.accessories (id, model_id, name, quantity) FROM stdin;
\.


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.addresses (id, street, zip_code, city, country_code, latitude, longitude) FROM stdin;
\.


--
-- Data for Name: inventory_pools; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.inventory_pools (id, name, description, contact_details, contract_description, contract_url, logo_url, default_contract_note, shortname, email, color, print_contracts, opening_hours, address_id, automatic_suspension, automatic_suspension_reason, automatic_access, required_purpose, is_active) FROM stdin;
\.


--
-- Data for Name: accessories_inventory_pools; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.accessories_inventory_pools (accessory_id, inventory_pool_id) FROM stdin;
\.


--
-- Data for Name: api_tokens; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.api_tokens (id, user_id, token_hash, token_part, scope_read, scope_write, scope_admin_read, scope_admin_write, description, created_at, updated_at, expires_at, scope_system_admin_read, scope_system_admin_write) FROM stdin;
\.


--
-- Data for Name: buildings; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.buildings (id, name, code) FROM stdin;
abae04c5-d767-425e-acc2-7ce04df645d1	general building	\N
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.rooms (id, name, description, building_id, general) FROM stdin;
b8927fd2-014c-48c2-b095-fa1d5620debe	general room	\N	abae04c5-d767-425e-acc2-7ce04df645d1	t
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.suppliers (id, name, created_at, updated_at, note) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.items (id, inventory_code, serial_number, model_id, supplier_id, owner_id, inventory_pool_id, parent_id, invoice_number, invoice_date, last_check, retired, retired_reason, price, is_broken, is_incomplete, is_borrowable, status_note, needs_permission, is_inventory_relevant, responsible, insurance_number, note, name, user_name, created_at, updated_at, shelf, room_id, properties, item_version) FROM stdin;
\.


--
-- Data for Name: attachments; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.attachments (id, model_id, content_type, filename, size, item_id, content, metadata) FROM stdin;
\.


--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.languages (name, locale, "default", active) FROM stdin;
English (UK)	en-GB	t	t
English (US)	en-US	f	t
Deutsch	de-CH	f	t
Züritüütsch	gsw-CH	f	t
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.users (id, login, firstname, lastname, phone, org_id, email, badge_id, address, city, zip, country, settings, delegator_user_id, created_at, updated_at, account_enabled, password_sign_in_enabled, url, img256_url, img32_url, img_digest, is_admin, extended_info, searchable, secondary_email, language_locale, protected) FROM stdin;
\.


--
-- Data for Name: audited_requests; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.audited_requests (id, txid, user_id, url, method, data, created_at) FROM stdin;
\.


--
-- Data for Name: audited_responses; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.audited_responses (id, txid, status, data, created_at) FROM stdin;
\.


--
-- Data for Name: authentication_systems; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.authentication_systems (id, name, description, type, enabled, priority, internal_private_key, internal_public_key, external_public_key, external_sign_in_url, send_email, send_org_id, send_login, shortcut_sign_in_enabled, created_at, updated_at, external_sign_out_url, sign_up_email_match) FROM stdin;
password	leihs password	\N	password	t	0	\N	\N	\N	\N	t	f	f	f	2020-11-05 13:50:39.546594+01	2020-11-05 13:50:39.546594+01	\N	\N
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.groups (id, name, description, org_id, searchable, created_at, updated_at, protected) FROM stdin;
\.


--
-- Data for Name: authentication_systems_groups; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.authentication_systems_groups (id, group_id, authentication_system_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: authentication_systems_users; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.authentication_systems_users (id, user_id, data, authentication_system_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contracts; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.contracts (id, compact_id, note, created_at, updated_at, state, user_id, inventory_pool_id, purpose) FROM stdin;
\.


--
-- Data for Name: customer_orders; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.customer_orders (id, user_id, purpose, created_at, updated_at, title) FROM stdin;
\.


--
-- Data for Name: delegations_direct_users; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.delegations_direct_users (delegation_id, user_id, id) FROM stdin;
\.


--
-- Data for Name: delegations_groups; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.delegations_groups (id, group_id, delegation_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: direct_access_rights; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.direct_access_rights (id, user_id, inventory_pool_id, created_at, updated_at, role) FROM stdin;
\.


--
-- Data for Name: fields; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.fields (id, active, "position", data, dynamic) FROM stdin;
inventory_code	t	1	{"type": "text", "group": null, "label": "Inventory Code", "required": true, "attribute": "inventory_code", "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}}	f
model_id	t	2	{"type": "autocomplete-search", "group": null, "label": "Model", "required": true, "attribute": ["model", "id"], "form_name": "model_id", "value_attr": "id", "search_attr": "search_term", "search_path": "models", "target_type": "item", "display_attr": "product", "display_attr_ext": "version", "item_value_label": ["model", "product"], "item_value_label_ext": ["model", "version"]}	f
license_version	t	3	{"type": "text", "group": null, "label": "License Version", "attribute": ["item_version"], "permissions": {"role": "inventory_manager", "owner": "true"}, "target_type": "license"}	f
software_model_id	t	3	{"type": "autocomplete-search", "group": null, "label": "Software", "required": true, "attribute": ["model", "id"], "form_name": "model_id", "value_attr": "id", "search_attr": "search_term", "search_path": "software", "target_type": "license", "display_attr": "product", "display_attr_ext": "version", "item_value_label": ["model", "product"], "item_value_label_ext": ["model", "version"]}	f
serial_number	t	4	{"type": "text", "group": "General Information", "label": "Serial Number", "attribute": "serial_number", "permissions": {"role": "lending_manager", "owner": true}}	f
properties_mac_address	t	5	{"type": "text", "group": "General Information", "label": "MAC-Address", "attribute": ["properties", "mac_address"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}	t
properties_imei_number	t	6	{"type": "text", "group": "General Information", "label": "IMEI-Number", "attribute": ["properties", "imei_number"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}	t
name	t	7	{"type": "text", "group": "General Information", "label": "Name", "attribute": "name", "forPackage": true, "target_type": "item"}	f
note	t	8	{"type": "textarea", "group": "General Information", "label": "Note", "attribute": "note", "forPackage": true}	f
retired	t	9	{"type": "select", "group": "Status", "label": "Retirement", "values": [{"label": "No", "value": false}, {"label": "Yes", "value": true}], "default": false, "attribute": "retired", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}}	f
retired_reason	t	10	{"type": "textarea", "group": "Status", "label": "Reason for Retirement", "required": true, "attribute": "retired_reason", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}, "visibility_dependency_value": "true", "visibility_dependency_field_id": "retired"}	f
is_broken	t	11	{"type": "radio", "group": "Status", "label": "Working order", "values": [{"label": "OK", "value": false}, {"label": "Broken", "value": true}], "default": false, "attribute": "is_broken", "forPackage": true, "target_type": "item"}	f
is_incomplete	t	12	{"type": "radio", "group": "Status", "label": "Completeness", "values": [{"label": "OK", "value": false}, {"label": "Incomplete", "value": true}], "default": false, "attribute": "is_incomplete", "forPackage": true, "target_type": "item"}	f
is_borrowable	t	13	{"type": "radio", "group": "Status", "label": "Borrowable", "values": [{"label": "OK", "value": true}, {"label": "Unborrowable", "value": false}], "default": false, "attribute": "is_borrowable", "forPackage": true}	f
status_note	t	14	{"type": "textarea", "group": "Status", "label": "Status note", "attribute": "status_note", "forPackage": true, "target_type": "item"}	f
building_id	t	15	{"type": "autocomplete", "group": "Location", "label": "Building", "values": "all_buildings", "required": true, "attribute": ["room", "building_id"], "forPackage": true, "target_type": "item", "exclude_from_submit": true}	f
room_id	t	16	{"type": "autocomplete", "group": "Location", "label": "Room", "required": true, "attribute": "room_id", "forPackage": true, "values_url": "/manage/rooms.json?building_id=$$$parent_value$$$", "target_type": "item", "values_label_method": "to_s", "values_dependency_field_id": "building_id"}	f
shelf	t	17	{"type": "text", "group": "Location", "label": "Shelf", "attribute": "shelf", "forPackage": true, "target_type": "item"}	f
is_inventory_relevant	t	18	{"type": "select", "group": "Inventory", "label": "Relevant for inventory", "values": [{"label": "No", "value": false}, {"label": "Yes", "value": true}], "default": true, "attribute": "is_inventory_relevant", "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "item"}	f
owner_id	t	19	{"type": "autocomplete", "group": "Inventory", "label": "Owner", "values": "all_inventory_pools", "attribute": ["owner", "id"], "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}}	f
last_check	t	20	{"type": "date", "group": "Inventory", "label": "Last Checked", "default": "today", "attribute": "last_check", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}	f
inventory_pool_id	t	21	{"type": "autocomplete", "group": "Inventory", "label": "Responsible department", "values": "all_inventory_pools", "attribute": ["inventory_pool", "id"], "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}}	f
responsible	t	22	{"type": "text", "group": "Inventory", "label": "Responsible person", "attribute": "responsible", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}	f
user_name	t	23	{"type": "text", "group": "Inventory", "label": "User/Typical usage", "attribute": "user_name", "forPackage": true, "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "item"}	f
properties_reference	t	24	{"type": "radio", "group": "Invoice Information", "label": "Reference", "values": [{"label": "Running Account", "value": "invoice"}, {"label": "Investment", "value": "investment"}], "default": "invoice", "required": true, "attribute": ["properties", "reference"], "permissions": {"role": "inventory_manager", "owner": true}}	f
properties_project_number	t	25	{"type": "text", "group": "Invoice Information", "label": "Project Number", "required": true, "attribute": ["properties", "project_number"], "permissions": {"role": "inventory_manager", "owner": true}, "visibility_dependency_value": "investment", "visibility_dependency_field_id": "properties_reference"}	f
invoice_number	t	26	{"type": "text", "group": "Invoice Information", "label": "Invoice Number", "attribute": "invoice_number", "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}	f
invoice_date	t	27	{"type": "date", "group": "Invoice Information", "label": "Invoice Date", "attribute": "invoice_date", "permissions": {"role": "lending_manager", "owner": true}}	f
price	t	28	{"type": "text", "group": "Invoice Information", "label": "Initial Price", "currency": true, "attribute": "price", "forPackage": true, "permissions": {"role": "lending_manager", "owner": true}}	f
supplier_id	t	29	{"type": "autocomplete", "group": "Invoice Information", "label": "Supplier", "values": "all_suppliers", "attribute": ["supplier", "id"], "extensible": true, "permissions": {"role": "lending_manager", "owner": true}, "extended_key": ["supplier", "name"]}	f
properties_warranty_expiration	t	30	{"type": "date", "group": "Invoice Information", "label": "Warranty expiration", "attribute": ["properties", "warranty_expiration"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}	t
properties_contract_expiration	t	31	{"type": "date", "group": "Invoice Information", "label": "Contract expiration", "attribute": ["properties", "contract_expiration"], "permissions": {"role": "lending_manager", "owner": true}, "target_type": "item"}	t
properties_activation_type	t	32	{"type": "select", "group": "General Information", "label": "Activation Type", "values": [{"label": "None", "value": "none"}, {"label": "Dongle", "value": "dongle"}, {"label": "Serial Number", "value": "serial_number"}, {"label": "License Server", "value": "license_server"}, {"label": "Challenge Response/System ID", "value": "challenge_response"}], "default": "none", "attribute": ["properties", "activation_type"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
properties_dongle_id	t	33	{"type": "text", "group": "General Information", "label": "Dongle ID", "required": true, "attribute": ["properties", "dongle_id"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_value": "dongle", "visibility_dependency_field_id": "properties_activation_type"}	f
properties_license_type	t	34	{"type": "select", "group": "General Information", "label": "License Type", "values": [{"label": "Free", "value": "free"}, {"label": "Single Workplace", "value": "single_workplace"}, {"label": "Multiple Workplace", "value": "multiple_workplace"}, {"label": "Site License", "value": "site_license"}, {"label": "Concurrent", "value": "concurrent"}], "default": "free", "attribute": ["properties", "license_type"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
properties_total_quantity	t	35	{"type": "text", "group": "General Information", "label": "Total quantity", "attribute": ["properties", "total_quantity"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
properties_quantity_allocations	t	36	{"type": "composite", "group": "General Information", "label": "Quantity allocations", "attribute": ["properties", "quantity_allocations"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "data_dependency_field_id": "properties_total_quantity", "visibility_dependency_field_id": "properties_total_quantity"}	f
properties_operating_system	t	37	{"type": "checkbox", "group": "General Information", "label": "Operating System", "values": [{"label": "Windows", "value": "windows"}, {"label": "Mac OS X", "value": "mac_os_x"}, {"label": "Linux", "value": "linux"}, {"label": "iOS", "value": "ios"}], "attribute": ["properties", "operating_system"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
properties_installation	t	38	{"type": "checkbox", "group": "General Information", "label": "Installation", "values": [{"label": "Citrix", "value": "citrix"}, {"label": "Local", "value": "local"}, {"label": "Web", "value": "web"}], "attribute": ["properties", "installation"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
properties_license_expiration	t	39	{"type": "date", "group": "General Information", "label": "License expiration", "attribute": ["properties", "license_expiration"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
properties_maintenance_contract	t	40	{"type": "select", "group": "Maintenance", "label": "Maintenance contract", "values": [{"label": "No", "value": "false"}, {"label": "Yes", "value": "true"}], "default": "false", "attribute": ["properties", "maintenance_contract"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
properties_maintenance_expiration	t	41	{"type": "date", "group": "Maintenance", "label": "Maintenance expiration", "attribute": ["properties", "maintenance_expiration"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_value": "true", "visibility_dependency_field_id": "properties_maintenance_contract"}	f
properties_maintenance_currency	t	42	{"type": "select", "group": "Maintenance", "label": "Currency", "values": "all_currencies", "default": "CHF", "attribute": ["properties", "maintenance_currency"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_field_id": "properties_maintenance_expiration"}	f
properties_maintenance_price	t	43	{"type": "text", "group": "Maintenance", "label": "Price", "currency": true, "attribute": ["properties", "maintenance_price"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license", "visibility_dependency_field_id": "properties_maintenance_currency"}	f
properties_procured_by	t	44	{"type": "text", "group": "Invoice Information", "label": "Procured by", "attribute": ["properties", "procured_by"], "permissions": {"role": "inventory_manager", "owner": true}, "target_type": "license"}	t
attachments	t	45	{"type": "attachment", "group": "General Information", "label": "Attachments", "attribute": "attachments", "permissions": {"role": "lending_manager", "owner": true}}	f
\.


--
-- Data for Name: disabled_fields; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.disabled_fields (id, field_id, inventory_pool_id) FROM stdin;
\.


--
-- Data for Name: emails; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.emails (id, user_id, subject, body, from_address, trials, code, error, message, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: entitlement_groups; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.entitlement_groups (id, name, inventory_pool_id, is_verification_required, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: entitlement_groups_direct_users; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.entitlement_groups_direct_users (user_id, entitlement_group_id, id) FROM stdin;
\.


--
-- Data for Name: entitlement_groups_groups; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.entitlement_groups_groups (id, group_id, entitlement_group_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: entitlements; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.entitlements (id, model_id, entitlement_group_id, quantity, "position") FROM stdin;
\.


--
-- Data for Name: favorite_models; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.favorite_models (user_id, model_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: group_access_rights; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.group_access_rights (id, group_id, inventory_pool_id, role, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: groups_users; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.groups_users (id, user_id, group_id, created_at) FROM stdin;
\.


--
-- Data for Name: hidden_fields; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.hidden_fields (id, field_id, user_id) FROM stdin;
\.


--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.holidays (id, inventory_pool_id, start_date, end_date, name) FROM stdin;
\.


--
-- Data for Name: model_groups; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.model_groups (id, type, name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: inventory_pools_model_groups; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.inventory_pools_model_groups (inventory_pool_id, model_group_id) FROM stdin;
\.


--
-- Data for Name: mail_templates; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.mail_templates (id, inventory_pool_id, name, format, body, created_at, updated_at, is_template_template, type, language_locale) FROM stdin;
\.


--
-- Data for Name: model_group_links; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.model_group_links (id, parent_id, child_id, label) FROM stdin;
\.


--
-- Data for Name: model_links; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.model_links (id, model_group_id, model_id, quantity) FROM stdin;
\.


--
-- Data for Name: models_compatibles; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.models_compatibles (model_id, compatible_id) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.notifications (id, user_id, title, created_at) FROM stdin;
\.


--
-- Data for Name: numerators; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.numerators (id, item) FROM stdin;
\.


--
-- Data for Name: old_empty_contracts; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.old_empty_contracts (id, compact_id, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: options; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.options (id, inventory_pool_id, inventory_code, manufacturer, product, version, price) FROM stdin;
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.orders (id, user_id, inventory_pool_id, purpose, state, created_at, updated_at, reject_reason, customer_order_id) FROM stdin;
\.


--
-- Data for Name: procurement_admins; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_admins (user_id) FROM stdin;
\.


--
-- Data for Name: procurement_budget_periods; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_budget_periods (id, name, inspection_start_date, end_date, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: procurement_main_categories; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_main_categories (id, name) FROM stdin;
\.


--
-- Data for Name: procurement_categories; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_categories (id, name, main_category_id, general_ledger_account, cost_center, procurement_account) FROM stdin;
\.


--
-- Data for Name: procurement_organizations; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_organizations (id, name, shortname, parent_id) FROM stdin;
\.


--
-- Data for Name: procurement_templates; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_templates (id, model_id, supplier_id, article_name, article_number, price_cents, price_currency, supplier_name, category_id) FROM stdin;
\.


--
-- Data for Name: procurement_requests; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_requests (id, budget_period_id, category_id, user_id, organization_id, model_id, supplier_id, template_id, article_name, article_number, requested_quantity, approved_quantity, order_quantity, price_cents, price_currency, priority, replacement, supplier_name, receiver, motivation, inspection_comment, created_at, inspector_priority, room_id, updated_at, accounting_type, internal_order_number, short_id) FROM stdin;
\.


--
-- Data for Name: procurement_attachments; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_attachments (id, request_id, filename, content_type, size, content, metadata, exiftool_version, exiftool_options) FROM stdin;
\.


--
-- Data for Name: procurement_budget_limits; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_budget_limits (id, budget_period_id, main_category_id, amount_cents, amount_currency) FROM stdin;
\.


--
-- Data for Name: procurement_category_inspectors; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_category_inspectors (id, user_id, category_id) FROM stdin;
\.


--
-- Data for Name: procurement_category_viewers; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_category_viewers (id, user_id, category_id) FROM stdin;
\.


--
-- Data for Name: procurement_images; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_images (id, main_category_id, content_type, content, filename, size, metadata, exiftool_version, exiftool_options) FROM stdin;
\.


--
-- Data for Name: procurement_requesters_organizations; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_requesters_organizations (id, user_id, organization_id) FROM stdin;
\.


--
-- Data for Name: procurement_requests_counters; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_requests_counters (id, prefix, counter, created_by_budget_period_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: procurement_settings; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_settings (id, created_at, updated_at, contact_url, inspection_comments) FROM stdin;
\.


--
-- Data for Name: procurement_uploads; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_uploads (id, filename, content_type, size, content, metadata, created_at, exiftool_version, exiftool_options) FROM stdin;
\.


--
-- Data for Name: procurement_users_filters; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.procurement_users_filters (id, user_id, filter) FROM stdin;
\.


--
-- Data for Name: properties; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.properties (id, model_id, key, value) FROM stdin;
\.


--
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.reservations (id, contract_id, inventory_pool_id, user_id, delegated_user_id, handed_over_by_user_id, type, status, item_id, model_id, quantity, start_date, end_date, returned_date, option_id, returned_to_user_id, created_at, updated_at, order_id, line_purpose) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.settings (smtp_address, smtp_port, smtp_domain, local_currency_string, contract_terms, contract_lending_party_string, email_signature, default_email, deliver_received_order_notifications, user_image_url, ldap_config, logo_url, mail_delivery_method, smtp_username, smtp_password, smtp_enable_starttls_auto, smtp_openssl_verify_mode, time_zone, disable_manage_section, disable_manage_section_message, disable_borrow_section, disable_borrow_section_message, text, timeout_minutes, external_base_url, custom_head_tag, sessions_max_lifetime_secs, sessions_force_uniqueness, sessions_force_secure, documentation_link, id, accept_server_secret_as_universal_password, created_at, updated_at, maximum_reservation_time, smtp_sender_address, smtp_default_from_address, smtp_authentication_type) FROM stdin;
localhost	25	localhost	GBP	\N	\N	Cheers,	your.lending.desk@example.com	f	\N	\N	\N	test	\N	\N	f	none	Bern	f	\N	f	\N	\N	30	\N	\N	432000	t	f	\N	0	t	2020-11-05 13:50:29.190792+01	2020-11-05 13:50:29.190792+01	\N	\N	noreply@example.com	plain
\.


--
-- Data for Name: suspensions; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.suspensions (id, user_id, inventory_pool_id, suspended_until, suspended_reason, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_admin_users; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.system_admin_users (user_id) FROM stdin;
\.


--
-- Data for Name: user_password_resets; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.user_password_resets (id, user_id, used_user_param, token, valid_until, created_at) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.user_sessions (id, token_hash, user_id, delegation_id, created_at, meta_data, authentication_system_id) FROM stdin;
\.


--
-- Data for Name: workdays; Type: TABLE DATA; Schema: public; Owner: thomas
--

COPY public.workdays (id, inventory_pool_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, reservation_advance_days, max_visits) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

