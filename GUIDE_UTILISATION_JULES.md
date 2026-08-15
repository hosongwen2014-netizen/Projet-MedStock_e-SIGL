# Guide d'Utilisation et de Fonctionnement de Jules (AI Software Engineer)

Ce guide complet vous explique exactement comment **Jules** fonctionne en interne, comment lui commander des projets ou fonctionnalités, et comment récupérer, tester et exécuter localement vos projets avec **Git / GitHub**, **VS Code** et **Docker**.

---

## Sommaire
1. [Fonctionnement Interne de Jules (Étape par Étape)](#1-fonctionnement-interne-de-jules-étape-par-étape)
2. [Comment Interagir avec Jules et Commander des Projets](#2-comment-interagir-avec-jules-et-commander-des-projets)
3. [Récupérer et Exécuter un Projet Jules sur votre Machine Local](#3-récupérer-et-exécuter-un-projet-jules-sur-votre-machine-locale)
   - [A. Gestion Git & GitHub (Branches et Pull Requests)](#a-gestion-git--github-branches-et-pull-requests)
   - [B. Utilisation avec VS Code](#b-utilisation-avec-vs-code)
   - [C. Déploiement et Test avec Docker & Docker Compose](#c-déploiement-et-test-avec-docker--docker-compose)
4. [Tutoriel Pratique Concret (Exemple sur Projet-MedStock_e-SIGL)](#4-tutoriel-pratique-concret-exemple-sur-projet-medstock_e-sigl)

---

## 1. Fonctionnement Interne de Jules (Étape par Étape)

Jules est un ingénieur logiciel virtuel autonome (AI Agent) conçu pour résoudre des problèmes, développer de nouvelles fonctionnalités, corriger des bugs et tester du code de manière rigoureuse. Voici le cycle de vie exact d'une tâche traitée par Jules :

### Étape 1 : Analyse de la demande & Mode Planification Profonde (Deep Planning)
- Lorsque vous confiez une mission à Jules, il commence par analyser votre besoin.
- **Mode Deep Planning** : Si la tâche nécessite des précisions, Jules passe en mode planification approfondie. Il pose des questions ciblées au lieu de deviner vos attentes. Il s'assure qu'aucun détail n'est laissé au hasard.
- Jules formule un plan d'action sous forme d'étapes numérotées au format Markdown via l'outil `set_plan`.

### Étape 2 : Exploration du Codebase (Recherche et Découverte)
- Jules explore le dépôt de code existant à l'aide d'outils spécialisés :
  - `list_files` : pour lister les dossiers et fichiers.
  - `read_file` : pour inspecter le contenu des fichiers de configuration (`package.json`, `requirements.txt`, `Dockerfile`, `README.md`, etc.) et du code source.
  - `run_in_bash_session` : pour exécuter des commandes de recherche (`grep`, `find`, etc.).

### Étape 3 : Exécution Autonome dans un Environnement Sandbox
- Jules travaille dans un environnement virtuel sécurisé (Sandbox Linux).
- Il possède un accès Bash pour :
  - Créer ou modifier des fichiers (`write_file`, `replace_with_git_merge_diff`).
  - Implémenter la logique métier et écrire des tests unitaires/d'intégration.
  - Installer des dépendances si nécessaire (`pip install`, `npm install`).
  - Lancer des conteneurs Docker ou démarrer des serveurs de développement en arrière-plan.

### Étape 4 : Vérification et Tests Proactifs
- **Principe d'auto-vérification** : Après chaque modification de fichier, Jules relit le fichier ou exécute des tests pour confirmer que la modification a réussi sans introduire de bugs.
- Il exécute les suites de tests existantes (`pytest`, `npm test`, scripts PowerShell/Bash).

### Étape 5 : État Pré-Commit (Pre-Commit Instructions)
- Avant de finaliser son travail, Jules appelle un ensemble de consignes de pré-validation (`pre_commit_instructions`).
- Il effectue une revue de code interne, s'assure que tout est propre, testé et documenté.

### Étape 6 : Soumission du Travail & Création de Branche Git
- Une fois tout validé, Jules prépare un commit propre avec un message descriptif.
- Il soumet ses modifications (`submit`) sur une branche Git dédiée (par exemple `jules/feature-medstock-api`) et ouvre/met à jour une Pull Request (PR) sur GitHub.

---

## 2. Comment Interagir avec Jules et Commander des Projets

Pour obtenir les meilleurs résultats avec Jules, voici les règles d'or :

1. **Être explicite sur les objectifs métier :**
   - *Exemple :* "Ajoute un endpoint REST `/api/statistiques` dans `app.py` qui renvoie la valeur totale du stock en pharmacie."
2. **Définir la portée et les contraintes :**
   - Précisez les technologies souhaitées (ex: FastAPI, PostgreSQL, Docker Compose, React, etc.).
3. **Laisser Jules poser des questions lors du Deep Planning :**
   - Répondez clairement à ses questions initiales. Cela lui permet d'avoir 100% de certitude avant de coder.
4. **Demander la création de tests et de documentation :**
   - Demandez à Jules de toujours inclure des tests d'intégration et une mise à jour des fichiers `README.md` ou `GUIDE.md`.

---

## 3. Récupérer et Exécuter un Projet Jules sur votre Machine Locale

Une fois que Jules a terminé son travail et a soumis la branche / Pull Request sur GitHub, voici comment récupérer le projet sur votre propre ordinateur.

### A. Gestion Git & GitHub (Branches et Pull Requests)

1. **Ouvrir votre terminal local** (Git Bash, PowerShell ou Terminal macOS/Linux).
2. **Récupérer les dernières mises à jour du dépôt GitHub :**
   ```bash
   git fetch origin
   ```
3. **Lister toutes les branches distantes (pour voir la branche créée par Jules) :**
   ```bash
   git branch -r
   ```
4. **Basculer sur la branche de Jules :**
   ```bash
   git checkout <nom_de_la_branche>
   # Exemple : git checkout jules/feature-medstock-api
   ```
5. **Si vous avez déjà la branche en local, mettez-la à jour :**
   ```bash
   git pull origin <nom_de_la_branche>
   ```

---

### B. Utilisation avec VS Code

1. **Ouvrir le projet dans VS Code :**
   - Lancer VS Code.
   - Aller dans **Fichier > Ouvrir le dossier...** (ou `File > Open Folder...`).
   - Sélectionner le dossier racine du projet.

2. **Visualiser les modifications apportées par Jules :**
   - Cliquez sur l'icône **Contrôle de source (Git)** dans la barre latérale gauche (ou raccourci `Ctrl+Shift+G`).
   - Vous pouvez comparer les fichiers modifiés par rapport à la branche principale (`main` / `master`).

3. **Ouvrir le Terminal Intégré de VS Code :**
   - Allez dans le menu **Terminal > Nouveau Terminal** (ou `Ctrl + ~`).
   - Assurez-vous d'être sur la bonne branche Git en vérifiant le coin inférieur gauche de VS Code.

---

### C. Déploiement et Test avec Docker & Docker Compose

Si le projet utilise Docker (comme ce projet MedStock) :

1. **Vérifier que Docker Desktop est démarré :**
   - Assurez-vous que l'icône Docker est active dans la barre des tâches.

2. **Configurer le fichier de variables d'environnement (`.env`) :**
   - Copiez le fichier d'exemple s'il existe :
     ```bash
     cp .env.example .env
     ```
   - Remplissez les mots de passe et configurations dans `.env`.

3. **Construire et démarrer les conteneurs Docker :**
   ```bash
   docker compose up --build -d
   ```
   *Explication :*
   - `--build` : Force la re-construction des images avec le nouveau code écrit par Jules.
   - `-d` : Exécute les conteneurs en arrière-plan (mode détaché).

4. **Vérifier l'état des conteneurs :**
   ```bash
   docker compose ps
   ```

5. **Consulter les logs (pour le débogage) :**
   ```bash
   docker compose logs -f
   ```

6. **Arrêter les conteneurs une fois terminé :**
   ```bash
   docker compose down
   ```

---

## 4. Tutoriel Pratique Concret (Exemple sur Projet-MedStock_e-SIGL)

Appliquons ces étapes sur le projet actuellement ouvert dans votre dépôt : **MedStock_e-SIGL**.

### Étape 1 : Récupérer le code sur votre terminal local
```bash
git fetch origin
git checkout main
```

### Étape 2 : Préparer les fichiers d'environnement
Créez un fichier `.env` à la racine du projet :
```env
POSTGRES_PASSWORD=votre_mot_de_passe_securise
MEDSTOCK_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000
```

### Étape 3 : Démarrer l'application avec Docker Compose
Exécutez dans votre terminal VS Code :
```bash
docker compose up --build -d
```
Cela lancera deux conteneurs :
1. `medstock_database` : Base de données PostgreSQL 15.
2. `medstock_backend_api` : API Web FastAPI (Python).

### Étape 4 : Tester l'API dans votre navigateur ou via `curl`

- **Vérifier la santé du service :**
  Ouvrez dans votre navigateur ou terminal :
  ```bash
  curl http://localhost:8000/health
  ```
  *Réponse attendue :*
  ```json
  {
    "status": "optimal",
    "database": "connected",
    "service": "MEDSTOCK",
    "timestamp": "2025-02-21T..."
  }
  ```

- **Consulter la documentation interactive de l'API (Swagger UI) :**
  Ouvrez dans votre navigateur web :
  [http://localhost:8000/docs](http://localhost:8000/docs)

- **Tester un enregistrement de mouvement de stock :**
  ```bash
  curl -X POST "http://localhost:8000/api/mouvements" \
    -H "Content-Type: application/json" \
    -d '[{
      "uuid": "test-uuid-1234567890",
      "medicament_id": 1,
      "type_mouvement": "ENTREE",
      "quantite": 50,
      "date_mouvement": "2025-02-21T10:00:00Z",
      "lot_numero": "LOT-2025-A",
      "date_peremption": "2026-12-31",
      "pharmacie_id": "PHARM-01",
      "source": "MANUEL"
    }]'
  ```

---

## Résumé du Workflow Idéal

1. **Proposer une mission à Jules** (en précisant le contexte et le besoin).
2. **Répondre aux questions de Jules** en mode Deep Planning.
3. **Laisser Jules développer, tester et soumettre la PR.**
4. **Récupérer la branche sur votre machine** (`git checkout <branche>`).
5. **Tester localement avec VS Code et Docker** (`docker compose up --build -d`).
6. **Valider et fusionner (merge) la PR sur GitHub.**
