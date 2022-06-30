-- REPEATABLE READ
-- no fantom read and repeatable read
--1
BEGIN;
UPDATE accounts SET amount = 200.00 WHERE id = 2;
UPDATE accounts SET amount = 800.00 WHERE id = 3;
INSERT INTO accounts VALUES (4, 'charlie', 100.00);
SELECT * FROM accounts ORDER BY id;
--3
COMMIT;
--------------------------------------------------------------------------
-- serialization error instead of lost-update
--1
SELECT * FROM accounts WHERE client  = 'bob';
BEGIN;
UPDATE accounts SET amount = amount - 100 WHERE id = 3;
--3
COMMIT;
SELECT * FROM accounts WHERE client = 'bob';
-----------------------------------------------------------------------------
-- assuming that some app store amount in memory and after set new
-- value based on stored value
-- 1
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT amount FROM accounts WHERE id = 1;
--3
UPDATE accounts SET amount = 900.00 + 100.00 WHERE id = 1;
--5
COMMIT;
---------------------------------------------------------------------------

-- read skew on repeatable read

--1
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT sum(amount) FROM accounts WHERE client = 'bob';
--3
UPDATE accounts SET amount  = amount - 600.00 WHERE id = 2;
--5
COMMIT;


SELECT  * FROM accounts;