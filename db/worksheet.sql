
SELECT users.login, users.email, users.org_id, duplicates.login, duplicates.email, duplicates.org_id
FROM users
JOIN users AS duplicates
  ON (lower(users.login) = lower(duplicates.login) AND users.id <> duplicates.id);


SELECT DISTINCT ON (users.login) users.login, users.email, users.org_id, duplicates.login, duplicates.email, duplicates.org_id
FROM users
JOIN users AS duplicates
  ON (lower(users.login) = lower(duplicates.login) AND users.id <> duplicates.id);

SELECT id FROM users
  WHERE EXISTS
    (SELECT TRUE FROM users as duplicates
      WHERE users.login = duplicates.login AND users.id <> duplicates.id);



SELECT distinct inventory_pools.name, direct_access_rights.role, access_rights.role, firstname, lastname
  FROM users
  JOIN access_rights on access_rights.user_id = users.id
  JOIN direct_access_rights on direct_access_rights.user_id = users.id
  JOIN inventory_pools on direct_access_rights.inventory_pool_id = inventory_pools.id
  WHERE lastname = 'Foo'
  ;
