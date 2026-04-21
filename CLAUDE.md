# Valutaváltó ERP — Claude Code kontextus

## Projekt áttekintés
Magyar valutaváltó / pénzváltó ERP rendszer. Multi-tenant (több iroda), offline-képes.

## Tech stack
- **Backend:** Java 21, Spring Boot 3.2, Spring Security, Spring Data JPA, PostgreSQL, Flyway migrációk
- **Frontend (admin):** React 19, TypeScript, Tailwind CSS 3, Zustand — `frontend-react/`
- **Desktop kliens (pénztáros):** Electron 33, React, SQLite offline sync — `penztar-client/`
- **Build:** Maven (backend), npm + Vite (frontend + desktop)

## Könyvtárstruktúra
```
backend/                  # Spring Boot backend
  src/main/java/hu/puzzleir/valuta/
    config/               # Security, WebSocket, CORS, rate limiting
    controller/           # REST kontrollerek (~113 db)
    dto/                  # Request/response DTO-k
    entity/               # JPA entity-k (~165 db)
    mapper/               # MapStruct mapperek
    repository/           # Spring Data JPA repók
    security/             # JWT, SecurityUtils
    service/              # Üzleti logika (~122 db)
    util/                 # Segédosztályok
  src/main/resources/
    db/migration/         # Flyway migrációk (V1–V71)
    application.properties
frontend-react/           # Admin webes felület (React 19 + TS)
  src/pages/              # ~51 oldal
  src/services/api.ts     # Axios API hívások
  src/utils/              # Segédek (pl. rounding.ts — 5 Ft kerekítés)
penztar-client/           # Pénztáros Electron kliens
  src/pages/              # Buy, Sell, Conversion, stb.
  src/stores/             # Zustand store-ok
  electron/sync-engine.ts # Offline sync
database/                 # Extra migrációk, seed-ek
scripts/                  # Utility szkriptek
```

## Build és futtatás
```bash
# Backend
cd backend && ./mvnw spring-boot:run

# Frontend (admin)
cd frontend-react && npm install && npm run dev

# Pénztáros kliens
cd penztar-client && npm install && npm run dev
```

## Tesztek
```bash
# Backend tesztek (JUnit 5)
cd backend && ./mvnw test

# Frontend tesztek (Vitest)
cd frontend-react && npm test

# Pénztáros kliens tesztek
cd penztar-client && npm test
```

## Fontos konvenciók
- **Nyelv:** A kódbázis Java/TypeScript, de a domain (üzleti fogalmak) magyarul van: vétel (buy), eladás (sell), sztornó (storno), napzárás (daily closing), címletezés (denomination), árfolyam (exchange rate)
- **Multi-tenant:** Minden lekérdezés companyId-ra szűr — SOHA ne hagyd ki a company szűrést!
- **HUF kerekítés:** Magyar 5 Ft-os kerekítés kötelező minden HUF összegnél (`roundHuf` util)
- **AML:** Pénzmosás elleni ellenőrzés kötelező tranzakciók előtt
- **Árfolyam frissesség:** 24 órás TTL — lejárt rátával nem szabad tranzakciót engedni
- **Security:** `@PreAuthorize` annotáció minden controlleren, JWT auth, CORS nem lehet wildcard (`*`)

## Kotelezo regi hibak azonnali javitasa
- Ha egy audit vagy kódreview soran barmilyen korabbi hibat megtalalsz (scope-on kivul, mas modulban), azonnal javitani kell, nem dokumentalni kesobbre.
- Ez kiterjeszti a jelenlegi PR scope szabalyt — a user szerint minden ismert hiba surgos.
- Kivetel: ha a javitas tobb napos refactort igenyelne, akkor GitHub Issue-t nyitni + kommentalni a kodban.

## AUTOMATIZALT AI code review workflow (Sourcery + Codex)
**2026-04-21 ota automatikus**: a `.github/workflows/ai-review-auto-fix.yml` a Claude Code Action-t triggereli, amikor Sourcery vagy Codex review erkezik. Ez automatikusan javit + push-ol a feature branch-re. A manualis workflow az `agent` fallback.

Lasd: `docs/AI_REVIEW_AUTOMATION.md`

## Kötelező AI code review workflow (Sourcery + Codex) — manualis fallback
- **Minden PR MERGE UTAN automatikusan:**
  1. Lekerni a Sourcery-AI es ChatGPT-Codex review-kat: `gh api repos/OWNER/REPO/pulls/PR_NUM/reviews` es `/pulls/PR_NUM/comments` (filter: user.login matches `sourcery-ai|chatgpt-codex-connector`).
  2. **Automatikusan javitani a jelzett hibakat.** Priorizalas: P1 (bug_risk, kritikus) > P2 (suggestions) > style.
  3. Follow-up PR-t nyitni: `fix(ai-review): ...` prefix-szel.
  4. Helyi teszt-futtatas kotelezo a merge elott (backend mvn test + frontend vitest + tsc).
