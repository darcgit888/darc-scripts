# ============================================================
# Revertidor de PCs Metalcam
# Deshace los cambios del script de optimizacion
# Repo: github.com/darcgit888/darc-scripts
# Versión: 2026-05-21
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Continue'

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Yellow
    Write-Host $Text -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Yellow
}

function Write-Step  { param([string]$T) Write-Host "  [+] $T" -ForegroundColor White }
function Write-Done  { param([string]$T) Write-Host "      OK: $T" -ForegroundColor Green }
function Write-Warn  { param([string]$T) Write-Host "      ! $T" -ForegroundColor Yellow }

Clear-Host
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "    REVERTIDOR DE PCs - METALCAM" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Este script deshace los cambios del optimizador." -ForegroundColor Gray
Write-Host "  Usa esto si algo dejo de funcionar despues de optimizar." -ForegroundColor Gray
Write-Host ""
Write-Host "  NOTA: El bloatware del Microsoft Store NO se puede" -ForegroundColor Red
Write-Host "  restaurar automaticamente (se reinstala manualmente" -ForegroundColor Red
Write-Host "  desde la Tienda de Microsoft si se necesita)." -ForegroundColor Red
Write-Host ""
$confirm = Read-Host "  Escribir 'SI' para continuar con la reversion total"

if ($confirm -ne "SI") {
    Write-Host ""
    Write-Host "  Reversion cancelada." -ForegroundColor Yellow
    exit
}

# ========== REVERTIR NIVEL 1 ==========
Write-Title "REVIRTIENDO NIVEL 1 - Configuraciones basicas"

Write-Step "Restaurando plan de energia a 'Balanceado'"
try {
    powercfg -setactive SCHEME_BALANCED | Out-Null
    Write-Done "Plan de energia: Balanceado"
} catch { Write-Warn "No se pudo cambiar plan de energia" }

Write-Step "Restaurando efectos visuales a configuracion de Windows"
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0
    Write-Done "Efectos visuales: Windows decide (default)"
} catch { Write-Warn "Efectos visuales no se pudieron revertir" }

Write-Step "Restaurando OneDrive al arranque"
try {
    $oneDrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    if (Test-Path $oneDrivePath) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -Value "`"$oneDrivePath`" /background"
        Write-Done "OneDrive regresado al arranque"
    } else {
        Write-Warn "OneDrive no esta instalado en esta PC"
    }
} catch { Write-Warn "No se pudo restaurar OneDrive" }

Write-Step "Habilitando notificaciones"
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 1 -ErrorAction SilentlyContinue
    Write-Done "Notificaciones habilitadas"
} catch { Write-Warn "Notificaciones parciales" }

# ========== REVERTIR NIVEL 2 ==========
Write-Title "REVIRTIENDO NIVEL 2 - Servicios de Windows"

$serviciosAReactivar = @{
    "Fax"              = "Servicio de Fax"
    "XboxGipSvc"       = "Xbox Game Input"
    "XblAuthManager"   = "Xbox Live Auth"
    "XblGameSave"      = "Xbox Live Game Save"
    "XboxNetApiSvc"    = "Xbox Live Networking"
    "WSearch"          = "Windows Search"
    "DiagTrack"        = "Telemetria de Microsoft"
    "dmwappushservice" = "Mensajes WAP push"
    "MapsBroker"       = "Mapas descargados"
}

foreach ($svc in $serviciosAReactivar.Keys) {
    Write-Step "Reactivando: $($serviciosAReactivar[$svc])"
    try {
        Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Done "Servicio '$svc' reactivado"
    } catch { Write-Warn "Servicio '$svc' no existe en esta PC" }
}

Write-Step "Reactivando Print Spooler"
try {
    Set-Service -Name "Spooler" -StartupType Automatic -ErrorAction Stop
    Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
    Write-Done "Print Spooler reactivado"
} catch { Write-Warn "No se pudo reactivar Print Spooler" }

# ========== REVERTIR NIVEL 3 ==========
Write-Title "REVIRTIENDO NIVEL 3 - Configuraciones profundas"

Write-Step "Reactivando apps en segundo plano"
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0
    Write-Done "Apps en segundo plano: reactivadas"
} catch { Write-Warn "No se pudo reactivar apps en segundo plano" }

Write-Step "Reactivando Cortana"
try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue
    Write-Done "Cortana reactivada"
} catch { Write-Warn "No se pudo reactivar Cortana" }

Write-Warn "Bloatware (Xbox, Skype, Solitaire) NO se puede restaurar automaticamente."
Write-Warn "Si los necesitas, reinstalalos desde la Tienda de Microsoft."

# ========== REVERTIR NIVEL 4 ==========
Write-Title "REVIRTIENDO NIVEL 4 - Configuracion Edge"

Write-Step "Removiendo politicas de Edge"
try {
    Remove-Item -Path "HKLM:\Software\Policies\Microsoft\Edge" -Recurse -ErrorAction SilentlyContinue
    Write-Done "Politicas de Edge removidas (Edge usara sus valores default)"
} catch { Write-Warn "No habia politicas de Edge que remover" }

# ========== RESUMEN ==========
Write-Title "REVERSION COMPLETA"
Write-Host ""
Write-Host "  La PC fue revertida a sus configuraciones anteriores." -ForegroundColor Green
Write-Host "  Se recomienda REINICIAR para aplicar todos los cambios." -ForegroundColor Yellow
Write-Host ""
Read-Host "  Presiona Enter para terminar"
