# Basic integration checks for MedStock API
$base = 'http://localhost:8000'
Write-Output "Checking health at $base/health ..."
try {
    $h = Invoke-RestMethod -Uri "$base/health" -Method Get -ErrorAction Stop
    Write-Output "Health response: $h"
} catch {
    Write-Error "Health endpoint failed: $_"
    exit 2
}

$uuid = "test-integ-$(Get-Date -Format yyyyMMddHHmmss)"
$single = @{
    uuid = $uuid
    medicament_id = 1
    type_mouvement = "ENTREE"
    quantite = 1
    date_mouvement = (Get-Date).ToString("o")
    lot_numero = "LOT1"
    date_peremption = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
    pharmacie_id = "PHARM001"
    source = "OFFLINE"
}
# API expects a list of mouvements
$payload = @($single)
$json = ConvertTo-Json $payload -Depth 6
Write-Output "JSON to send: $json"
Write-Output "Posting mouvement with uuid=$uuid ..."
try {
    $resp = Invoke-RestMethod -Uri "$base/api/mouvements" -Method Post -Body $json -ContentType "application/json" -ErrorAction Stop
    Write-Output "POST response: $($resp | ConvertTo-Json -Depth 2)"
} catch {
    Write-Error "POST /api/mouvements failed: $_"
    exit 3
}

Write-Output "Integration tests passed." 
exit 0
