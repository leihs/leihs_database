class RefactoringAuditedChanges < ActiveRecord::Migration[5.0]
  include ::Leihs::MigrationHelper

  def up

    # the new pkey works similar as in the "simple" version stated in
    # https://stackoverflow.com/questions/44846049/how-to-obtain-primary-key-value-in-trigger-function-if-primary-key-column-name-i
    # NOTE: this does not work for composed pkeys; so far we don't have any and we will likely never have

    add_column :audited_changes, :pkey, :text, index: true

    execute <<-SQL.strip_heredoc

      CREATE OR REPLACE FUNCTION jsonb_changed(jold JSONB, jnew JSONB)
      RETURNS JSONB AS $$
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
      $$ LANGUAGE plpgsql;

      UPDATE audited_changes SET changed = jsonb_changed(before, after);

      -- just use the id; should be correct for the tables thus far audited
      UPDATE audited_changes
      SET pkey = CASE
        WHEN tg_op = 'DELETE' THEN before->>'id'
        WHEN tg_op IN ('INSERT', 'UPDATE') THEN after->>'id'
        END ;

      CREATE OR REPLACE FUNCTION audit_change()
      RETURNS TRIGGER AS $$
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
      $$ LANGUAGE 'plpgsql';

    SQL

    remove_column :audited_changes, :before, :jsonb
    remove_column :audited_changes, :after, :jsonb

    audit_table :contracts
    audit_table :delegations_direct_users
    audit_table :delegations_groups
    audit_table :direct_access_rights
    audit_table :entitlement_groups
    audit_table :entitlement_groups_direct_users
    audit_table :entitlement_groups_groups
    audit_table :group_access_rights
    audit_table :inventory_pools
    audit_table :items
    audit_table :languages
    audit_table :models
    audit_table :orders
    audit_table :reservations
    audit_table :settings
    audit_table :suspensions
    audit_table :system_admin_users

  end
end
