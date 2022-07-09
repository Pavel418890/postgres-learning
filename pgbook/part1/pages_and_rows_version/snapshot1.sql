/*
 Itself Transaction Visibility
 cmin cmax - inner serial number for transaction itself
 cmin - insert operation
 cmax - delete operation

 Cursor opened in transaction doesn't see changes
 after your creation
 */
BEGIN;
INSERT INTO accounts
VALUES (3, 'charlie', 100.00);

DECLARE c CURSOR FOR SELECT COUNT(*)
                     FROM accounts;
SELECT pg_current_xact_id();
INSERT INTO accounts
VALUES (4, 'charlie', 400.00);

SELECT xmin, CASE WHEN xmin = 5490 THEN cmin END cmin, *
FROM accounts;

FETCH c;

/*
 Transaction horizon - xmin xid number of earliest active transaction
 in moment of creation snapshot
 Database horizon - earliest xmin xid number in all active transactions
all rows version that was created before that xid may be safely cleared

 Repeatable Read of Serializable transaction with IDLE status hold
 horizon and prevent cleaning rows version

 ReadCommitted transaction with IDLE status also hold a horizon
 and prevent cleaning rows version, but virtual ReadCommitted transaction
 hold a horizon only in process execution operations
 */
--1
BEGIN;
SELECT backend_xmin
FROM pg_stat_activity
WHERE pid = PG_BACKEND_PID();
--3
SELECT backend_xmin
FROM pg_stat_activity
WHERE pid = PG_BACKEND_PID();
COMMIT;
SELECT backend_xmin
FROM pg_stat_activity
WHERE pid = PG_BACKEND_PID();


/*
 Snapshot for system catalog

 System catalog not used transaction or operator snapshot
 and has own catalog snapshot including actual updates or
 constrains
 */
--1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT 1;
--3
INSERT INTO accounts (client, amount)
VALUES ('alice', NULL);
--ERROR: null value in column "amount" of relation "accounts" violates not-null constraint
ROLLBACK;
----------------------------------------------------------------------
-- if transaction call table then updates and add constrains block
-- until transaction finish
--1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT 1;
SELECT *
FROM accounts;
--3
COMMIT;

