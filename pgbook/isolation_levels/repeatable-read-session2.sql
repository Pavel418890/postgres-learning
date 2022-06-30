--2
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM accounts ORDER BY id;
--4 the same result as expected
SELECT * FROM accounts ORDER BY id;
COMMIT;
---------------------------------------------------------------------------
-- serialization error instead of lost update
--2
BEGIN ISOLATION LEVEL REPEATABLE READ;
UPDATE accounts SET amount  = amount * 1.01
WHERE client IN (
    SELECT client
    FROM accounts
    GROUP BY client
    HAVING sum(amount) >= 1000
    );
--[40001] ERROR: could not serialize access due to concurrent update
ROLLBACK;
-----------------------------------------------------------------------
-- assuming that some app store amount in memory and after set new
-- value based on stored value
-- 2
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT amount FROM accounts WHERE id = 1;
--4
UPDATE accounts SET amount = 900.00 + 100.00 WHERE id = 1;
-- [40001] ERROR: could not serialize access due to concurrent update
ROLLBACK;