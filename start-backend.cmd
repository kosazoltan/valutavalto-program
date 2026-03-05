@echo off
echo ============================================
echo   Valutavalto Backend - Spring Boot Server
echo ============================================

set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot
set PATH=%JAVA_HOME%\bin;%PATH%

cd /d "%~dp0backend"

echo Java verzio:
java -version

echo.
echo Inditas... (port 8080)
echo API: http://localhost:8080/api/v1
echo Swagger: http://localhost:8080/swagger-ui.html
echo.

call mvnw.cmd spring-boot:run -DskipTests
