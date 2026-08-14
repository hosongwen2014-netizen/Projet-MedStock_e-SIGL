# Dump MedStock DB from Postgres container to host
$dest = "./artifacts/medstock_db_dump_$(Get-Date -Format yyyyMMdd_HHmmss).sql"
Write-Output "Creating dump inside container..."
docker exec medstock_database sh -c "pg_dump -U postgres medstock_db > /tmp/medstock_db_dump.sql"
Write-Output "Copying dump to host: $dest"
docker cp medstock_database:/tmp/medstock_db_dump.sql $dest
Write-Output "Done. Dump at: $dest"
