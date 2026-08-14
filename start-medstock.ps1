$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$pythonCmd = $null
if (Get-Command py -ErrorAction SilentlyContinue) { $pythonCmd = "py" }
elseif (Get-Command python -ErrorAction SilentlyContinue) { $pythonCmd = "python" }
else {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH."
    exit 1
}

& $pythonCmd -m pip install -r requirements.txt
Start-Process "http://localhost:8000"
& $pythonCmd -m uvicorn app:app --host 0.0.0.0 --port 8000
