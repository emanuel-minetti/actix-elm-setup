--
-- Needs to be run (via psql) with sufficient grants (e.g. as user 'postgres')
--

-- Dumped from database version 15.7
-- Dumped by pg_dump version 15.7

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

--
-- Name: aes; Type: DATABASE; Schema: -; Owner: aes
--

CREATE DATABASE aes WITH ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_Germany.1252';


ALTER DATABASE aes OWNER TO aes;

\connect aes

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
-- Name: user; Type: TABLE; Schema: public; Owner: aes
--

CREATE TABLE aes.public."user" (
    id integer NOT NULL,
    account_name character varying NOT NULL,
    pw_hash character varying NOT NULL
);


ALTER TABLE aes.public."user" OWNER TO aes;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: aes
--

ALTER TABLE aes.public."user" ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME aes.public."user_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: aes
--

INSERT INTO public."user" OVERRIDING SYSTEM VALUE VALUES (1, 'emu', 'test');


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: aes
--

SELECT pg_catalog.setval('aes.public.user_id_seq', 1, true);


--
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: aes
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk PRIMARY KEY (id);


--
-- Name: user user_pk_2; Type: CONSTRAINT; Schema: public; Owner: aes
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk_2 UNIQUE (account_name);


--
-- PostgreSQL database dump complete
--

