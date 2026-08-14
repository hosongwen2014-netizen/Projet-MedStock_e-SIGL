const DEFAULT_API_BASE_URL = "http://localhost:8000";
const DB_NAME = "MedstockLocal";
const DB_VERSION = 2;
let db;

function getApiBaseUrl() {
  const configured =
    window.MEDSTOCK_CONFIG?.apiBaseUrl ||
    localStorage.getItem("medstock_api_base_url") ||
    DEFAULT_API_BASE_URL;

  return String(configured).replace(/\/$/, "");
}

function generateUuid() {
  if (window.crypto && typeof window.crypto.randomUUID === "function") {
    return window.crypto.randomUUID();
  }

  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (char) => {
    const random = Math.random() * 16 | 0;
    const value = char === "x" ? random : (random & 0x3) | 0x8;
    return value.toString(16);
  });
}

function getDefaultPharmacieId() {
  return localStorage.getItem("medstock_pharmacie_id") || "PHARMACIE_DEFAULT";
}

function openMedstockDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const database = event.target.result;

      if (!database.objectStoreNames.contains("file_attente_mouvements")) {
        const store = database.createObjectStore("file_attente_mouvements", {
          keyPath: "id_local",
          autoIncrement: true,
        });
        store.createIndex("statut_idx", "statut", { unique: false });
        store.createIndex("uuid_idx", "uuid", { unique: true });
      }
    };

    request.onsuccess = (event) => {
      db = event.target.result;
      window.addEventListener("online", verifierEtSynchroniserMouvements);
      resolve(db);
    };

    request.onerror = (event) => {
      reject(event.target.error);
    };
  });
}

function readAllPendingMovements() {
  return new Promise((resolve, reject) => {
    if (!db) {
      reject(new Error("Base IndexedDB non initialisée"));
      return;
    }

    const transaction = db.transaction(["file_attente_mouvements"], "readonly");
    const store = transaction.objectStore("file_attente_mouvements");
    const request = store.getAll();

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error || new Error("Impossible de lire les mouvements locaux"));
  });
}

function stockerMouvementLocal(medicamentId, typeMouvement, quantite, lotNumero, datePeremption) {
  if (!db) {
    console.error("Base IndexedDB non initialisée");
    return;
  }

  const transaction = db.transaction(["file_attente_mouvements"], "readwrite");
  const store = transaction.objectStore("file_attente_mouvements");

  const nowIso = new Date().toISOString();
  const mouvement = {
    uuid: generateUuid(),
    medicament_id: Number(medicamentId),
    type_mouvement: String(typeMouvement).trim().toUpperCase(),
    quantite: Number(quantite),
    date_mouvement: nowIso,
    lot_numero: String(lotNumero).trim(),
    date_peremption: String(datePeremption).trim(),
    pharmacie_id: getDefaultPharmacieId(),
    source: navigator.onLine ? "POS" : "OFFLINE",
    statut: "EN_ATTENTE",
    created_at: nowIso,
  };

  store.add(mouvement);

  transaction.oncomplete = () => {
    console.log("Mouvement enregistré localement", mouvement.uuid);
    if (navigator.onLine) {
      verifierEtSynchroniserMouvements();
    }
  };

  transaction.onerror = () => {
    console.error("Erreur d'écriture locale");
  };
}

async function verifierEtSynchroniserMouvements() {
  if (!navigator.onLine || !db) return;

  try {
    const mouvements = (await readAllPendingMovements()).filter((m) => m.statut === "EN_ATTENTE");

    if (!mouvements.length) {
      console.log("Aucun mouvement en attente");
      return;
    }

    const payload = mouvements.map(({ id_local, statut, created_at, source, ...mouvement }) => ({
      ...mouvement,
      source: mouvement.source || "OFFLINE",
    }));

    const response = await fetch(`${getApiBaseUrl()}/api/mouvements`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erreur serveur: ${response.status} - ${errorText}`);
    }

    const result = await response.json();

    const transaction = db.transaction(["file_attente_mouvements"], "readwrite");
    const store = transaction.objectStore("file_attente_mouvements");

    for (const mouvement of mouvements) {
      const updated = { ...mouvement, statut: "SYNC", source: mouvement.source || "SYNC" };
      store.put(updated);
    }

    console.log("Synchronisation réussie", result);
  } catch (error) {
    console.error("Échec de synchronisation:", error);
  }
}

openMedstockDB().then(() => {
  console.log("MEDSTOCK offline ready");
  console.log("Serveur configuré:", getApiBaseUrl());
});
