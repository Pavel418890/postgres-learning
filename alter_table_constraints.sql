CREATE TABLE persons
(
    id         SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name  VARCHAR(255) NOT NULL

);
-- adding new column
ALTER TABLE persons
ADD COLUMN age INT;

ALTER TABLE persons
ADD COLUMN nationality VARCHAR(20) NOT NULL,
ADD COLUMN email VARCHAR(255) UNIQUE;

-- rename table
ALTER TABLE persons
RENAME TO users;

ALTER TABLE users
RENAME TO persons;

-- rename column
ALTER TABLE persons
RENAME COLUMN age TO person_age;

ALTER TABLE persons
DROP COLUMN person_age;

ALTER TABLE persons
ADD COLUMN age VARCHAR(10);

-- change data type of column
ALTER TABLE persons
ALTER COLUMN age TYPE INTEGER
USING age::integer;

-- set column a default value
ALTER TABLE persons
ADD COLUMN is_enabled VARCHAR(1);

ALTER TABLE persons
ALTER COLUMN is_enabled SET DEFAULT 'y';

INSERT INTO persons (first_name, last_name, nationality, age)
VALUES ('john', 'williams', 'american', 28);

SELECT * FROM persons;

-- add UNIQUE constrain
CREATE TABLE web_links (
    link_id SERIAL PRIMARY KEY,
    link_url VARCHAR(255) NOT NULL,
    link_target VARCHAR(20)
);
INSERT INTO web_links (link_url, link_target)
VALUES ('https://google.com', '_blank');

SELECT * FROM web_links;

ALTER TABLE web_links
ADD CONSTRAINT unique_web_url UNIQUE (link_url);

-- not works
INSERT INTO web_links (link_url, link_target)
VALUES ('https://google.com', '_blank');

INSERT INTO web_links (link_url, link_target)
VALUES ('https://amazon.com', '_blank');

-- to set a column to accept only defined allowed/acceptable values

ALTER TABLE web_links
ADD COLUMN is_enabled VARCHAR(2);

INSERT INTO web_links (link_url, link_target, is_enabled)
VALUES ('https://netflex.com', '_blank', 'Y');

ALTER TABLE web_links
ADD CHECK (is_enabled IN ('Y', 'N'));

INSERT INTO web_links (link_url, link_target, is_enabled)
VALUES ('https://vk.com', '_blank', 'Q');

UPDATE  web_links
SET is_enabled = 'Y'
WHERE is_enabled ISNULL;


