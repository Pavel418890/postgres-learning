/*
 UPSERT
when you insert a new row into the table, pg will update the row if
it already in exists, otherwise, it will be insert new row
INSERT INTO table name (columns)
VALUES (values)
ON CONFLICT target action(
    DO NOTHING,
    DO UPDATE SET EXCLUDED.column = value (
        value may be modified with condition
        or set new value for column like new date or other
        )

    WHERE condition # similar to INSERT INTO ... IF NOT EXIST
)
 */

SELECT first_name || ' ' || last_name full_name
FROM actors;


SELECT *
FROM movies
ORDER BY release_date ASC;

SELECT *
FROM movies
ORDER BY release_date DESC;

SELECT release_date, movie_name
FROM movies
ORDER BY movie_name DESC,
         release_date DESC;

SELECT first_name, last_name AS surname
FROM actors
ORDER BY last_name DESC;

SELECT first_name, last_name AS surname
FROM actors
ORDER BY surname DESC;

SELECT first_name, LENGTH(first_name) AS len
FROM actors
ORDER BY len DESC;

SELECT *
FROM actors
ORDER BY first_name, date_of_birth DESC;

SELECT first_name,
       last_name,
       date_of_birth
FROM actors
ORDER BY first_name, date_of_birth DESC;


SELECT first_name,
       last_name,
       date_of_birth
FROM actors
ORDER BY 1, 3 DESC;

CREATE TABLE demo_sorting
(
    num INT

);

INSERT INTO demo_sorting (num)
VALUES (1),
       (2),
       (3),
       (NULL);

SELECT *
FROM demo_sorting;

SELECT *
FROM demo_sorting
ORDER BY num DESC;

SELECT *
FROM demo_sorting
ORDER BY num NULLS LAST;

SELECT *
FROM demo_sorting
ORDER BY num NULLS FIRST;

SELECT *
FROM demo_sorting
ORDER BY num DESC;

DROP TABLE demo_sorting;

SELECT *
FROM movies;

SELECT DISTINCT movie_lang
FROM movies
ORDER BY 1;

SELECT DISTINCT director_id
FROM movies
ORDER BY 1;

SELECT DISTINCT movie_lang, director_id
FROM movies
ORDER BY movie_lang;

SELECT DISTINCT *
FROM movies
ORDER BY movie_id;

SELECT *
FROM movies
WHERE movie_lang = 'English';
/*
 logical operator
AND OR - like and math operation multiplication and addition
3 *<and> 1 +<or> + 2 = 5
3 *<and>(1 +<or> 2) = 9
AND executes first, always need using pretences for right result
---------------------------------------
 */
SELECT *
FROM movies
WHERE movie_lang = 'Japanese'
   OR movie_lang = 'English';


SELECT *
FROM movies
WHERE movie_lang = 'Japanese'
  AND age_certificate = '18';

SELECT *
FROM movies
WHERE movie_lang = 'English'
   OR movie_lang = 'Chinese'
ORDER BY movie_lang;

SELECT *
FROM movies
WHERE movie_lang = 'English'
  AND director_id = 8;

SELECT *
FROM movies
WHERE movie_lang = 'English'
   OR movie_lang = 'Chinese';

/*
 order execution
FROM -> WHERE -> SELECT -> ORDER BY
---------------------------------------
 */
SELECT *
FROM movies
WHERE movie_lang = 'English'
   OR movie_lang = 'Chinese' AND age_certificate = '12'
ORDER BY movie_lang DESC;

SELECT *
FROM movies
WHERE (movie_lang = 'English' OR movie_lang = 'Chinese')
  AND age_certificate = '12'
ORDER BY movie_lang DESC;

SELECT first_name, last_name AS surname
FROM actors
WHERE surname = 'Allen';

SELECT *
FROM movies
WHERE movie_length > 100
ORDER BY movie_length;


SELECT *
FROM movies
WHERE movie_length <= 100
ORDER BY movie_length;

SELECT *
FROM movies
WHERE release_date > '2000-12-31'
ORDER BY release_date;

SELECT *
FROM movies
WHERE movie_lang > 'English'
ORDER BY movie_lang;

SELECT *
FROM movies
WHERE movie_lang < 'English'
ORDER BY movie_lang;

SELECT *
FROM movies
WHERE movie_lang != 'English'
ORDER BY movie_lang;

SELECT *
FROM movies
WHERE movie_length > 100;

SELECT *
FROM movies
ORDER BY movie_name LIMIT 9;

/*
OFFSET <int> - value starting from row <int>
LIMIT <int> - total number of row in result
---------------------------------------
 */


SELECT *
FROM movies
ORDER BY movie_length DESC LIMIT 5;

SELECT *
FROM directors
WHERE nationality = 'American'
ORDER BY date_of_birth DESC LIMIT 5;


SELECT *
FROM actors
WHERE gender = 'F'
ORDER BY date_of_birth DESC LIMIT 5;

SELECT *
FROM movies_revenues
ORDER BY revenues_domestic DESC NULLS LAST LIMIT 10;

SELECT *
FROM movies_revenues
ORDER BY revenues_domestic LIMIT 10;

SELECT *
FROM movies
ORDER BY movie_id LIMIT 5
OFFSET 5;

SELECT *
FROM movies_revenues
ORDER BY revenues_domestic DESC NULLS LAST limit 5
OFFSET 5;