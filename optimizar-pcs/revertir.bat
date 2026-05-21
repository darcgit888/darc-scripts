@echo off
REM ============================================================
REM Revertidor de PCs Metalcam - Lanzador
REM Doble click aqui si algo no funciono despues de optimizar
REM ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\revertir-metalcam-pc.ps1"

pause
