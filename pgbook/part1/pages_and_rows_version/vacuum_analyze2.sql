-- 2
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
UPDATE accounts
SET amount = 0
WHERE id = 4;
--4
select backend_xmin from pg_stat_activity;
--6
commit;