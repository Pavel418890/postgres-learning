--
-- PostgreSQL database dump
--

-- Dumped from database version 14.3 (Debian 14.3-1.pgdg110+1)
-- Dumped by pg_dump version 14.3 (Ubuntu 14.3-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: plots
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    first_name character varying(100),
    last_name character varying(255)
);


ALTER TABLE public.customers OWNER TO plots;

--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: plots
--

COPY public.customers (customer_id, first_name, last_name) FROM stdin;
1	John	Doe
2	Jeff	Smith
3	Mike	Steel
4	Mark	Benjamin
5	Hannah	Rose
\.


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: plots
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- PostgreSQL database dump complete
--

