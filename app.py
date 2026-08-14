import os
import time
from datetime import datetime
from typing import List

import psycopg2
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from psycopg2.extras import RealDictCursor
from pydantic import BaseModel, Field, field_validator


def get_allowed_origins() -> list[str]:
    raw = os.getenv(
        "MEDSTOCK_ALLOWED_ORIGINS",
        "http://localhost:3000,http://127.0.0.1:5500,http://localhost:8000,https://medstock-benin.org",
    )
    return [item.strip() for item in raw.split(",") if item.strip()]


app = FastAPI(
    title="MEDSTOCK Web API",
    description="Plateforme de gestion logistique et de dispensation de produits de santé",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=get_allowed_origins(),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["*"],
)


def get_db_connection():
    last_error = None
    for attempt in range(1, 11):
        try:
            return psycopg2.connect(
                host=os.getenv("POSTGRES_HOST", "localhost"),
                database=os.getenv("POSTGRES_DB", "medstock_db"),
                user=os.getenv("POSTGRES_USER", "postgres"),
                password=os.getenv("POSTGRES_PASSWORD", "postgres"),
                port=os.getenv("POSTGRES_PORT", "5432"),
                connect_timeout=5,
                cursor_factory=RealDictCursor,
            )
        except psycopg2.OperationalError as exc:
            last_error = exc
            if attempt < 10:
                time.sleep(2)
                continue
            raise RuntimeError(f"Base de données indisponible après 10 tentatives: {exc}") from exc

    if last_error is not None:
        raise RuntimeError(f"Base de données indisponible: {last_error}")
    raise RuntimeError("Base de données indisponible")


class MouvementStockSchema(BaseModel):
    uuid: str = Field(..., min_length=10, max_length=64)
    medicament_id: int = Field(..., gt=0)
    type_mouvement: str
    quantite: int = Field(..., gt=0)
    date_mouvement: datetime
    lot_numero: str = Field(..., min_length=1)
    date_peremption: str = Field(..., min_length=1)
    pharmacie_id: str = Field(..., min_length=1, max_length=64)
    source: str = Field(default="OFFLINE", min_length=1, max_length=20)

    @field_validator("type_mouvement")
    @classmethod
    def validate_type(cls, value: str) -> str:
        normalized = value.strip().upper()
        if normalized not in {"ENTREE", "SORTIE"}:
            raise ValueError("Le type de mouvement doit être ENTREE ou SORTIE.")
        return normalized

    @field_validator("source")
    @classmethod
    def validate_source(cls, value: str) -> str:
        normalized = value.strip().upper()
        if normalized not in {"POS", "OFFLINE", "SYNC", "MANUEL"}:
            raise ValueError("La source du mouvement est invalide.")
        return normalized


@app.get("/health")
def health_check():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        status = "connected"
        cursor.close()
        conn.close()
    except Exception:
        status = "disconnected"
    return {
        "status": "optimal" if status == "connected" else "degraded",
        "database": status,
        "service": "MEDSTOCK",
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


@app.post("/api/mouvements", status_code=201)
def enregistrer_mouvements(mouvements: List[MouvementStockSchema]):
    conn = get_db_connection()
    cursor = conn.cursor()
    inserted = 0
    duplicates_ignored = 0

    try:
        for m in mouvements:
            cursor.execute("SELECT 1 FROM mouvements_stock WHERE uuid = %s LIMIT 1", (m.uuid,))
            if cursor.fetchone():
                duplicates_ignored += 1
                continue

            cursor.execute(
                """
                INSERT INTO mouvements_stock (
                    uuid, medicament_id, type_mouvement, quantite, date_mouvement,
                    lot_numero, date_peremption, pharmacie_id, source, statut_sync
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    m.uuid,
                    m.medicament_id,
                    m.type_mouvement,
                    m.quantite,
                    m.date_mouvement,
                    m.lot_numero,
                    m.date_peremption,
                    m.pharmacie_id,
                    m.source,
                    "SYNC",
                ),
            )
            inserted += 1

        conn.commit()
        cursor.execute("SELECT rafraichir_indicateurs_logistiques();")
        conn.commit()

        return {
            "status": "success",
            "inserted": inserted,
            "duplicates_ignored": duplicates_ignored,
            "total_received": len(mouvements),
            "message": f"{inserted} mouvements enregistrés, {duplicates_ignored} doublons ignorés.",
        }
    except Exception as exc:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(exc))
    finally:
        cursor.close()
        conn.close()


@app.get("/api/logistique/alertes")
def obtenir_alertes_stock():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """
            SELECT m.nom_commercial, m.code_dci, il.stock_actuel, il.cmm, il.sdu, il.qac
            FROM indicateurs_logistiques il
            JOIN medicaments m ON m.id = il.medicament_id
            WHERE il.stock_actuel <= il.sdu
            ORDER BY il.stock_actuel ASC
            """
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()
