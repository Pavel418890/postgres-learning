/*
 VACUUM
 Internal page prune cleaned up only page table row version without indexes,
 or index pages without page table

 VACUUM - handle the page table row version and index references too.
 It works parallel with other operation except CREATE INDEX and ALTER TABLE.
 Visibility maps used to view unnecessary pages, because it contains only
 actual row version and other pages may be cleaned up.
 VACUUM can refresh the visibility maps, if only row version in range horizon
 is left. Free space map refreshed too.


 */

CREATE TABLE vac
(
    id integer,
    s  char(100)
) WITH (AUTOVACUUM_ENABLED = OFF);

CREATE INDEX vac_s ON vac (s);

INSERT INTO vac
VALUES (1, 'A');
UPDATE vac
SET s = 'B'
WHERE id = 1;
UPDATE vac
SET s = 'C'
WHERE id = 1;

SELECT *
FROM heap_page('vac', 0);
SELECT *
FROM index_page('vac_s', 1);
VACUUM vac;
-- ctid have a unused state instead of dead like in page prune,
-- because there is no references in indexes page on that row version.
-- they can be used for new row version
SELECT *
FROM heap_page('vac', 0);
SELECT *
FROM index_page('vac_s', 1);

CREATE EXTENSION pg_visibility;
-- page is marked as visible in visibility map
SELECT all_visible
FROM pg_visibility('vac', 0);
-- and in page headers too
SELECT flags & 4 > 0 AS all_visibility
FROM page_header(get_raw_page('vac', 0));

/*
 VACUUM define which row version should be cleaned up using
  DB level horizon of transaction
 */
-- 1
TRUNCATE vac;
INSERT INTO vac(id, s)
VALUES (1, 'A');
UPDATE vac
SET s = 'B'
WHERE id = 1;
-- 3
UPDATE vac
SET s = 'C'
WHERE id = 1;

SELECT *
FROM heap_page('vac', 0);
SELECT *
FROM index_page('vac_s', 1);
--5
VACUUM vac;
SELECT *
FROM heap_page('vac', 0);
SELECT *
FROM index_page('vac_s', 1);
VACUUM VERBOSE vac;
-- vacuuming "public.vac"
-- table "vac": found 0 removable, 2 nonremovable row versions in 1 out of 1 pages
--7
VACUUM VERBOSE vac;
/*
vacuuming "public.vac"
scanned index "vac_s" to remove 1 row versions
table "vac": removed 1 dead item identifiers in 1 pages
index "vac_s" now contains 1 row versions in 2 pages
table "vac": found 1 removable, 1 nonremovable row versions in 1 out of 1 pages
 */

SELECT *
FROM heap_page('vac', 0);

SELECT *
FROM index_page('vac_s', 1);


/*
 VACUUM in details
 In generally:
    1. scanning table the `dead` row version will be detected
    2. found version cleaned up in indexes pages first
    3. found version cleaned up in row version pages
    4. repeat 2, 3 if needed
    5. truncate table

1. Scan table
 Actual pages in visibility map will be passed. tid that out of range horizon
 appended to the special list in local memory of clean process. Allocated
 memory for that list is 64MB. At this point, either the scan has ended or memory
 in the list not enough to go further. Cleanup of indexes will be performed anyway.

2. Cleanup indexes
 Compare each index with stored in the list record. Founded indexes will be removed
 in background processes(on each index own process or
     common limits for background task) and at the same time free space map maintenance
     actual state will be control and computed cleanup process state. But
 this step will be passed if not actual update/delete, and then cleanup indexes
 will be pass through in another process at the end of process.
 3. Cleanup table
 Free space after 1,2 step written to free space table, pages that has only
 actual row version with "full visibility" from all snapshots written to
 visibility map. At this point repeat operation 1, 2 if scan table is not over
 eat from the point where it was stopped.

 4. Truncate table

 Truncate required a exclusive block table, if request is denied ,then waiting
 is break after 5 seconds or another process call block.
 From that perspective truncation performed only if amount of pages is enough
 1/16 of file or more then 1000 for big table. If at the end of file formed
 some free space, truncation may cut a part of file and return to OS
 In some cases can release a whole page.

 Analyse

 As addition to cleanup process pg have an another task - analyze.
 Statistic includes amount of tuples and pages in relationships e.t.c

 */

/*
  Autovacuum - special mechanism which perform a vacuum and analyze,
  depending on table update frequency.

track_counts - using rate statistics
autovacuum launcher - scheduler process that control execution of autovacuum workers.
autovacuum workers - polling process
autovacuum naptime(1 min default) - timer for scheduling
max_autovacuum_process - 3 default

Autovacuum run:
  * connect to required database
  * build a list all tables, materialized views and toast table where vacuum
    is required
  * build a list all tables, materialized views where analyze is required( toast
    no needed analyze, because they always get from indexes).
  * run ANALYZE & auto-VACUUM
    differences with VACUUM:
        - value for memory allocation to list;
        - don't use parallel scanning index pages(too much processes will be);

In regular way VACUUM mechanism will be called in this situation:
  1. Too much dead tuples.

  pg_stat_all_tables.n_dead_tup >
  autovacuum_vacuum_threshold +
  autovacuum_vacuum_scale_factor * pg_class.reltuples

  2. Too much inserted tuples
  pg_stat_all_tables.n_ins_since_vacuum >
  autovacuum_vacuum_insert_threshold +
  autovacuum_vacuum_insert_scale_factor * pg_class.reltuples

ANALYZE inspect only updated tuples and will be called in situation
  pg_stat_all_tables.n_mod_since_analyze >
  autovacuum_analyze_threshold +
  autovacuum_analyze_scale_factor * pg_class.reltuples


 */
