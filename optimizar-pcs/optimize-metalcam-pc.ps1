# ============================================================
# Optimizador de PCs Metalcam
# Política completa: docs/HERRAMIENTAS.md
# Versión: 2026-05-21
# Editable libremente. Idempotente (correr varias veces es seguro).
# ============================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Continue'

# ========== HELPERS DE PRESENTACIÓN ==========
function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "  [+] $Text" -ForegroundColor White
}

function Write-Done {
    param([string]$Text)
    Write-Host "      OK: $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "      ! $Text" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Text)
    Write-Host "      X $Text" -ForegroundColor Red
}

# ========== NIVEL 1: BASICO (cambios que se sienten al instante) ==========
function Apply-Nivel1 {
    Write-Title "NIVEL 1 - Optimizaciones basicas"

    # 1. Plan de energia: Alto rendimiento
    Write-Step "Cambiando plan de energia a Alto Rendimiento"
    try {
        powercfg -setactive SCHEME_MIN | Out-Null
        Write-Done "Plan de energia: Alto Rendimiento"
    } catch { Write-Warn "No se pudo cambiar plan de energia" }

    # 2. Visual effects mínimos
    Write-Step "Desactivando animaciones y efectos visuales"
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction Stop
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction Stop
        Write-Done "Efectos visuales en modo 'Mejor rendimiento'"
    } catch { Write-Warn "Algunos efectos visuales no se pudieron tocar" }

    # 3. Desactivar OneDrive autostart (Metalcam usa Google Drive)
    Write-Step "Desactivando OneDrive del arranque (Metalcam usa Google Drive)"
    try {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
        Write-Done "OneDrive ya no arranca con Windows"
    } catch { Write-Warn "OneDrive no estaba en arranque" }

    # 4. Desactivar Apps de inicio innecesarias comunes
    Write-Step "Desactivando apps de inicio innecesarias (Skype, Teams personal, Spotify, etc.)"
    $appsAQuitar = @("Skype", "Teams", "Spotify", "Discord", "Steam", "Adobe Updater")
    foreach ($app in $appsAQuitar) {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $app -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $app -ErrorAction SilentlyContinue
    }
    Write-Done "Apps de arranque limpias"

    # 5. Desactivar Notificaciones de Focus Assist y telemetría básica
    Write-Step "Desactivando notificaciones intrusivas"
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Value 0 -ErrorAction SilentlyContinue
        Write-Done "Notificaciones bajo control"
    } catch { Write-Warn "Notificaciones parciales" }
}

# ========== NIVEL 2: SERVICIOS WINDOWS INNECESARIOS ==========
function Apply-Nivel2 {
    Write-Title "NIVEL 2 - Servicios de Windows innecesarios"

    # Lista de servicios a desactivar (NO toca Bluetooth — Metalcam si lo usa)
    $serviciosADesactivar = @{
        "Fax" = "Servicio de Fax (nadie lo usa)"
        "XboxGipSvc" = "Xbox Game Input"
        "XblAuthManager" = "Xbox Live Auth"
        "XblGameSave" = "Xbox Live Game Save"
        "XboxNetApiSvc" = "Xbox Live Networking"
        "WSearch" = "Windows Search (indexador pesado)"
        "DiagTrack" = "Telemetria de Microsoft"
        "dmwappushservice" = "Mensajes WAP push"
        "MapsBroker" = "Mapas descargados"
        "RetailDemo" = "Modo demo de tienda"
    }

    foreach ($servicio in $serviciosADesactivar.Keys) {
        Write-Step "Desactivando: $($serviciosADesactivar[$servicio])"
        try {
            $svc = Get-Service -Name $servicio -ErrorAction Stop
            if ($svc.Status -eq 'Running') {
                Stop-Service -Name $servicio -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $servicio -StartupType Disabled -ErrorAction Stop
            Write-Done "Servicio '$servicio' desactivado"
        } catch {
            Write-Warn "Servicio '$servicio' no existe en esta PC"
        }
    }

    # Print Spooler condicional: solo apagar si NO hay impresoras configuradas
    Write-Step "Revisando Print Spooler (impresion)"
    try {
        $impresoras = Get-Printer -ErrorAction SilentlyContinue
        if ($impresoras.Count -eq 0) {
            Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
            Set-Service -Name "Spooler" -StartupType Disabled
            Write-Done "Print Spooler desactivado (no hay impresoras)"
        } else {
            Write-Warn "Print Spooler activo (hay $($impresoras.Count) impresoras configuradas)"
        }
    } catch { Write-Warn "No se pudo revisar Print Spooler" }
}

# ========== NIVEL 3: LIMPIEZA PROFUNDA ==========
function Apply-Nivel3 {
    Write-Title "NIVEL 3 - Limpieza profunda"

    # 1. Desinstalar bloatware Microsoft Store
    Write-Step "Removiendo bloatware del Microsoft Store"
    $bloatware = @(
        "*Microsoft.SkypeApp*",
        "*Microsoft.XboxApp*",
        "*Microsoft.XboxGamingOverlay*",
        "*Microsoft.XboxGameOverlay*",
        "*Microsoft.XboxIdentityProvider*",
        "*Microsoft.XboxSpeechToTextOverlay*",
        "*Microsoft.MicrosoftSolitaireCollection*",
        "*Microsoft.MicrosoftMahjong*",
        "*Microsoft.MicrosoftFreeCell*",
        "*king.com.CandyCrush*",
        "*Microsoft.GetHelp*",
        "*Microsoft.Getstarted*",
        "*Microsoft.WindowsFeedbackHub*",
        "*Microsoft.YourPhone*",
        "*Microsoft.ZuneMusic*",
        "*Microsoft.ZuneVideo*",
        "*Microsoft.BingNews*",
        "*Microsoft.BingWeather*"
    )

    foreach ($app in $bloatware) {
        Get-AppxPackage -AllUsers $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
    Write-Done "Bloatware removido"

    # 2. Activar Storage Sense (limpieza automática de temp)
    Write-Step "Activando Storage Sense (limpieza automatica)"
    try {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 -Type DWord
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "2048" -Value 1 -Type DWord
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "32" -Value 30 -Type DWord
        Write-Done "Storage Sense activado (limpia temp cada 30 dias)"
    } catch { Write-Warn "Storage Sense no se pudo configurar" }

    # 3. Limpiar archivos temporales actuales
    Write-Step "Limpiando archivos temporales actuales"
    try {
        Get-ChildItem -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Done "Temp files limpiados"
    } catch { Write-Warn "Algunos temp files no se pudieron borrar (en uso)" }

    # 4. Background apps desactivadas
    Write-Step "Desactivando apps en segundo plano innecesarias"
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -ErrorAction Stop
        Write-Done "Apps en segundo plano: bloqueadas globalmente"
    } catch { Write-Warn "No se pudo bloquear apps en segundo plano" }

    # 5. Desactivar Cortana
    Write-Step "Desactivando Cortana"
    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord
        Write-Done "Cortana desactivada"
    } catch { Write-Warn "Cortana no se pudo desactivar via registry" }
}

