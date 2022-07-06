/*
 Create domain

 CREATE DOMAIN <name> <data_type> <constraint>

 Creating a domain allow you add your own data type with some validation
 in default return NULL and a created domain should return single value
 */

CREATE DOMAIN postal_code AS VARCHAR(10) NOT NULL
    CHECK (VALUE ~ '^\d{5}$' OR VALUE ~ '^\d{5}-\d{4}$');

CREATE TABLE addresses
(
    address_id  SERIAL PRIMARY KEY,
    postal_code postal_code
);

INSERT INTO addresses (postal_code)
VALUES ('10000'),
       ('10000-0000');

SELECT *
FROM addresses;

INSERT INTO addresses (postal_code)
VALUES ('1000000');

CREATE DOMAIN true_color AS TEXT CHECK (value IN ('black', 'white'));

CREATE TABLE colors
(
    color true_color
);

INSERT INTO colors
VALUES ('black'),
       ('white');
INSERT INTO colors
VALUES ('red');
SELECT *
FROM colors;

-- to get list of all domain data types
SELECT typname
FROM pg_catalog.pg_type
         JOIN pg_catalog.pg_namespace ON pg_type.typnamespace = pg_namespace.oid
WHERE typtype = 'd'
  AND nspname = 'public'
-- or other schema;

/*
 Composite data types
 1. List of fields names with corresponding data types
 2. Used in table as a column
 3. Used in func or procedures
 4. Can return multiple values, its a composite type

 CREATE TYPE <NAME> AS (<FIELD> <COLUMN PROPERTIES> FIELD <COLUMN PROPERTIES> and so on...)
 */
CREATE TYPE address AS
(
    city    VARCHAR(50),
    country VARCHAR(20)
);

CREATE TABLE companies
(
    com_id  SERIAL PRIMARY KEY,
    address address
);

INSERT INTO companies (address)
VALUES (ROW ('london', 'uk'));
INSERT INTO companies (address)
VALUES (ROW ('moscow', 'ru'));
INSERT INTO companies (address)
VALUES (ROW ('new_york', 'us'));

SELECT *
FROM companies;

SELECT (address).country
FROM companies;
SELECT (address).city
FROM companies;

SELECT (companies.address).city
FROM companies;

CREATE TYPE inventory_item AS
(
    name       VARCHAR(200),
    suplier_id INT,
    price      NUMERIC
);

CREATE TABLE inventory
(
    inventory_id SERIAL PRIMARY KEY,
    item         inventory_item
);

INSERT INTO inventory (item)
VALUES (ROW ('pen', 10, 104.4));

INSERT INTO inventory (item)
VALUES (ROW ('paper', 20, 10.94));

SELECT (inventory.item).name
FROM inventory
WHERE (item).price > 3.99;


CREATE TYPE currency AS ENUM ('USD', 'EUR', 'GBP');

SELECT 'USD'::CURRENCY;

ALTER TYPE currency ADD VALUE 'CHF' AFTER 'EUR';

CREATE TABLE stocks
(
    stock_id       SERIAL PRIMARY KEY,
    stock_currency currency
);

INSERT INTO stocks (stock_currency)
VALUES ('USD'),
       ('CHF');
SELECT *
FROM stocks;

