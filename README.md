# Projet MedStock_e-SIGL

Ce dépôt contient la version autonome du projet MedStock (export depuis 18-EITHING).

Pré-requis : Docker Desktop (WSL2 recommandé).

Démarrage local :

1. Copier `.env.example` en `.env` et remplir les variables (POSTGRES_PASSWORD...)
2. Lancer :

   docker compose -f medstock/docker-compose.yml up --build -d

3. Vérifier l'API :

   curl http://localhost:8000/health

Tests d'intégration simples :

- Le workflow CI définit une vérification basique qui démarre les services et poste un mouvement test.

Scripts utiles :
- `medstock/scripts/dump_db.ps1` : crée un dump SQL vers `medstock/artifacts/`.
- `medstock/scripts/run_integration_tests.ps1` : test d'intégration PowerShell (Windows).

Notes : Ne pas committer `.env` ni `medstock/artifacts`.
