@echo off
cd /d "%~dp0"

where py >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set PYTHON_CMD=py
) else (
    where python >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        set PYTHON_CMD=python
    ) else (
        echo Python n'est pas installe ou n'est pas dans le PATH.
        pause
        exit /b 1
    )
)

%PYTHON_CMD% -m pip install -r requirements.txt
start http://localhost:8000
%PYTHON_CMD% -m uvicorn app:app --host 0.0.0.0 --port 8000
