@echo off
chcp 65001 >nul 2>&1
REM Valutavalto Penztar - Szolgaltatasok leallitasa
echo Szolgaltatasok leallitasa...

echo   Backend leallitas...
net stop BestChange-Backend
if errorlevel 1 (
    echo   FIGYELMEZETES: Backend leallitas hiba. Lehet, hogy nem fut.
)
timeout /t 3 /nobreak >nul

echo   PostgreSQL leallitas...
net stop BestChange-PostgreSQL
if errorlevel 1 (
    echo   FIGYELMEZETES: PostgreSQL leallitas hiba. Lehet, hogy nem fut.
)

echo Szolgaltatasok lealltak.
pause
