# MEDSTOCK

This folder contains a lightweight stock and dispensing prototype for an offline-first pharmacy workflow.

## Structure

- `app.py` — FastAPI backend
- `schema.sql` — PostgreSQL schema and stock refresh logic
- `medstock_offline.js` — IndexedDB queue for offline sales
- `index.html` — comptoir interface demo
- `dhis2_export.py` — DHIS2 monthly payload helper
- `.env.example` — environment variables
- `requirements.txt` — Python dependencies

## Quick start

1. Create PostgreSQL database `medstock_db`.
2. Run `schema.sql`.
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Start the API:
   ```bash
   uvicorn app:app --reload --host 0.0.0.0 --port 8000
   ```
5. Open the browser demo: `index.html`.

## Offline behavior

When internet is unavailable, the browser stores movements in IndexedDB and sends them automatically once connectivity returns.
