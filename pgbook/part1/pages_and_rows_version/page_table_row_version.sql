CREATE EXTENSION pageinspect;

-- get size of page headers
SELECT lower, upper, special, pagesize
FROM page_header(get_raw_page('accounts', 0))

CREATE TABLE padding
(
    b1 BOOLEAN,
    i1 INT,
    b2 BOOLEAN,
    i2 INT
);
INSERT INTO padding (b1, i1, b2, i2)
VALUES (TRUE, 1, FALSE, 2);

SELECT lp_len
FROM heap_page_items(get_raw_page('padding', 0));
-- 40 bytes                 total
-- 24 bytes                 header
-- 4 bytes(8 total)         integer
-- 1 bytes(2 total)         boolean
-- 6 bytes                  4-bytes boundary tuple alignment
DROP TABLE padding;

CREATE TABLE padding
(
    i1 INT,
    i2 INT,
    b1 BOOLEAN,
    b2 BOOLEAN
);
-- micro optimization: move fixed size column at beginning
INSERT INTO padding
VALUES (1, 2, TRUE, FALSE);
SELECT lp_len
FROM heap_page_items(get_raw_page('padding2', 0));

/*
 xmin xmax - counter used for differentiate a rows version between transaction
 xmin -     the number of transaction which run UPDATE command on row
 xmax -     the number of transaction which run DELETE command on row

 In UPDATE scenario used 2 operations DELETE and INSERT
 xmax -     the number of transaction which run UPDATE command on row
 creates a new row version where
 xmin -     the number from xmax on previous version
 xmax -     0

 */
CREATE TABLE t
(
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    s  TEXT
);
CREATE INDEX ON t (s);

BEGIN;
INSERT INTO t (s)
VALUES ('FOO');
SELECT pg_current_xact_id();

SELECT *
FROM heap_page_items(get_raw_page('t', 0));

SELECT '(0,' || lp || ')'      AS ctid, --(page number, page pointer)
       CASE lp_flags
           WHEN 0 THEN 'unset'
           WHEN 1 THEN 'normal'
           WHEN 2 THEN 'redirected to' || lp_off
           WHEN 3 THEN 'dead'
           END                 AS state,
       t_xmin,
       t_xmax,
       -- status of current xmin transaction
       (t_infomask & 256) > 0  AS xmin_commited,
       (t_infomask & 512) > 0  AS xmin_aborted,
       -- status of current xmax transaction
       (t_infomask & 1024) > 0 AS xmax_commited,
       (t_infomask & 2048) > 0 AS xmax_aborted
FROM heap_page_items(get_raw_page('t', 0));
/*
 on insert into table we have only 1 row version and pointer referenced to
 xmin -     current transaction and status not commited and not aborted,
            because transaction is still active
 xmax -     0  this row version wasn't deleted and flag xmax aborted is true,
            because from perspective isolation aborted transaction(even if didn't start)
            have no effect on that row version

 */
CREATE FUNCTION heap_page(relname TEXT, pageno INT)
    RETURNS TABLE
            (
                ctid  tid,
                state TEXT,
                xmin  TEXT,
                xmax  TEXT
            )
AS
$$
SELECT (pageno, lp)::TEXT::tid AS ctid,
       CASE lp_flags
           WHEN 0 THEN 'unset'
           WHEN 1 THEN 'normal'
           WHEN 2 THEN 'redirected to' || lp_off
           WHEN 3 THEN 'dead'
           END                 AS state,
       t_xmin || CASE
                     WHEN (t_infomask & 256) > 0 THEN ' c'
                     WHEN (t_infomask & 512) > 0 THEN ' a'
                     ELSE ''
           END                 AS xmin,
       t_xmax || CASE
                     WHEN (t_infomask & 1024) > 0 THEN ' c'
                     WHEN (t_infomask & 2048) > 0 THEN ' a'
                     ELSE ''
           END                 AS xmax
FROM heap_page_items(get_raw_page(relname, pageno))
ORDER BY lp;
$$ LANGUAGE sql;
SELECT XMIN, XMAX
FROM t;
SELECT *
FROM heap_page('t', 0);

