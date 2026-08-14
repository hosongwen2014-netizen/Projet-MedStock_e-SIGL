--
-- PostgreSQL database dump
--

\restrict DBhIa326aYUgjOJ7J9noG1tYf6D2wyU6FHGE2E3BBu2HaLkks6as9zKV0NTucsF

-- Dumped from database version 15.19
-- Dumped by pg_dump version 15.19

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
-- Name: rafraichir_indicateurs_logistiques(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rafraichir_indicateurs_logistiques() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO indicateurs_logistiques (medicament_id, stock_actuel, cmm, sdu, qac, derniere_mise_a_jour)
    SELECT m.id, 0, 0, 0, 0, NOW()
    FROM medicaments m
    ON CONFLICT (medicament_id) DO NOTHING;

    UPDATE indicateurs_logistiques il
    SET stock_actuel = COALESCE((
        SELECT SUM(
            CASE
                WHEN ms.type_mouvement = 'ENTREE' THEN ms.quantite
                ELSE -ms.quantite
            END
        )
        FROM mouvements_stock ms
        WHERE ms.medicament_id = il.medicament_id
    ), 0),
        derniere_mise_a_jour = NOW();

    UPDATE indicateurs_logistiques il
    SET cmm = COALESCE((
        SELECT GREATEST(1, ROUND(AVG(periode_sortie)))
        FROM (
            SELECT SUM(ms.quantite) AS periode_sortie
            FROM mouvements_stock ms
            WHERE ms.medicament_id = il.medicament_id
              AND ms.type_mouvement = 'SORTIE'
              AND ms.date_mouvement >= NOW() - INTERVAL '90 days'
            GROUP BY date_trunc('month', ms.date_mouvement)
        ) x
    ), 0),
        sdu = COALESCE(
            (SELECT m.mois_securite FROM medicaments m WHERE m.id = il.medicament_id),
            1
        ) * COALESCE((
            SELECT GREATEST(1, ROUND(AVG(periode_sortie)))
            FROM (
                SELECT SUM(ms.quantite) AS periode_sortie
                FROM mouvements_stock ms
                WHERE ms.medicament_id = il.medicament_id
                  AND ms.type_mouvement = 'SORTIE'
                  AND ms.date_mouvement >= NOW() - INTERVAL '90 days'
                GROUP BY date_trunc('month', ms.date_mouvement)
            ) x
        ), 0),
        qac = GREATEST(0, (
            COALESCE((SELECT m.mois_objectif FROM medicaments m WHERE m.id = il.medicament_id), 3)
            * COALESCE((
                SELECT GREATEST(1, ROUND(AVG(periode_sortie)))
                FROM (
                    SELECT SUM(ms.quantite) AS periode_sortie
                    FROM mouvements_stock ms
                    WHERE ms.medicament_id = il.medicament_id
                      AND ms.type_mouvement = 'SORTIE'
                      AND ms.date_mouvement >= NOW() - INTERVAL '90 days'
                    GROUP BY date_trunc('month', ms.date_mouvement)
                ) x
            ), 0)
            - il.stock_actuel
        )),
        derniere_mise_a_jour = NOW()
    WHERE il.medicament_id IS NOT NULL;
END;
$$;


ALTER FUNCTION public.rafraichir_indicateurs_logistiques() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: indicateurs_logistiques; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.indicateurs_logistiques (
    medicament_id integer NOT NULL,
    stock_actuel integer DEFAULT 0 NOT NULL,
    cmm integer DEFAULT 0 NOT NULL,
    sdu integer DEFAULT 0 NOT NULL,
    qac integer DEFAULT 0 NOT NULL,
    derniere_mise_a_jour timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.indicateurs_logistiques OWNER TO postgres;

--
-- Name: medicaments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicaments (
    id integer NOT NULL,
    code_dci character varying(50) NOT NULL,
    nom_commercial character varying(150) NOT NULL,
    forme_pharmaceutique character varying(50),
    conditionnement integer NOT NULL,
    prix_achat_unitaire numeric(12,2) DEFAULT 0,
    prix_vente_unitaire numeric(12,2) DEFAULT 0,
    mois_securite integer DEFAULT 1,
    mois_objectif integer DEFAULT 3,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT medicaments_conditionnement_check CHECK ((conditionnement > 0))
);


ALTER TABLE public.medicaments OWNER TO postgres;

--
-- Name: medicaments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medicaments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medicaments_id_seq OWNER TO postgres;

--
-- Name: medicaments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medicaments_id_seq OWNED BY public.medicaments.id;


--
-- Name: mouvements_stock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mouvements_stock (
    id integer NOT NULL,
    uuid character varying(64) NOT NULL,
    medicament_id integer NOT NULL,
    type_mouvement character varying(20) NOT NULL,
    quantite integer NOT NULL,
    date_mouvement timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    lot_numero character varying(50),
    date_peremption date NOT NULL,
    pharmacie_id character varying(64) DEFAULT 'PHARMACIE_DEFAULT'::character varying NOT NULL,
    source character varying(30) DEFAULT 'OFFLINE'::character varying,
    statut_sync character varying(20) DEFAULT 'NON_SYNC'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT mouvements_stock_quantite_check CHECK ((quantite > 0)),
    CONSTRAINT mouvements_stock_source_check CHECK (((source)::text = ANY ((ARRAY['POS'::character varying, 'OFFLINE'::character varying, 'SYNC'::character varying, 'MANUEL'::character varying])::text[]))),
    CONSTRAINT mouvements_stock_statut_sync_check CHECK (((statut_sync)::text = ANY ((ARRAY['NON_SYNC'::character varying, 'SYNC'::character varying, 'ERREUR'::character varying])::text[]))),
    CONSTRAINT mouvements_stock_type_mouvement_check CHECK (((type_mouvement)::text = ANY ((ARRAY['ENTREE'::character varying, 'SORTIE'::character varying])::text[])))
);


ALTER TABLE public.mouvements_stock OWNER TO postgres;

--
-- Name: mouvements_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mouvements_stock_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mouvements_stock_id_seq OWNER TO postgres;

--
-- Name: mouvements_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mouvements_stock_id_seq OWNED BY public.mouvements_stock.id;


--
-- Name: medicaments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicaments ALTER COLUMN id SET DEFAULT nextval('public.medicaments_id_seq'::regclass);


--
-- Name: mouvements_stock id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_stock ALTER COLUMN id SET DEFAULT nextval('public.mouvements_stock_id_seq'::regclass);


--
-- Data for Name: indicateurs_logistiques; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.indicateurs_logistiques (medicament_id, stock_actuel, cmm, sdu, qac, derniere_mise_a_jour) FROM stdin;
1	9	3	3	0	2026-08-14 06:49:27.972404
\.


--
-- Data for Name: medicaments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicaments (id, code_dci, nom_commercial, forme_pharmaceutique, conditionnement, prix_achat_unitaire, prix_vente_unitaire, mois_securite, mois_objectif, created_at) FROM stdin;
1	MED001	Medicament Exemple	Comprime	1	0.00	0.00	1	3	2026-08-14 06:43:32.644819
\.


--
-- Data for Name: mouvements_stock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mouvements_stock (id, uuid, medicament_id, type_mouvement, quantite, date_mouvement, lot_numero, date_peremption, pharmacie_id, source, statut_sync, created_at) FROM stdin;
1	44444444-5555-6666-7777-000000000004	1	ENTREE	12	2026-08-14 07:40:00	LOT-004	2028-06-30	PHARM-001	OFFLINE	SYNC	2026-08-14 06:46:20.308197
2	55555555-6666-7777-8888-000000000005	1	SORTIE	3	2026-08-14 07:42:00	LOT-004	2028-06-30	PHARM-001	POS	SYNC	2026-08-14 06:49:27.965157
\.


--
-- Name: medicaments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medicaments_id_seq', 1, true);


--
-- Name: mouvements_stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mouvements_stock_id_seq', 2, true);


--
-- Name: indicateurs_logistiques indicateurs_logistiques_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.indicateurs_logistiques
    ADD CONSTRAINT indicateurs_logistiques_pkey PRIMARY KEY (medicament_id);


--
-- Name: medicaments medicaments_code_dci_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicaments
    ADD CONSTRAINT medicaments_code_dci_key UNIQUE (code_dci);


--
-- Name: medicaments medicaments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicaments
    ADD CONSTRAINT medicaments_pkey PRIMARY KEY (id);


--
-- Name: mouvements_stock mouvements_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_stock
    ADD CONSTRAINT mouvements_stock_pkey PRIMARY KEY (id);


--
-- Name: mouvements_stock mouvements_stock_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_stock
    ADD CONSTRAINT mouvements_stock_uuid_key UNIQUE (uuid);


--
-- Name: idx_mouvements_medicament_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mouvements_medicament_date ON public.mouvements_stock USING btree (medicament_id, date_mouvement);


--
-- Name: idx_mouvements_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mouvements_uuid ON public.mouvements_stock USING btree (uuid);


--
-- Name: indicateurs_logistiques indicateurs_logistiques_medicament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.indicateurs_logistiques
    ADD CONSTRAINT indicateurs_logistiques_medicament_id_fkey FOREIGN KEY (medicament_id) REFERENCES public.medicaments(id) ON DELETE CASCADE;


--
-- Name: mouvements_stock mouvements_stock_medicament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_stock
    ADD CONSTRAINT mouvements_stock_medicament_id_fkey FOREIGN KEY (medicament_id) REFERENCES public.medicaments(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict DBhIa326aYUgjOJ7J9noG1tYf6D2wyU6FHGE2E3BBu2HaLkks6as9zKV0NTucsF

