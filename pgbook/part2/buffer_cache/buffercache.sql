/*
 Buffer Cache
 It is array of buffers placed in shared server memory
 and available for all process. Each buffer reserved a memory
 for page and buffer header.
 Header contains the service info about buffer and the page loaded into it:
    * location in HD(relation file node, fork and block number in that fork)
    * special flag, which indicated that data in page has changed (dirty page)
    * usage count of particular buffer
    * pin count - the reference count to buffer
 To retrieve a page the process requesting a buffer number for that page
 from buffer manager. Process read the data from page in cache and can update it, so
 buffer will be pinned to exclude preemption that page. On each request the usage
 count will be incremented.
 OS I/O operation doesn't needed while page placed in buffer.

 When the buffer manager is requested a page it first try to find it in cache.
 For that purpose hash table is used. The structure of hash key - relation file
 node, type of fork and page number.
 If the buffer number will be found in hash-table buffer manager has pin it
 and return to the process. At this point of time process can work with page,
 without using OS I/O. Multiple process can pin a buffer each of them increment
 the `pin_count`. While buffer has pinned the page cannot be preempted, but
 new tuple version will be hidden

 */
CREATE EXTENSION pg_buffercache;

CREATE TABLE cacheme
(
    id int
) WITH (AUTOVACUUM_ENABLED = 'off');

INSERT INTO cacheme
VALUES (1);

CREATE FUNCTION buffercache(rel regclass)
    RETURNS TABLE
            (
                bufferid   int,
                relfor     text,
                relblk     bigint,
                isdirty    boolean,
                usagecount smallint,
                pins       int
            )
AS
$$
SELECT bufferid,
       CASE relforknumber
           WHEN 0 THEN 'main'
           WHEN 1 THEN 'fsm'
           WHEN 2 THEN 'vm'
           END,
       relblocknumber,
       isdirty,
       usagecount,
       pinning_backends
FROM pg_buffercache
WHERE relfilenode = pg_relation_filenode(rel)
ORDER BY relforknumber, relblocknumber;

$$ LANGUAGE sql;

EXPLAIN (analyse, buffers, costs off, timing off, summary off)
select * from cacheme;

select * from buffercache('cacheme');

-- Opened cursor hold a pin
BEGIN;
DECLARE c CURSOR FOR SELECT * FROM cacheme;
FETCH c;
select * from buffercache('cacheme');
-- Other process skip the pinned buffer. For example
-- VACUUM VERBOSE cacheme in other session

-- INFO:  vacuuming "public.cacheme"
-- INFO:  "cacheme": found 0 removable, 0 nonremovable row versions in 1 out of 1 pages
-- DETAIL:  0 dead row versions cannot be removed yet, oldest xmin: 929
-- There were 0 unused item identifiers.
-- Skipped 1 page due to buffer pins, 0 frozen pages.
-- 0 pages are entirely empty.
-- CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s.
-- VACUUM

-- In the other hand the VACUUM FREEZE will be pushed to the queue and slept
-- until page is unpinned

-- In situation where cursor jump to the next page or will be done page is unpinned
-- in this example it happen after transaction is finished.

COMMIT;
SELECT * FROM buffercache('cacheme');

-- page doesn't write to the disk, but still in buffer with dirty state (no need OS I/O)
INSERT INTO cacheme VALUES(2);
SELECT * FROM buffercache('cacheme');