/*
    clog ( commit log ) - few(for convenience) special file
    in PGDATA/pg_xact 2 bit for every transaction status(committed/aborted).
    When other transaction call page table status of transaction xmin number:
        1. Still running? Then created row version should be invisible.
        Use ProcArray data structure to retrieve list of actual
        process with number of current transaction for every process.
        2. Is finish?
            * Status aborted - row version should be invisible
            * Status commited - get transaction status from clog.
                For performance reason once defined status of transaction
                will be written to hint bits xmin_commited/xmin_aborted
                in row headers, even last pages stored in memory
                buffer that operation is still cost.
                If one of them bits is set before, then transaction status
                is known and next transaction no needed call clog or ProcArray
        Why are these hint bits not being set by transaction itself?
        At this point of time transaction don't know self status.
        In moment fixation no longer clear that row and
        pages was updated and number of records can be large and
        some of them can be push from memory buffer to HD.
        On the other hand any transaction that executes SELECT statement
        will be set this value too. Of course pages in buffer can be dirty.
*/

COMMIT;
SELECT *
FROM heap_page('t', 0);
-- now transaction that called page in regular way(not with pageinspect)
-- should ask status of transaction xmin and write to hint bits
SELECT *
FROM t;

SELECT *
FROM heap_page('t', 0);

/*
    On DELETE operation xmax is set to actual `delete` transaction,
    xmax_aborted is droped. The same value is a row blocker, for other
    transactions request this row will be blocked until current is not done.
 */
BEGIN;
DELETE
FROM t
WHERE s = 'FOO';
SELECT pg_current_xact_id();
SELECT *
FROM heap_page('t', 0);
--- cancel transaction work the same way as confirm, except hint bit xmax_aborted will
-- be used
ROLLBACK;
SELECT *
FROM heap_page('t', 0);
SELECT *
FROM t;
SELECT *
FROM heap_page('t', 0);

-- UPDATE operation work as DELETE and INSERT

BEGIN;
UPDATE t
SET s = 'BAR'
WHERE s = 'FOO';
SELECT pg_current_xact_id();
SELECT *
FROM t;
SELECT *
FROM heap_page('t', 0);
COMMIT;

/*
 Indexes
 Any indexes don't have a row version, each row present a single instance(no xmax/xmin value)

 Get all indexes on page
 */

CREATE FUNCTION index_page(relname TEXT, pageno INT)
    RETURNS TABLE
            (
                itemofset SMALLINT,
                htid      tid
            )
AS
$$
SELECT itemoffset, htid
FROM bt_page_items(relname, pageno)
$$ LANGUAGE sql;

SELECT *
FROM index_page('t_s_idx', 1);

/*
 TOAST
 1. Have own row version table.
 2. Toast version doesn't seems effect on main page
 3. Rows will never updated only deleted and inserted new
 4. When main page has changed, toast version will be same,
 except the scenario when toast was changed

 Virtual Transaction id (virtual xid)
    1. Exists only in RAM while transaction is active
    2. If transaction changed some data, then `real` transaction id
    will be received

 */
BEGIN;
SELECT pg_current_xact_id_if_assigned();
UPDATE accounts
SET amount = amount - 1.00
WHERE id = 4;
SELECT pg_current_xact_id_if_assigned();
COMMIT;
/*

Savepoint and Subtransaction
Subtransaction have a own id greater then primary transaction.
Status of subtransaction like a regular transaction will be
written to `clog`, but hint bits in saved subtransaction
marked as commited and aborted simultaneously. The final status
depends on status primary transaction
is rejected    - all will be aborted
is success     - all will be commited

Data of nested transaction located in PGDATA/pg_subtrans
SAVEPOINT <name>    - for using nesting transaction
if you try transaction like
BEGIN;
....
BEGIN;
the warning message will be received that transactions already in progress

 */
TRUNCATE TABLE t;
BEGIN;
INSERT INTO t (s)
VALUES ('foo');
SELECT pg_current_xact_id();
SAVEPOINT sp;
INSERT INTO t (s)
VALUES ('bar');
-- nothing changed
SELECT pg_current_xact_id();
SELECT *
FROM heap_page('t', 0) AS p
         LEFT JOIN t ON p.ctid = t.ctid;
ROLLBACK TO sp;
INSERT INTO t (s)
VALUES ('xyz');
SELECT *
FROM heap_page('t', 0) AS p
         LEFT JOIN t ON p.ctid = t.ctid;
COMMIT;
SELECT *
FROM t;
SELECT *
FROM heap_page('t', 0);

-- errors and operation atomicity
-- raised error in transaction block further execution
-- before transaction ends. Even sended commit will be rejected
-- and rollback
BEGIN;
SELECT *
FROM t;
UPDATE t
SET s = REPEAT('X', 1 / (id - 10))
WHERE id IS NOT NULL;
SELECT *
FROM t;
-- rollback will be received
COMMIT;

select * from heap_page('t', 0);