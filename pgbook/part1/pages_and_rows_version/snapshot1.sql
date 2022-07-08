/*
 Snapshot - all `rows version` observed by a transaction in a particular
 period of a time and contains only actual data on a moment of creation

 All transaction work with your own snapshot.
 At the same time different transaction see different data but consistent
 for a given period of time.

 Read Committed         creates snapshot before each operator;

 Repeatable Read        creates snapshot at start first operator and
                        stay active till the end;

 Serializable           same as Repeatable Read;

 Snapshot is not a copy of the `rows version`,
 just a few number represent visibility of that particular `rows`

 Visibility of row depends on

 xmin           - last number of active transaction

 xmax           - last number of finished transaction + 1,
                  represent the moment of creation snapshot
                  all transaction that >= not finished or does not exists

 xip_list       - (x in progress list) list of active transaction

 */
SELECT *
FROM accounts;
TRUNCATE TABLE accounts;
--1
BEGIN;
INSERT INTO accounts (id, client, amount)
VALUES (1, 'alice', 1000.00);
SELECT pg_current_xact_id();
--4
COMMIT;

--5
BEGIN;
UPDATE accounts
SET amount = amount + 100.00
WHERE id = 2;
SELECT pg_current_xact_id();
COMMIT;
