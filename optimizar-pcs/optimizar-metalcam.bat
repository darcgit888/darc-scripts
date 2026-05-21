@echo off
REM ============================================================
REM Optimizador de PCs Metalcam - Lanzador
REM Doble click aqui para correr el script con permisos admin
REM ============================================================

REM Verificar si ya estamos como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Ya somos admin - ejecutar el script PowerShell
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\optimize-metalcam-pc.ps1"

pause
