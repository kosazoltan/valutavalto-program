@echo off
title ZType telepítő
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
  echo.
  echo Telepítés hiba -- lasd fent.
  pause
  exit /b 1
)
echo.
pause
