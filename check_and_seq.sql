/*
 CHECK constraint
 attach come requirements to the column using boolean expression
 to evaluate the value before insert/update operation happened.

 */

CREATE TABLE staff
(
    staff_id    serial PRIMARY KEY,
    first_name  varchar(50),
    last_name   varchar(50),
    birth_date  date CHECK (birth_date > '1990-01-01'),
    joined_date date CHECK (joined_date > birth_date),
    salary      numeric CHECK (salary > 0)
);


INSERT INTO staff(first_name, last_name, birth_date, joined_date, salary)
VALUES ('John', 'Doe', '1994-05-12', '2002-05-12', 1000);

SELECT *
FROM staff;
-- errors
INSERT INTO staff(first_name, last_name, birth_date, joined_date, salary)
VALUES ('John1', 'Doe2', '1989-05-12', '2002-05-12', 1000),
       ('John2', 'Doe3', '1994-05-12', '1993-05-12', 1000),
       ('John3', 'Doe4', '1994-05-12', '2002-05-12', -1000);


UPDATE staff
SET salary = 0
WHERE staff_id = 1;

--define CHECK constraint for existing table
CREATE TABLE prices
(
    price_id   serial PRIMARY KEY,
    product_id int     NOT NULL,
    price      numeric NOT NULL,
    discount   numeric NOT NULL,
    valid_from date    NOT NULL
);
ALTER TABLE prices
    ADD CONSTRAINT price_check
        CHECK (price > 0 AND discount >= 0 AND price > discount)

SELECT *
FROM prices;

INSERT INTO prices (product_id, price, discount, valid_from)
VALUES ('1', 100, 20, '2020-01-02');

INSERT INTO prices (product_id, price, discount, valid_from)
VALUES ('2', 100, 120, '2020-01-02');

-- rename constraint
ALTER TABLE prices
    RENAME CONSTRAINT price_check TO price_discount_check;

-- drop constraint

alter table prices
drop CONSTRAINT price_discount_check;

/*
 SEQUENCE

 */

 create sequence test_seq
start with 200
increment 20
minvalue 100
maxvalue 300
cycle;

select nextval('test_seq');

select setval('test_seq', 400);