- **Helyes-pozitiv kizarasa:** Ha egy AI flag hamis riasztas (pl. balanced brackets), dokumentalni a PR-ben miert nem javitasra vonatkozo. Ne ignoralni, csak megjelolni.
- **Kovetkezo session handoff:** minden AI javitas a session handoff memory YAML-ban dokumentalando.

## Kötelező security gate minden agentnek
- **Always-on szabály:** Kötelező alkalmazni `.cursor/rules/mandatory-security-gate.mdc`.
- **Kötelező skill:** Minden programozási feladatnál kötelező a `.cursor/skills/security-deploy-gate/SKILL.md`.
- **Kötelező baseline:** `.cursor/skills/security-deploy-gate/SECURITY_BASELINE_V3.md` (multi-stack: Java, Electron, React, Python, Node.js).
- **Deploy előtti gate:** Kötelező futtatás: `powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1`.
- **Blokkolás:** `FAILED` vagy `BLOCKED` gate státusz esetén deploy tiltott.
- **Bizonyíték-kötelezettség:** Eredményeket `security-reports/latest/` útvonalról kell jelenteni.

## Adatbázis
- PostgreSQL (szerver), SQLite (offline kliens)
- Flyway migrációk: `backend/src/main/resources/db/migration/`
- Kapcsolat: `application.properties` → `spring.datasource.*`

## Aktuális release-állapot (a következő agent számára folytatási horgony)
- **Verzió:** **v2.1.0** (git tag pusholva, 2026-04-17). Minden modul (backend/pom.xml, frontend-react, penztar-client, installer/*) egységesen 2.1.0-n. Előtte szétesett: 1.0.0 / 1.0.0-SNAPSHOT / 1.9.2. Ha bump kell, lásd a `docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.yaml` alatt a `resume_workflow_for_future_agent.version_bump_for_future_release.files_to_update` listát (12 fájl).
- **HEAD:** `ba425304` a `main`-en, pusholva. Mai session commitjai: `87b9a56a` (First-Run Setup Wizard), `b73a2c56` (standalone Penztar-Eltavolito build + magyar README + NSIS encoding fix), `ba425304` (verzió-egyesítés + CHANGELOG [2.1.0]).
- **Telepítő fájlok (gitignore-osak, `installer/build/`-ban):**
  - `Penztar-Setup-2.1.0-20260417.exe` — 431.20 MB, SHA-256 `33F48495F17B113BBCBC9FB7F8FF9AC051D3532248BF0984EE5AEB89304CEBDC`
  - `Penztar-Eltavolito-2.1.0-20260417.exe` — 58.5 KB, SHA-256 `D6404015F2C24A457977D0C48A6BAE97F0972F06BE93766B45FB8500073AC8CA`
  - Mindkettő bemásolva a `%USERPROFILE%\Downloads\`-ba az operátornak.
- **Újra-buildelés:** `powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 [-SkipDownloads]` (~10-30 perc, vagy ~8 perc `-SkipDownloads`-al, ha az `installer/build/stage/` cache megvan). Standalone eltávolító: `powershell -ExecutionPolicy Bypass -File installer\build-cleanup.ps1` (~1 s, ~60 KB).
- **NSIS encoding szabály:** `.nsi` forrásfájlok csak Windows-1252 ASCII-t tartalmazhatnak (NSIS 3.x Windows fordító ACP-t használ). Magyar ékezetek (`á`/`é`/`í`/`ó`/`ö`/`ő`/`ú`/`ü`/`ű`) → sima ASCII. Em-dash (`—`) → `-`. A `©` (U+00A9 = `0xA9` byte) megmaradhat, valid Windows-1252.
- **Memory fájlok a mai wave-hez:** `docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.yaml` + `.qmd`. Ugyanaznap korábbi wave (AML parity + pipeline): `docs/knowledge/memory/2026-04-17-pipeline-run-session.yaml` + `.qmd`.
- **Nyitott következő feladatok:** CB-016 (NavClosingService hardcoded VAT_RATE=0.27 → tax_code mapping), companyId formal repository audit (multi-tenant boundary check), Spring Boot 3.5.14 monitoring (2026-04-23 milestone; amint release-eli Tomcat 10.1.54+ bundle-lel, törlendő az explicit `<tomcat.version>` override a `backend/pom.xml`-ből), installer acceptance test friss Windows VM-en az `installer/tests/installer-validation-suite.ps1` szkripttel.
