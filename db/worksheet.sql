
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



