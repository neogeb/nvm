@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem === AJUSTA RUTAS SI CAMBIAN EN TU EQUIPO ===
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

rem ===== Construir PATH nuevo quitando otras rutas de Node =====
set "NEWPATH="
for %%I in ("%PATH:;=","%") do (
  set "P=%%~I"
  if /I not "!P!"=="%NODE12%" if /I not "!P!"=="%NODE14%" if /I not "!P!"=="%NODE22%" (
    if defined NEWPATH (
      set "NEWPATH=!NEWPATH!;!P!"
    ) else (
      set "NEWPATH=!P!"
    )
  )
)

rem Prependemos la seleccionada
if defined NEWPATH (
  set "NEWPATH=%TARGET%;!NEWPATH!"
) else (
  set "NEWPATH=%TARGET%"
)

set "PATH=!NEWPATH!"

echo.
echo [OK] Node activado desde: "%TARGET%"
for /f "delims=" %%v in ('node -v 2^>nul') do echo   Node %%v
for /f "delims=" %%v in ('npm -v 2^>nul') do echo   npm  %%v
echo.

if /I "%~2"=="--persist" (
  setx PATH "%PATH%" >nul
  echo [OK] PATH de usuario actualizado de forma permanente. Abre una nueva consola para que aplique.
) else (
  echo [INFO] Cambio valido solo en ESTA ventana. Agrega --persist para guardarlo.
)

goto :end

:usage
echo Uso:
echo   usarnode 12 ^| 14 ^| 22  [--persist]
echo Ejemplos:
echo   usarnode 12
echo   usarnode 14 --persist
echo   usarnode 22
goto :end

:end
endlocal