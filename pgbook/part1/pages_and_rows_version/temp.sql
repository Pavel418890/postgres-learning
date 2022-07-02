CREATE EXTENSION pageinspect;
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

DROP TABLE padding;

CREATE TABLE padding
(
    i1 INT,
    i2 INT,
    b1 BOOLEAN,
    b2 BOOLEAN
);
INSERT INTO padding
VALUES (1, 2, TRUE, FALSE);

SELECT lp_len
FROM heap_page_items(get_raw_page('padding', 0));


CREATE TABLE t2
(
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    s  TEXT
);
CREATE INDEX ON t2 (s);

BEGIN;

INSERT INTO t2 (s)
VALUES ('FOO');
SELECT pg_current_xact_id();

SELECT *
FROM heap_page_items(get_raw_page('t2', 0));

SELECT '(0,' || lp || ')'      AS cid,
       CASE lp_flags
           WHEN 0 THEN 'unset'
           WHEN 1 THEN 'normal'
           WHEN 2 THEN 'redirected to' || lp_off
           WHEN 3 THEN 'dead'
           END                 AS state,
       t_xmin,
       t_xmax,
       (t_infomask & 256) > 0  AS xmin_commited,
       (t_infomask & 512) > 0  AS xmin_aborted,
       (t_infomask & 1024) > 0 AS xmax_commited,
       (t_infomask & 2048) > 0 AS xmax_aborted
FROM heap_page_items(get_raw_page('t2', 0));

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

SELECT *
FROM heap_page('t2', 0);

