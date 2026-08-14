CREATE TABLE IF NOT EXISTS medicaments (
    id SERIAL PRIMARY KEY,
    code_dci VARCHAR(50) UNIQUE NOT NULL,
    nom_commercial VARCHAR(150) NOT NULL,
    forme_pharmaceutique VARCHAR(50),
    conditionnement INT NOT NULL CHECK (conditionnement > 0),
    prix_achat_unitaire NUMERIC(12, 2) DEFAULT 0,
    prix_vente_unitaire NUMERIC(12, 2) DEFAULT 0,
    mois_securite INT DEFAULT 1,
    mois_objectif INT DEFAULT 3,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mouvements_stock (
    id SERIAL PRIMARY KEY,
    uuid VARCHAR(64) NOT NULL UNIQUE,
    medicament_id INT NOT NULL REFERENCES medicaments(id) ON DELETE RESTRICT,
    type_mouvement VARCHAR(20) NOT NULL CHECK (type_mouvement IN ('ENTREE', 'SORTIE')),
    quantite INT NOT NULL CHECK (quantite > 0),
    date_mouvement TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    lot_numero VARCHAR(50),
    date_peremption DATE NOT NULL,
    pharmacie_id VARCHAR(64) NOT NULL DEFAULT 'PHARMACIE_DEFAULT',
    source VARCHAR(30) DEFAULT 'OFFLINE' CHECK (source IN ('POS', 'OFFLINE', 'SYNC', 'MANUEL')),
    statut_sync VARCHAR(20) DEFAULT 'NON_SYNC' CHECK (statut_sync IN ('NON_SYNC', 'SYNC', 'ERREUR')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mouvements_medicament_date
    ON mouvements_stock (medicament_id, date_mouvement);

CREATE INDEX IF NOT EXISTS idx_mouvements_uuid
    ON mouvements_stock (uuid);

CREATE TABLE IF NOT EXISTS indicateurs_logistiques (
    medicament_id INT PRIMARY KEY REFERENCES medicaments(id) ON DELETE CASCADE,
    stock_actuel INT NOT NULL DEFAULT 0,
    cmm INT NOT NULL DEFAULT 0,
    sdu INT NOT NULL DEFAULT 0,
    qac INT NOT NULL DEFAULT 0,
    derniere_mise_a_jour TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION rafraichir_indicateurs_logistiques()
RETURNS VOID
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

