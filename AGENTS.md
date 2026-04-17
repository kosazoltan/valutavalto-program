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

## Mandatory security gate for all agents
- **Always-on rule:** Every coding agent must apply `.cursor/rules/mandatory-security-gate.mdc`.
- **Mandatory skill:** Every coding task must use `.cursor/skills/security-deploy-gate/SKILL.md` automatically (no trigger words required).
- **Baseline version:** Mandatory baseline is `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md` (Java + Electron + React + Python + Node.js).
- **Pre-deploy gate:** Before any deploy recommendation, run `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1`.
- **Hard stop:** `FAILED` or `BLOCKED` gate status always blocks deployment.
- **Evidence-first:** Agents must provide command evidence from `security-reports/latest/` and must not claim unverified success.

## Database
- PostgreSQL (server), SQLite (offline client)
- Flyway migrations: `backend/src/main/resources/db/migration/`
- Connection config: `application.properties` → `spring.datasource.*`

## Current release state (resume anchor for next agent)
- **Version:** **v2.1.0** (git tag pushed, 2026-04-17). All modules (backend/pom.xml, frontend-react, penztar-client, installer/*) unified on 2.1.0. Before this release they were split across 1.0.0 / 1.0.0-SNAPSHOT / 1.9.2. If you bump, update all 12 version files listed in `docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.yaml` under `resume_workflow_for_future_agent.version_bump_for_future_release.files_to_update`.
- **HEAD:** `ba425304` on `main`, pushed. Recent commits: `87b9a56a` (First-Run Setup Wizard), `b73a2c56` (standalone Penztar-Eltavolito build + Hungarian README + NSIS encoding fix), `ba425304` (version unification + CHANGELOG [2.1.0]).
- **Installer artifacts (gitignored, in `installer/build/`):**
  - `Penztar-Setup-2.1.0-20260417.exe` — 431.20 MB, SHA-256 `33F48495F17B113BBCBC9FB7F8FF9AC051D3532248BF0984EE5AEB89304CEBDC`
  - `Penztar-Eltavolito-2.1.0-20260417.exe` — 58.5 KB, SHA-256 `D6404015F2C24A457977D0C48A6BAE97F0972F06BE93766B45FB8500073AC8CA`
  - Both copied to `%USERPROFILE%\Downloads\` for the operator.
- **Rebuild:** `powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 [-SkipDownloads]` (~10-30 min, or ~8 min with `-SkipDownloads` if `installer/build/stage/` cache present). Standalone uninstaller: `powershell -ExecutionPolicy Bypass -File installer\build-cleanup.ps1` (~1s, ~60 KB).
- **NSIS source encoding rule:** `.nsi` files must be Windows-1252 ASCII-only (NSIS 3.x Windows compiler uses ACP). Hungarian accents (`á`/`é`/`í`/`ó`/`ö`/`ő`/`ú`/`ü`/`ű`) must be plain ASCII; em-dashes (`—`) must be plain `-`. The `©` symbol (U+00A9 = byte `0xA9`) is valid in Windows-1252 and stays.
- **Memory files for this wave:** `docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.yaml` + `.qmd`. Previous same-day wave (AML parity + pipeline): `docs/knowledge/memory/2026-04-17-pipeline-run-session.yaml` + `.qmd`.
- **Open next-wave items:** CB-016 (NavClosingService hardcoded VAT_RATE=0.27 → tax_code mapping), companyId formal repository audit (multi-tenant boundary check), Spring Boot 3.5.14 watch (milestone 2026-04-23; once Tomcat 10.1.54+ bundled, remove explicit `<tomcat.version>` override in `backend/pom.xml`), installer acceptance test on clean Windows VM via `installer/tests/installer-validation-suite.ps1`.
