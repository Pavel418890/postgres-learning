/*
---------------------------------------
FETCH {START }
FETCH - similar functionality as pg LIMIT(non-standard SQL-command)
    OFFSET may be before FETCH or after
---------------------------------------
*/

SELECT *
FROM movies
    FETCH FIRST 5 ROW ONLY;

SELECT *
FROM movies
ORDER BY movie_length DESC
    FETCH FIRST 5 ROW ONLY;

SELECT *
FROM directors
ORDER BY date_of_birth
    FETCH FIRST 5 ROW ONLY;


SELECT *
FROM actors
WHERE gender = 'F'
ORDER BY date_of_birth DESC
    FETCH FIRST 10 ROW ONLY;

SELECT *
FROM movies
ORDER BY movie_length DESC
    FETCH FIRST 5 ROW ONLY
OFFSET 5;

SELECT *
FROM movies
WHERE movie_lang IN ('English', 'Japanese', 'Chinese')
ORDER BY movie_length DESC;
/* SIMILAR AS
   WHERE movie_lang = 'English' OR
         movie_lang = 'Japanese'... */
SELECT *
FROM movies
WHERE age_certificate IN ('12', 'PG')
ORDER BY age_certificate;

SELECT *
FROM movies
WHERE director_id NOT IN (13, 10)
ORDER BY director_id;

SELECT *
FROM actors
WHERE actor_id NOT IN (1, 2, 3, 4, 5)
ORDER BY actor_id;

/*
---------------------------------------

BETWEEN/NOT BETWEEN
value BETWEEN (>=)low AND (<=) high

---------------------------------------
*/
SELECT *
FROM actors
WHERE date_of_birth BETWEEN '1991-01-01' AND '1995-12-31'
ORDER BY date_of_birth;

SELECT *
FROM movies
WHERE release_date BETWEEN '1998-01-01' AND '2002-12-31'
ORDER BY release_date;

SELECT *
FROM movies_revenues
WHERE revenues_domestic BETWEEN 102.10 AND 290.30
ORDER BY revenues_domestic;

SELECT *
FROM movies
WHERE movie_length NOT BETWEEN 100 AND 300
ORDER BY movie_length;

/*
 ---------------------------------------
LIKE/ILIKE
% - any sequence of zero or more char
_ - any single char

PERFORMANCE ON LARGE DB CAN BE SLOW
AND WE CAN IMPROVE THIS BY USING INDEXES
---------------------------------------
 */

SELECT 'hello' LIKE 'h%';
SELECT 'hello' LIKE '%e%';
SELECT 'hello' LIKE 'hell%';
SELECT 'hello' LIKE '%ll';
SELECT 'hello' LIKE '_ello';
SELECT 'hello' LIKE '___lo';

SELECT *
FROM actors
WHERE first_name LIKE 'A%';

SELECT *
FROM actors
WHERE last_name LIKE '%a'
ORDER BY last_name;

SELECT *
FROM actors
WHERE first_name LIKE '_____';
-- similar as this
SELECT *
FROM actors
WHERE LENGTH(first_name) = 5;

SELECT *
FROM actors
WHERE first_name LIKE '_l%'
ORDER BY first_name;

SELECT *
FROM actors
WHERE first_name LIKE '%TIM%';

SELECT *
FROM actors
WHERE first_name ILIKE '%TIM%';

/*
 IS NULL NOT IS NULL
 */
SELECT *
FROM actors
WHERE date_of_birth IS NULL
   OR first_name IS NULL;