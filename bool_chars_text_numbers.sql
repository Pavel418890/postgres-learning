/*
 Boolean data type
 TRUE FALSE NULL - BOOLEAN

 BOOLEAN LITERALS
 |  TRUE   |  FALSE |
 |---------|---------|
 |TRUE     |   FALSE |
 |'true'   |  'false'|
 | 't'     |   'f'   |
 |'yes'    |   'no'  |
 |'y'      |  'n'    |
 |'1'      |   '0'   |


 Character data types

 - TEXT - variable unlimited length

  */
SELECT CAST('Pavel' AS CHARACTER(10)) AS "Name";
SELECT 'Pavel'::CHAR(10) AS "Name", PG_COLUMN_SIZE('Pavel'::CHAR(10));
SELECT 'PAVEL'::CHAR AS "Name";
/*
CHARACTER, CHAR - fixed length, blank padded - default length 1
"Adnan     "
 */

/*
- CHARACTER VARYING, VARCHAR - variable length with length limit
NO DEFAULT VALUE
 */

SELECT 'Pavel'::VARCHAR(10), PG_COLUMN_SIZE('Pavel'::VARCHAR(10));
SELECT 'THIS IS A TEST FROM SYSTEM'::VARCHAR(10);

/*
 Text
 max size 1gb by chunk in toast table not best choice to store massive data
 in db
 */
CREATE TABLE temp
(
    t TEXT
);
INSERT INTO temp
VALUES ('hello');

UPDATE temp
SET t = (
    SELECT STRING_AGG(CHR(TRUNC(65 + RANDOM() * 26)::INTEGER), '')
    FROM GENERATE_SERIES(1, 5000)
)
WHERE t = 'hello';
SELECT relnamespace::regnamespace, relname
FROM pg_class
WHERE oid = (
    SELECT reltoastrelid FROM pg_class WHERE relname = 'temp'
    );


SELECT chunk_id,
       chunk_seq,
       LENGTH(chunk_data),
       LEFT(ENCODE(chunk_data, 'escape')::text, 10) ||
       '...' ||
        right(encode(chunk_data, 'escape')::text, 10)
FROM pg_toast.pg_toast_24953;


/*
 Numbers data types
 can hold various type numbers, but not NULL

 INTEGER
 SMALLINT - 2 bytes -32768 to +32768
 INTEGER - 4 bytes -2147483648 to +2147483647
 BIGINT - 8 bytes -92223372036854775808 to +92223372036854775807

 SERIAL
 SMALLSERIAL - 2 bytes 1 to 32768
 SERIAL - 4 bytes 1 to 2147483647
 BIGSERIAL - 8 bytes 1 to 92223372036854775807

 default value that serial type is hold -
 NEXTVAL('<table>_<serial_field_name>_seq'::regclass)
 */