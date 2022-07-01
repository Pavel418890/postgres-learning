-- READ ONLY TRANSACTION ANOMALY
--3
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM accounts WHERE client = 'alice';
--5
-- this transaction begin after second transaction, but second transaction
-- begin after first and result of this query in any scenario will be skew
SELECT * FROM accounts WHERE client = 'bob';
------------------------------------------------------------------