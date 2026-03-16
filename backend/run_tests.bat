@echo off
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot
call mvnw.cmd test -Dtest=StockSnapshotServiceTest,StockSnapshotExcelServiceTest 2>&1
