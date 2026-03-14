# Valutaváltó ERP — Codex Agent Context

## Project overview
Hungarian currency exchange (valutaváltó / pénzváltó) ERP system. Multi-tenant (multiple branches), offline-capable.

## Tech stack
- **Backend:** Java 21, Spring Boot 3.2, Spring Security, Spring Data JPA, PostgreSQL, Flyway migrations
- **Frontend (admin):** React 19, TypeScript, Tailwind CSS 3, Zustand — `frontend-react/`
- **Desktop client (cashier):** Electron 33, React, SQLite offline sync — `penztar-client/`
- **Build:** Maven (backend), npm + Vite (frontend + desktop)

## Directory structure
```
backend/                  # Spring Boot backend
  src/main/java/hu/puzzleir/valuta/
    config/               # Security, WebSocket, CORS, rate limiting
    controller/           # REST controllers (~113)
    dto/                  # Request/response DTOs
    entity/               # JPA entities (~165)
    mapper/               # MapStruct mappers
    repository/           # Spring Data JPA repos
    security/             # JWT, SecurityUtils
    service/              # Business logic (~122)
    util/                 # Utilities
  src/main/resources/
    db/migration/         # Flyway migrations (V1–V71)
    application.properties
frontend-react/           # Admin web UI (React 19 + TS)
  src/pages/              # ~51 pages
  src/services/api.ts     # Axios API calls
  src/utils/              # Helpers (e.g. rounding.ts — HUF 5 Ft rounding)
penztar-client/           # Cashier Electron client
  src/pages/              # Buy, Sell, Conversion, etc.
  src/stores/             # Zustand stores
  electron/sync-engine.ts # Offline sync
database/                 # Extra migrations, seeds
scripts/                  # Utility scripts
```

## Setup commands
```bash
# Backend (requires Java 21)
cd backend && ./mvnw spring-boot:run

# Frontend admin
cd frontend-react && npm install && npm run dev

# Cashier desktop client
cd penztar-client && npm install && npm run dev
```

## Testing commands
```bash
# Backend tests (JUnit 5) — run this to verify backend changes
cd backend && ./mvnw test

# Frontend tests (Vitest)
cd frontend-react && npm test

# Cashier client tests
cd penztar-client && npm test
```

## Critical rules
- **Language:** Code is Java/TypeScript, but domain terms are Hungarian: vétel (buy), eladás (sell), sztornó (storno), napzárás (daily closing), címletezés (denomination), árfolyam (exchange rate)
- **Multi-tenant:** Every query MUST filter by companyId — NEVER skip company filtering!
- **HUF rounding:** Hungarian 5 HUF rounding is mandatory for all HUF amounts (use `roundHuf` utility)
- **AML:** Anti-money-laundering check is mandatory before transactions
- **Exchange rate freshness:** 24-hour TTL — never allow transactions with stale rates
- **Security:** `@PreAuthorize` annotation required on every controller, JWT auth, CORS must NOT be wildcard (`*`)

## Database
- PostgreSQL (server), SQLite (offline client)
- Flyway migrations: `backend/src/main/resources/db/migration/`
- Connection config: `application.properties` → `spring.datasource.*`
