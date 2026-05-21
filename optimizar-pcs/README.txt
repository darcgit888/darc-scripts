============================================================
  OPTIMIZADOR DE PCs - METALCAM
  Politica completa: docs/HERRAMIENTAS.md
============================================================

DESCARGAR LOS ARCHIVOS:
  Ir a este link y descargar el ZIP:

    https://github.com/darcgit888/metalcam/tree/master/scripts/optimizar-pcs

  En la pagina de GitHub, click en el boton verde "Code" arriba
  a la derecha, luego "Download ZIP". Extraer el ZIP en cualquier
  carpeta (Escritorio o Descargas estan bien).

QUE ES:
  Script que optimiza una PC Windows para usuarios de Metalcam.
  Libera RAM, desactiva apps innecesarias, configura el navegador
  Edge para uso eficiente con Google Drive y Workspace.

COMO SE USA:
  1. Doble click en "optimizar-metalcam.bat"
  2. Windows pedira permiso de administrador. Da "Si".
  3. Elige el nivel a aplicar:
       1 - Basico (cambios suaves, sin riesgo)
       2 - + Servicios Windows innecesarios
       3 - + Limpieza profunda (quita Skype, Xbox, etc.)
       4 - + Configuracion Edge optimizada
       5 - TODO (recomendado para PCs viejas)
  4. Espera 3-5 minutos.
  5. Reinicia la PC para aplicar todos los cambios.

POR PERFIL DE PC:
  PC nueva (16GB+):              Nivel 1 o 2
  PC media (8GB):                Nivel 1, 2 o 3
  PC vieja (4-6GB):              Nivel 5 (todo)
  PC de personal vigilado:       Nivel 5 (todo)

SI ALGO NO FUNCIONA:
  El script es idempotente — se puede correr varias veces sin
  romper nada.

  Si un servicio que necesitas quedo desactivado:
    1. Abre PowerShell como admin
    2. Ejecuta: Set-Service -Name "NombreServicio" -StartupType Automatic
    3. Ejemplo: Set-Service -Name "Spooler" -StartupType Automatic

EDITAR EL SCRIPT:
  Abre "optimize-metalcam-pc.ps1" en VS Code o Notepad.
  Es texto plano. Cualquier mejora se hace ahi y se vuelve
  a correr en las PCs.

VERSION: 2026-05-21
