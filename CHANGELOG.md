# Changelog

## [2.0.0] - 2026-03-06

### Added
- Teljes Electron pénztár kliens (47 képernyő)
- Értéktár mód (ugyanaz az app, config alapú)
- AML pénzmosás elleni modul (300K/4.5M/2M küszöb)
- MNB napi/havi jelentés (XML export)
- NAV adatszolgáltatás (2M+ Ft)
- Trade modul (irodák közötti devizakereskedés)
- Deviza kalkulátor (cross-rate, kerekítés)
- Záró wizard (5 lépéses)
- Dashboard (összesítő)
- Pénztárgép integráció (NAV online)
- LED kijelző kezelés
- Dokumentum szkenner
- FTP szinkronizáció bridge
- i18n többnyelvűség (hu/en/de)
- Config export/import
- Cég/Fiók adminisztráció
- Backup/Restore
- Licenc kezelés
- Nyomtatási sablonok
- Audit trail (teljes)
- Értesítés rendszer + NotificationBell
- Scheduler (rate sync, backup, closing reminder, health check)
- GlobalExceptionHandler (6 hibakód)
- ErrorBoundary + Toast rendszer
- Swagger UI v2.0
- 245 teszt (177 backend + 68 frontend)

### Migration
- 41 Flyway migráció (V1-V41)
- 146 entity
- 106 controller
- 400+ REST endpoint

### Tech Stack
- Java 21 + Spring Boot 3.2
- React 19 + TypeScript + Vite
- Electron (offline pénztár)
- PostgreSQL + SQLite (sql.js WASM)
- JWT auth
