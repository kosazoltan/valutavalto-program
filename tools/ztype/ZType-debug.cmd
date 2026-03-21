@echo off
chcp 65001 >nul
title ZType hibakeresés
REM Parancsikon munkakönyvtára: %LOCALAPPDATA%\ZType
set "BASE=%~dp0"
cd /d "%BASE%"

if not exist "ztype.py" (
  set "BASE=%LOCALAPPDATA%\ZType"
  cd /d "%BASE%"
)

if not exist "ztype.py" (
  echo Nem találom a ztype.py-t. BASE=%CD%
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo Nincs .venv — futtasd: Install-ZType.cmd vagy install.ps1
  pause
  exit /b 1
)

echo.
echo === ZType konzolos indítás ===
echo Mappa: %CD%
echo Hiba esetén másold ki a szöveget, vagy nézd: %%LOCALAPPDATA%%\ZType\ztype-crash.log
echo.
".venv\Scripts\python.exe" -u ztype.py
echo.
echo Kilépési kód: %ERRORLEVEL%
pause