-- get param value from table
CREATE FUNCTION p(param text, c pg_class) RETURNS float
AS
$$
SELECT COALESCE(
               (SELECT option_value
                       -- if value is declared, then get it
                FROM PG_OPTIONS_TO_TABLE(C.reloptions)
                WHERE option_name = CASE
                                        WHEN C.relkind = 't' THEN 'toast.'
                                        ELSE ''
                                        END || param
               ),
           -- else get value from  default configuration
               CURRENT_SETTING(param)
           )::FLOAT
$$ LANGUAGE sql;
CREATE VIEW need_vacuum AS
WITH c AS (
    SELECT c.oid,
           GREATEST(c.reltuples, 0)                   AS reltuples,
           p('autovacuum_vacuum_threshold', c)        AS threashold,
           p('autovacuum_vacuum_scale_factor', c)     AS scale_factor,
           p('autovacuum_vacuum_insert_threshold', c) AS insert_threshold,
           p('autovacuum_vacuum_insert_scale_factor',
             c)                                       AS insert_scale_factor
    FROM pg_class c
    WHERE relkind IN ('r', 'm', 't')
)
SELECT st.schemaname || '.' || st.relname                      AS tablename,
       st.n_dead_tup                                           AS deap_tuple,
       c.threashold + c.scale_factor * c.reltuples             AS max_dead_tup,
       st.n_ins_since_vacuum                                   AS ins_tup,
       c.insert_threshold + c.insert_scale_factor * c.reltuples AS max_ins_tup,
       st.last_autovacuum
FROM pg_stat_all_tables st
         JOIN c ON c.oid = st.relid;

CREATE VIEW need_analyze AS
WITH c AS (
    SELECT c.oid,
           GREATEST(c.reltuples, 0)                reltuples,
           p('autovacuum_analyze_threshold', c)    threshold,
           p('autovacuum_analyze_scale_factor', c) scale_factor
    FROM pg_class AS c
    WHERE c.relkind IN ('r', 'm')
)
SELECT st.schemaname || '.' || st.relname         AS tablename,
        st.n_mod_since_analyze AS mod_tup,
       c.threshold + c.scale_factor * c.reltuples AS max_mod_tup,
       st.last_analyze
FROM pg_stat_all_tables st
         JOIN c ON c.oid = st.relid;

DROP TABLE IF EXISTS vac;

CREATE TABLE vac (
    id int,
    s  char(1000)
) WITH (AUTOVACUUM_ENABLED = 'off');

CREATE INDEX vac_s ON vac(s);
CREATE INDEX vac_id ON vac(id);

ALTER SYSTEM SET autovacuum_naptime = '1s';
SELECT pg_reload_conf();

INSERT INTO vac (id, s)
SELECT  id, 'A' FROM generate_series(1, 1000) id;


SELECT * FROM need_vacuum WHERE tablename = 'public.vac';
/*
Note: threshold is 50 and max_ins_tup 1000
autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor * pg_class.reltuples
50 + 0.2 * 1000 = 250
pg_stat_all_tables.n_ins_since_vacuum >
autovacuum_vacuum_insert_threshold + autovacuum_vacuum_insert_scale_factor * pg_class.reltuples
1000 + 0.2 * 1000 = 1200

because the autovacuum is off state and we get a default table values
where collecting statistics is not performed.
*/
SELECT reltuples FROM pg_class WHERE relname = 'vac';
/*
reltuples is `-1` special value that allow differentiate empty table from table without
 statistics, but already analyzed. In this case it replaced to 0 and
 threshold is equal 50 and max inserted tuples 1000.
 50 + 0.2 * 0 = 50
 1000 + 0.2 * 0 = 1000
 */


SELECT * FROM need_analyze WHERE tablename = 'public.vac';

/*
Table was updated(inserted 1000 tuples) that greater then max threshold 50,
so then analyze will been called the value should change
50 + 0.1 * 1000 = 150
 */
 ALTER TABLE vac SET (autovacuum_enabled = on);

 SELECT reltuples FROM pg_class WHERE relname = 'vac';
SELECT * FROM need_analyze WHERE tablename = 'public.vac';
-- as expected 150

SELECT * FROM need_vacuum where tablename = 'public.vac';
/*
At this point autovacuum can happened  on addition 250 dead tuples or 200 new
tuples will be created
so let's try it.
 */
 ALTER TABLE vac SET (autovacuum_enabled = 'off');

