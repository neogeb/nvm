@echo off
rem === AJUSTA ESTAS RUTAS A TU EQUIPO ===
set "NODE12=C:\node\v12.18.2"
set "NODE14=C:\node\v14.21.3"
set "NODE22=C:\Program Files\nodejs"

if "%~1"=="" goto :usage

set "TARGET="
if /I "%~1"=="12" set "TARGET=%NODE12%"
if /I "%~1"=="14" set "TARGET=%NODE14%"
if /I "%~1"=="22" set "TARGET=%NODE22%"

if not defined TARGET (
  echo [ERROR] Version no soportada: %~1
  goto :end
)

if not exist "%TARGET%\node.exe" (
  echo [ERROR] No se encontro node.exe en "%TARGET%"
  goto :end
)

call :ensure_npm "%TARGET%"

rem ---- Sesion actual: prepend al PATH ----
set "PATH=%TARGET%;%PATH%"

echo [OK] Node activado desde: "%TARGET%"
for /f "delims=" %%v in ('node -v 2^>nul') do echo   Node %%v
for /f "delims=" %%v in ('npm -v  2^>nul') do echo   npm  %%v
echo.

if /I "%~2"=="--persist" (
  rem OJO: setx puede truncar si el PATH de usuario es muy largo.
  setx PATH "%PATH%" >nul
  echo [OK] PATH de usuario actualizado. Abre una nueva consola para que aplique.
) else (
  echo [INFO] Cambio valido solo en ESTA ventana. Usa --persist para guardar.
)

goto :end

:ensure_npm
rem Crea wrappers npm/npx si no existen
set "BASE=%~1"
if not exist "%BASE%\npm.cmd" (
  >"%BASE%\npm.cmd" echo @echo off
  >>"%BASE%\npm.cmd" echo "%~1\node.exe" "%~1\node_modules\npm\bin\npm-cli.js" %%*
)
if not exist "%BASE%\npx.cmd" (
  >"%BASE%\npx.cmd" echo @echo off
  >>"%BASE%\npx.cmd" echo "%~1\node.exe" "%~1\node_modules\npm\bin\npx-cli.js" %%*
)
exit /b 0

:usage
echo Uso:
echo   usarnode 12 ^| 14 ^| 22  [--persist]
echo Ejemplos:
echo   usarnode 12
echo   usarnode 14 --persist
echo   usarnode 22
echo.
:end