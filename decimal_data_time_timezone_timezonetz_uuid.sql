/*
 Decimal Numbers
 Fixed-point number
 -------------------
 numeric (precision, scale)
 precision    max number of digits of the left and right of the decimal point
 scale        number of digits allowable on the right of the decimal point

 decimal(precision, scale) e.g. numeric(10,2) will return two digits to the
 right of the decimal point

Floating-point number
----------------------
    real        allow precision to 6 decimal digits
    double      allow precision to 15 decimal digits
 */

 CREATE TABLE table_numbers(
     col_numeric numeric(20, 5),
     col_real real,
     col_double double precision
 );
INSERT INTO table_numbers
VALUES (.9, .9, .9),
       (3.13579, 3.13579, 3.13579),
       (4.13579876543, 4.13579876543, 4.13579876543);

SELECT * FROM table_numbers;

/*
Date data type
1.  Store date values
2. take 4 bytes
3. default format YYYY-MM-DD
4. CURRENT_DATE store current date
*/

CREATE TABLE table_dates(
    id serial PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    add_date DATE DEFAULT CURRENT_DATE
);

INSERT INTO table_dates (employee_name, hire_date) VALUES
('ADAM', '2020-01-01'),
('LINDA', '2022-02-01');

SELECT * FROM table_dates;

/*
Time data type
1. store the time
2. take 8 bytes
3. precision - number of fractional digits in the seconds field(6 digits)
4. formats
-----------
    HH:MM
    HH:MM:SS
    HHMMSS
    MM:SS.pppppp
    HH:MM:SS.pppppp
    HHMMSS.pppppp
*/

CREATE TABLE table_time(
    id serial PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL
);

INSERT INTO table_time (class_name, start_time, end_time)
VALUES ('MATH', '08:00:00', '09:00:00'),
       ('CHEMISTRY', '09:01:00', '10:00:00');

SELECT * FROM table_time;

SELECT CURRENT_TIME(2);

SELECT CURRENT_TIME, LOCALTIME;

SELECT '10:00'::TIME - '04:00'::TIME as Result;

SELECT LOCALTIME + interval '2 HOURS' AS RESULT;


/*
 TIMESTAMP/TIMESTAMPTZ date types

 timestamptz - stored value is always in UTC

 adding a timestamptz
 -----
 an INPUT value that has an explicit time zone is converted to UTC using
 appropriate offset for that time zone
if no time zone specified - using system TimeZone parameter, and converted to
 UTC using offset for the timezone

 on OUTPUT
 converted from UTC to the current timezone zone, and displayed as local time in
 that zone

 */

 CREATE TABLE table_time_tz(
     ts timestamp,
     tstz timestamptz
 );

INSERT INTO table_time_tz (ts, tstz)
VALUES ('2020-02-22 10:10:10-07', '2020-02-22 10:10:10-07');

SELECT * FROM table_time_tz;

SHOW TIMEZONE;

SET TIMEZONE = 'Europe/Moscow'

SELECT CURRENT_TIMESTAMP;
SELECT TIMEOFDAY();

SELECT timezone('Asia/Singapore', '2020-01-01 00:00:00');
SELECT timezone('America/New_York', '2020-01-01 00:00:00');


/*
 UUID data type
32 hexadecimal digits separated by hyphens

Is much better than the SERIAL data type when it comes to `uniqueness` across
 systems as SERIAL data type generated only unique values within a single db
*/

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- MAC TIMESTAMP AND RANDOM NUMBER
SELECT uuid_generate_v1();
-- PURE UNIQUE
SELECT uuid_generate_v4();


CREATE TABLE table_uuid(
    product_id UUID DEFAULT uuid_generate_v1(),
    product_name VARCHAR(100) NOT NULL
);

INSERT INTO table_uuid(product_name)
VALUES('BOOK'), ('ABC'), ('BCD');

SELECT * FROM table_uuid;

ALTER TABLE table_uuid ALTER COLUMN product_id
SET DEFAULT uuid_generate_v4();

INSERT INTO table_uuid(product_name)
VALUES('BOOK'), ('ABC'), ('BCD');