UPDATE vac SET s = 'B' WHERE id <= 251;

SELECT * FROM need_vacuum WHERE tablename = 'public.vac';
ALTER TABLE vac SET (autovacuum_enabled = 'on');
SELECT * FROM need_vacuum WHERE tablename = 'public.vac';

/*
Performance control

In case autovacuum is enabled the process of "manual" VACUUM use rotation
between execution and sleeping. VACUUM work `vacuum_cost_limit=200` process unit
and sleep `cost_delay` default is 0. Meaning if autovacuum is disabled
by the user, then he want cleanup the table as soon as possible.
Autovacuum control working the same, but with your own params.
Note: -1 value  = regular vacuum setting

In case where required speed up vacuum process incrementing the autovacuum_max_workers
has no effect, because `autovacuum_vacuum_cost_limit` process unit used by the all
workers in scope of one loop process. So the value of `autovacuum_vacuum_cost_limit`
need to increase too.
 */
 select current_setting('autovacuum_vacuum_cost_delay') as auto_delay,
        current_setting('autovacuum_vacuum_cost_limit') as auto_limit,
        current_setting('vacuum_cost_delay') as regular_delay,
        current_setting('vacuum_cost_limit') as regular_limit;

/*
Monitoring VACUUM process.

In the scenario when process try to cleanup huge number of tuples, and
allocated memory for the list index references not enough(`maintenances_work_mem` = 64MB)
then scanning indexes will be performed many times. For the huge table it can be
very slow and performance will be decreased. Of course it not block
the another operation, but I/O bound operation is costly for OS.

To fix this problem can help:
    * cleanup more often
    * increase allocated memory for list

`log_autovacuum_min_duration` -
 */


TRUNCATE vac;
alter table vac set (autovacuum_enabled = 'off');

INSERT INTO vac (id, s)
SELECT id, 'A' FROM generate_series(1, 500000) as id;

UPDATE vac SET s = 'B' WHERE id  IS NOT NULL;

ALTER SYSTEM SET maintenance_work_mem = '1MB';

SELECT pg_reload_conf();

VACUUM VERBOSE vac;
/*
plots=# SELECT * FROM pg_stat_progress_vacuum \gx
-[ RECORD 1 ]------+---------------
pid                | 155
datid              | 16384
datname            | plots
relid              | 25555
phase              | vacuuming heap  -- name
heap_blks_total    | 142858 -- total number of pages
heap_blks_scanned  | 49850 -- scanned pages
heap_blks_vacuumed | 36796 -- cleaned up pages
index_vacuum_count | 2 -- count of iteration over table
max_dead_tuples    | 174761
num_dead_tuples    | 174475


plots=# SELECT * FROM pg_stat_progress_vacuum \gx
-[ RECORD 1 ]------+---------------
pid                | 155
datid              | 16384
datname            | plots
relid              | 25555
phase              | vacuuming heap
heap_blks_total    | 142858
heap_blks_scanned  | 142858
heap_blks_vacuumed | 61201
index_vacuum_count | 3
max_dead_tuples    | 174761
num_dead_tuples    | 151050

2022-07-17 13:15:36] [00000] vacuuming "public.vac"
[2022-07-17 13:15:44] [00000] launched 1 parallel vacuum worker for index vacuuming (planned: 1)
[2022-07-17 13:15:44] [00000] scanned index "vac_s" to remove 174475 row versions
[2022-07-17 13:15:44] [00000] scanned index "vac_id" to remove 174475 row versions
[2022-07-17 13:15:51] [00000] table "vac": removed 174475 dead item identifiers in 24925 pages
[2022-07-17 13:15:58] [00000] launched 1 parallel vacuum worker for index vacuuming (planned: 1)
[2022-07-17 13:15:58] [00000] scanned index "vac_s" to remove 174475 row versions
[2022-07-17 13:15:58] [00000] scanned index "vac_id" to remove 174475 row versions
[2022-07-17 13:16:04] [00000] table "vac": removed 174475 dead item identifiers in 24925 pages
[2022-07-17 13:16:19] [00000] launched 1 parallel vacuum worker for index vacuuming (planned: 1)
[2022-07-17 13:16:19] [00000] scanned index "vac_s" to remove 151050 row versions
[2022-07-17 13:16:19] [00000] scanned index "vac_id" to remove 151050 row versions
[2022-07-17 13:16:25] [00000] table "vac": removed 151050 dead item identifiers in 21579 pages
[2022-07-17 13:16:25] [00000] index "vac_s" now contains 500000 row versions in 860 pages
[2022-07-17 13:16:25] [00000] index "vac_id" now contains 500000 row versions in 2745 pages
[2022-07-17 13:16:25] [00000] table "vac": found 500000 removable, 500000 nonremovable row versions in 142858 out of 142858 pages
[2022-07-17 13:16:25] [00000] vacuuming "pg_toast.pg_toast_25555"
[2022-07-17 13:16:25] [00000] table "pg_toast_25555": found 0 removable, 0 nonremovable row versions in 0 out of 0 pages
 */




