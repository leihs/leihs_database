CREATE VIEW unified_access_rights AS
    SELECT
      id AS id,
      id as direct_access_right_id,
      NULL as group_access_right_id,
      user_id AS user_id,
      inventory_pool_id AS inventory_pool_id,
      role AS role,
      created_at AS created_at,
      updated_at AS updated_at
    FROM direct_access_rights
  UNION
    SELECT
      group_access_rights.id AS id,
      NULL AS direct_access_right_id,
      group_access_rights.id AS group_access_right_id,
      groups_users.user_id as user_id,
      group_access_rights.inventory_pool_id as inventory_pool_id,
      role AS role,
      group_access_rights.created_at AS created_at,
      group_access_rights.updated_at AS updated_at
    FROM group_access_rights
    INNER JOIN groups ON groups.id = group_access_rights.group_id
    INNER JOIN groups_users ON groups_users.group_id = groups.id
