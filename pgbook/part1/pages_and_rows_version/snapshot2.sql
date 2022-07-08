-- 2
BEGIN;
INSERT INTO accounts (id, client, amount)
VALUES (2, 'bob', 200.00);
SELECT pg_current_xact_id();
COMMIT;
--3
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT *
FROM pg_current_snapshot();
--6
SELECT ctid, *
FROM accounts;
COMMIT;
SELECT *
FROM accounts;
SELECT *
FROM heap_page('accounts', 0);
