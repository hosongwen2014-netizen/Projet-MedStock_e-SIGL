-- Init data for MedStock
-- Insert a sample medicament used by tests if it doesn't exist
INSERT INTO medicaments (code_dci, nom_commercial, forme_pharmaceutique, conditionnement, prix_achat_unitaire, prix_vente_unitaire, mois_securite, mois_objectif)
SELECT 'MED001', 'Medicament Exemple', 'Comprime', 1, 0.00, 0.00, 1, 3
WHERE NOT EXISTS (SELECT 1 FROM medicaments WHERE code_dci = 'MED001');

-- Refresh indicators
SELECT rafraichir_indicateurs_logistiques();