# ========== NIVEL 4: CONFIGURACION EDGE OPTIMIZADA ==========
function Apply-Nivel4 {
    Write-Title "NIVEL 4 - Configuracion Edge optimizada"

    # Asegurar que existe el path de policies de Edge
    $edgePolicy = "HKLM:\Software\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgePolicy)) {
        New-Item -Path $edgePolicy -Force | Out-Null
    }

    Write-Step "Activando Sleeping Tabs (hiberna pestanas inactivas)"
    try {
        Set-ItemProperty -Path $edgePolicy -Name "SleepingTabsEnabled" -Value 1 -Type DWord
        Set-ItemProperty -Path $edgePolicy -Name "SleepingTabsTimeout" -Value 300 -Type DWord
        Write-Done "Sleeping Tabs activado (5 minutos)"
    } catch { Write-Warn "No se pudo activar Sleeping Tabs" }

    Write-Step "Activando Efficiency Mode"
    try {
        Set-ItemProperty -Path $edgePolicy -Name "EfficiencyMode" -Value 2 -Type DWord
        Write-Done "Efficiency Mode: Siempre activo"
    } catch { Write-Warn "No se pudo activar Efficiency Mode" }

    Write-Step "Activando Startup Boost"
    try {
        Set-ItemProperty -Path $edgePolicy -Name "StartupBoostEnabled" -Value 1 -Type DWord
        Write-Done "Startup Boost activado"
    } catch { Write-Warn "No se pudo activar Startup Boost" }

    Write-Step "Desactivando preload de paginas (ahorra RAM)"
    try {
        Set-ItemProperty -Path $edgePolicy -Name "NetworkPredictionOptions" -Value 2 -Type DWord
        Write-Done "Preload de paginas desactivado"
    } catch { Write-Warn "No se pudo desactivar preload" }
}

# ========== MENU PRINCIPAL ==========
Clear-Host
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "    OPTIMIZADOR DE PCs - METALCAM" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Politica completa: docs/HERRAMIENTAS.md" -ForegroundColor Gray
Write-Host ""
Write-Host "  Niveles disponibles:" -ForegroundColor White
Write-Host "    1 - Basico (apps inicio, plan energia, visual effects)"
Write-Host "    2 - + Servicios Windows innecesarios"
Write-Host "    3 - + Limpieza profunda (bloatware Store, Storage Sense)"
Write-Host "    4 - + Configuracion Edge optimizada"
Write-Host "    5 - TODO (recomendado para PCs viejas)"
Write-Host ""
$nivel = Read-Host "  Elige nivel (1-5)"

if ($nivel -notmatch '^[1-5]$') {
    Write-Host ""
    Write-Host "  Nivel invalido. Saliendo." -ForegroundColor Red
    exit
}

$nivel = [int]$nivel
Write-Host ""
Write-Host "  Aplicando nivel $nivel..." -ForegroundColor Green
Start-Sleep -Seconds 1

if ($nivel -ge 1 -or $nivel -eq 5) { Apply-Nivel1 }
if ($nivel -ge 2 -and $nivel -le 5) { Apply-Nivel2 }
if ($nivel -ge 3 -and $nivel -le 5) { Apply-Nivel3 }
if ($nivel -ge 4 -and $nivel -le 5) { Apply-Nivel4 }

# ========== RESUMEN FINAL ==========
Write-Title "OPTIMIZACION COMPLETA"
Write-Host ""
Write-Host "  Se recomienda REINICIAR la PC para aplicar todos los cambios." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Si algo no funciona despues:" -ForegroundColor Gray
Write-Host "    1. Revisa que servicios desactivados no afecten tu trabajo" -ForegroundColor Gray
Write-Host "    2. Algunos servicios se pueden reactivar manualmente con:" -ForegroundColor Gray
Write-Host "       Set-Service -Name 'NombreServicio' -StartupType Automatic" -ForegroundColor Gray
Write-Host ""
Read-Host "  Presiona Enter para terminar"
