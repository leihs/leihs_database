class FixViewEntitlementsGroupsUsers < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL

      CREATE OR REPLACE FUNCTION entitlement_groups_users_id_agg_f
      (id1 uuid, id2 uuid, user_id uuid, entitlement_group_id uuid)
      RETURNS uuid AS $$
      BEGIN
        IF id1 IS NOT NULL AND id2 IS NOT NULL THEN
          RETURN uuid_generate_v3(uuid_nil(), user_id::TEXT || entitlement_group_id::TEXT);
        ELSIF id1 IS NOT NULL THEN
          RETURN id1;
        ELSE
          RETURN id2;
        END IF;
      END;
      $$ LANGUAGE plpgsql;

    SQL

  end

  def down

  end

end

