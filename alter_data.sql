/*
 Alter data types
 */

CREATE TYPE myaddress AS
(
    city    varchar(50),
    country varchar(50)
);
--rename
ALTER TYPE myaddress RENAME TO my_address;

-- change owner
ALTER TYPE my_address OWNER TO plots;

-- change schema
CREATE SCHEMA test_schema;

ALTER TYPE my_address SET SCHEMA test_schema;

-- add attribute
ALTER TYPE test_schema.my_address ADD ATTRIBUTE street_address varchar(50);

-- alter enum
CREATE TYPE colors AS enum (
    'green',
    'red',
    'blue'
    );

-- update value
ALTER TYPE colors RENAME VALUE 'red' TO 'orange';

SELECT ENUM_RANGE(NULL::colors);

-- add value
ALTER TYPE colors ADD VALUE 'red' BEFORE 'green';
ALTER TYPE colors ADD VALUE 'purple' AFTER 'green';

CREATE TYPE status_enum AS enum ('queued', 'waiting', 'running', 'done');

CREATE TABLE jobs
(
    job_id     serial PRIMARY KEY,
    job_status status_enum
);


INSERT INTO jobs (job_status)
VALUES ('queued'),
       ('waiting'),
       ('running'),
       ('done');

UPDATE jobs
SET job_status = 'running'
WHERE job_status = 'waiting';
ALTER TYPE status_enum RENAME TO status_enum_old;
CREATE TYPE status_enum AS enum ('queued', 'running', 'done');
ALTER TABLE jobs
    ALTER COLUMN job_status TYPE status_enum
        USING job_status::text::status_enum;
DROP TYPE status_enum_old;



SELECT ENUM_RANGE(NULL::status_enum);
SELECT ENUM_RANGE(NULL::status_enum_old);


----------------------------------------------
-- enum with default value in table

CREATE TYPE status AS enum ('pending', 'approved', 'declined');

CREATE TABLE cron_jobs
(
    cron_job_id int,
    status      status DEFAULT 'pending'
);
INSERT INTO cron_jobs (cron_job_id)
VALUES (1);
INSERT INTO cron_jobs (cron_job_id)
VALUES (2),
       (3);
INSERT INTO cron_jobs (cron_job_id, status)
VALUES (5, 'approved');
SELECT *
FROM cron_jobs;

-- creating type if not exists
DO
$$
    BEGIN
        IF NOT EXISTS(
                SELECT *
                FROM pg_type typ
                         INNER JOIN pg_namespace pn ON typ.typnamespace = pn.oid
                WHERE pn.nspname = CURRENT_SCHEMA()
                  AND typ.typname = 'ai'
            ) THEN
            CREATE TYPE ai AS
            (
                a text,
                i int
            );
        END IF;
    END;
$$
LANGUAGE plpgsql;

