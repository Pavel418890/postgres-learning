/*
 hstore data type
 1. stored key-value pairs
 2. key value must be a string only

 */

CREATE EXTENSION IF NOT EXISTS hstore;

CREATE TABLE table_hstore
(
    book_id   SERIAL PRIMARY KEY,
    title     VARCHAR(100) NOT NULL,
    book_info hstore
);

INSERT INTO table_hstore(title, book_info)
VALUES ('book 1',
        '
            "publisher" => "abc publisher",
            "paper_cost" => "23.78",
            "e_cost" => "5.89"
        ');


INSERT INTO table_hstore(title, book_info)
VALUES ('book 2',
        '
            "publisher" => "abc publisher",
            "paper_cost" => "43.78",
            "e_cost" => "55.89"
        ');
SELECT *
FROM table_hstore;

SELECT book_info -> 'publisher'  AS "Publisher",
       book_info -> 'paper_cost' AS "Paper Cost",
       book_info -> 'e_cost'     AS "Electron Cost"
FROM table_hstore;


/*
 Network data types

 cidr       7 or 19 bytes   IPv4 and IPv6 for networks
 inet       7 or 19 bytes   IPv4 and IPv6 for networks and hosts
 macaddr    6 bytes         MAC addresses
 macaddr8   8 bytes         MAC addresses (EUI-64 format)

 is better to use these types instead of plain text to store network addresses,
 because these types offer input error checking and specialized operators and
 functions

 have special sorting mechanism
    when sorting inet or cidr data types, IPv4 will always sorting before IPv6
    including IPv4 addresses encapsulated or mapped to IPv6 addresses

 have special index support
 */
CREATE TABLE table_netaddr
(
    id SERIAL PRIMARY KEY,
    ip INET
)

INSERT INTO table_netaddr (ip)
VALUES ('192.254.89.39'),
       ('10.254.89.39'),
       ('255.254.89.39'),
       ('10.254.255.39'),
       ('14.254.89.39');

SELECT ip,
       set_masklen(ip, 24) as inet_24,
       set_masklen(ip::cidr, 24) as cird_24,
       set_masklen(ip::cidr, 27) as cird_27,
       set_masklen(ip::cidr, 28) as cird_28
FROM table_netaddr;
