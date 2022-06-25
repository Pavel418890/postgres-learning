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