/*
 Page prune - clean up rows version on read operation there
 out of range "horizon".
 This operation will never change more then 1 page.
 References(ctid) on row version doesn't clean,
 because they needed for indexes which in an another page.

 It happened in 2 case:
    * UPDATE doesn't have enough space for new row on particular page
        (It remains in page headers).
    * Page current size greater then fillfactor of the page.

 Postgres INSERT new row version in page only if page size < fillfactor
 therefore amount of space uses for insertion new row version in
 UPDATE operation.


 */
-- page size 8192
-- headers size 24
-- bytes for each row 2004
-- fillfactor 75% (6144 max)
-- 4 row in each page, but 3 only will be inserted, remaining space for update
CREATE TABLE hot
(
    id integer,
    s  char(2000)
) WITH (FILLFACTOR = 75);
CREATE INDEX hot_id ON hot (id);
CREATE INDEX hot_s ON hot (s);

INSERT INTO hot
VALUES (1, 'A');

UPDATE hot
SET s = 'b'
WHERE id = 1;

UPDATE hot
SET s = 'c'
WHERE id = 1;

UPDATE hot
SET s = 'd'
WHERE id = 1;
SELECT *
FROM heap_page('hot', 0);

SELECT upper, pagesize
FROM page_header(get_raw_page('hot', 0));
-- page prune all not actual rows clean up. All `dead` rows move to
-- the end of the page and all available space presents as one segment
UPDATE hot
SET s = 'e'
WHERE id = 1;
SELECT *
FROM heap_page('hot', 0);
-- indexes still have references on row version
SELECT *
FROM index_page('hot_s', 1);
SELECT *
FROM index_page('hot_id', 1);

DROP FUNCTION index_page;

CREATE FUNCTION index_page(relname text, pageno int)
    RETURNS table
            (
                itemoffset smallint,
                htid       tid,
                dead       boolean
            )
AS
$$
SELECT itemoffset, htid, dead
FROM bt_page_items(relname, pageno)
$$ LANGUAGE sql;


SELECT *
FROM index_page('hot_id', 1);


EXPLAIN (ANALYSE, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT *
FROM hot
WHERE id = 1;
-- 4 row version have `normal` status, but is dead for index ref because
-- it out of range of "horizon"
SELECT *
FROM index_page('hot_id', 1);


/*
 Hot updates(Heap-Only-Tuple)
 Hold references on all row version not efficient:
    1. Any changes raised restructure indexes for table, event if updated
    field not included in index
    2. Indexes stores references on row versions history, which should
    be cleaned up with this row version.

 However, if updated field not in indexes, create additional record
 is meaningless. For that reason Heap-Only-Tuple does this optimization.
 Hot updates have only first row version record. Other version of particular
 row will be linked in a chain of ctid headers and stored in page table.

 heap-only-tuple - indicates, that current row doesn't have index reference
 heap-hot-update - indicates, that current row is chain link and move on
 For each row visibility will be checked in regular way, before return to
 client.

 */

DROP INDEX hot_s;
TRUNCATE TABLE hot;
DROP FUNCTION heap_page(text, int);

CREATE FUNCTION heap_page(relname TEXT, pageno INT)
    RETURNS TABLE
            (
                ctid   tid,
                state  TEXT,
                xmin   TEXT,
                xmax   TEXT,
                hhu    text,
                hot    text,
                t_ctid tid
            )
AS
$$
SELECT (pageno, lp)::TEXT::tid                          AS ctid,
       CASE lp_flags
           WHEN 0 THEN 'unused'
           WHEN 1 THEN 'normal'
           WHEN 2 THEN 'redirected to' || lp_off
           WHEN 3 THEN 'dead'
           END                                          AS state,
       t_xmin || CASE
                     WHEN (t_infomask & 256) > 0 THEN ' c'
                     WHEN (t_infomask & 512) > 0 THEN ' a'
                     ELSE ''
           END                                          AS xmin,
       t_xmax || CASE
                     WHEN (t_infomask & 1024) > 0 THEN ' c'
                     WHEN (t_infomask & 2048) > 0 THEN ' a'
                     ELSE ''
           END                                          AS xmax,
       CASE WHEN (t_infomask2 & 16384) > 0 THEN 't' END AS hhu,
       CASE WHEN (t_infomask2 & 32768) > 0 THEN 't' END AS hot,
       t_ctid
FROM heap_page_items(get_raw_page(relname, pageno))
ORDER BY lp;
$$ LANGUAGE sql;

INSERT INTO hot
VALUES (1, 'A');
UPDATE hot
SET s = 'B'
WHERE id = 1;

SELECT *
FROM heap_page('hot', 0);

UPDATE hot
SET s = 'C'
WHERE id = 1;
UPDATE hot
SET s = 'D'
WHERE id = 1;

SELECT *
FROM heap_page('hot', 0);

SELECT *
FROM index_page('hot_id', 1);

/*
 Page prune with Hot Updates
 Head of linked chain should always be on the same place, because index
 have a reference on that place. Other references should be cleaned up.

 */
UPDATE hot
SET s = 'E'
WHERE id = 1;
-- after update page prune will be executes
-- head of chain redirected to row version where chain started now
-- 2 and 3 version had a unused status and was cleaned up.
-- New row version was inserted to a free space(0, 2)
SELECT *
FROM heap_page('hot', 0);

UPDATE hot
SET s = 'F'
WHERE id = 1;

UPDATE hot
SET s = 'G'
WHERE id = 1;
SELECT *
FROM heap_page('hot', 0);

-- next update and page prune again
UPDATE hot
SET s = 'H'
WHERE id = 1;

select *
from heap_page('hot', 0);
-- Note: On often update fields that not included in the index
-- recommended use fillfactor for reserving space for updates; but
-- need to remains the lower fillfactor, the more unused space in a page,
-- therefore much more size a table

/*
 Hot-Chain break
 In case where not enough amount of space for new row version chain will break.
 A new reference to that page  will be created in index page.

 */
--2 transaction blocks the page prune and new page will be created
UPDATE hot
SET s = 'I'
where id = 1;
UPDATE hot
SET s = 'J'
where id = 1;
UPDATE hot
SET s = 'K'
where id = 1;

select *
from heap_page('hot', 0);

update hot
set s = 'L'
where id = 1;
--
select *
from heap_page('hot', 0);
select *
from heap_page('hot', 1);
--
select *
from index_page('hot_id', 1);

/*
 Indexes Page Prune may happen when for insertion in B-Tree not enough amount
 of space and index pages will be split, sharing data between them. But on
 delete operation pages will not squashed back and index grow up even if
 a significant amount of data will be removed.
 However if page prune happened in right moment, split operation will be
 call later.

 Row types for page prune:
    1. First of all remove row marked as `dead`(
        in case if index record referenced on row version, which out of range
        the horizon - not visible for any snapshot or not exists)
    2. If `dead` record is not found, then rows which referenced on different
    version the same row.

    In case that a field includes in the index references on row version
    arise in another indexes too.


 */