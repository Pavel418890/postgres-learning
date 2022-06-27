--3 another session
BEGIN;
SELECT amount FROM accounts WHERE client = 'alice';
-- 5
SELECT amount FROM accounts WHERE client = 'alice';
-- VALUE HAS CHANGED --> NON REPEATABLE READ
COMMIT;

---------------------------------------------------
--2
BEGIN;
SELECT amount FROM accounts WHERE id = 2;
--4
SELECT amount FROM accounts WHERE id = 3;
-- read committed value from first transaction (in sum bob amount = 1100)
-- but total amount for bob accounts 1000 --> read skew
-- for that operation need only 1 operator
COMMIT;


--2 change behaviour and fix read skew
BEGIN;
SELECT sum(amount) FROM accounts WHERE client = 'bob';
--4
COMMIT;

-- read skew 2
-- 2


BEGIN;
UPDATE accounts SET amount = amount + 100 WHERE id = 2;
UPDATE accounts SET amount = amount - 100 WHERE id = 3;
COMMIT;
-- that is true but not for VOLATILE FUNCTION
-- this anomaly happened only with read committed and volatile - default settings
---------------------------------------------------------------------------
--2
UPDATE accounts SET amount  = amount * 1.01
WHERE client IN (
    SELECT client
    FROM accounts
    GROUP BY client
    HAVING sum(amount) >= 1000
    );


------------------------------------------------------------------------
--2 lost update
BEGIN;
SELECT amount FROM accounts WHERE id = 1;
--4 same logic as step 3 but in another session
UPDATE accounts
SET amount = 800.00 + 100
WHERE id = 1
RETURNING amount;
COMMIT;
-- amount must be a 1000 --> lost update.