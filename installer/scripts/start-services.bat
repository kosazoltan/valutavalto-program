@echo off
chcp 65001 >nul 2>&1
REM Valutavalto Penztar - Szolgaltatasok inditasa
echo Szolgaltatasok inditasa...

echo   PostgreSQL inditas...
net start BestChange-PostgreSQL
if errorlevel 1 (
    echo   FIGYELMEZETES: PostgreSQL inditas hiba. Lehet, hogy mar fut.
)
timeout /t 5 /nobreak >nul

echo   Backend inditas...
net start BestChange-Backend
if errorlevel 1 (
    echo   FIGYELMEZETES: Backend inditas hiba. Lehet, hogy mar fut.
)

echo Szolgaltatasok inditasa kesz.
echo Penztar: http://localhost:8080/actuator/health
pause
