import os
from typing import Dict, List

import requests
from requests.auth import HTTPBasicAuth

DHIS2_URL = os.getenv("DHIS2_URL", "https://dhis2-benin.org/api/dataValueSets")
DHIS2_USER = os.getenv("DHIS2_USER", "identifiant_medstock")
DHIS2_PASSWORD = os.getenv("DHIS2_PASSWORD", "mot_de_passe_securise")

DATA_ELEMENT_MAP = {
    "stock_initial": "DE_STOCK_INITIAL",
    "quantite_entree": "DE_QUANTITE_ENTREE",
    "quantite_sortie": "DE_QUANTITE_SORTIE",
    "stock_final": "DE_STOCK_FINAL",
    "jours_rupture": "DE_JOURS_RUPTURE",
}


def build_monthly_payload(period: str, org_unit_id: str, rows: List[Dict[str, int]]) -> Dict:
    data_values = []
    for row in rows:
        coc = f"COC_{row['code_dci']}"
        for key, data_element in DATA_ELEMENT_MAP.items():
            data_values.append({
                "dataElement": data_element,
                "categoryOptionCombo": coc,
                "value": str(row[key]),
                "period": period,
                "orgUnit": org_unit_id,
            })

    return {
        "dataSet": "DATASET_LOGISTIQUE_MEDICAMENTS",
        "completeDate": f"{period[:4]}-{period[4:6]}-01",
        "period": period,
        "orgUnit": org_unit_id,
        "dataValues": data_values,
    }


def send_monthly_report(period: str, org_unit_id: str, rows: List[Dict[str, int]]):
    payload = build_monthly_payload(period, org_unit_id, rows)
    response = requests.post(
        DHIS2_URL,
        json=payload,
        auth=HTTPBasicAuth(DHIS2_USER, DHIS2_PASSWORD),
        headers={"Content-Type": "application/json"},
        timeout=30,
    )
    response.raise_for_status()
    return response.json()
