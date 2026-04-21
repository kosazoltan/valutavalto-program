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

## KÖTELEZŐ ÉRVÉNYŰ: Production-first fejlesztés
> **A fejlesztés közvetlenül a produktumhoz (Hetzner HA: https://excvaluta.com) illeszkedik.**
> TILOS divergens lokális stack-et használni seed-adattal, amit a produktum nem tartalmaz.

### Szabályok
1. **Frontend + Electron** az `excvaluta.com`-ra mutat (production API URL). Lokális backend CSAK Maven teszt-futtatáshoz (mvn test), nem integrációs fejlesztéshez.
2. **Lokális DB seed** TILOS, ami nincs a produktum DB-n. Ha új seed kell: **Flyway migráció** -> commit -> push -> Hetzner deploy (auto) -> NEKI ott is futni kell.
3. **Adatbázis migráció** esetén: `backend/src/main/resources/db/migration/V{N}__{name}.sql` — a CI/CD deploy pipeline futtatja produktum-on is.
4. **Manuális INSERT `psql`-lel** a lokális DB-be **csak reprodukciós tesztre**, utána **azonnal rollback vagy DROP**. TILOS elfelejtve hagyni.
5. **Ha produktum DB-ben valami hiányzik** (pl. licence, árfolyam), **Flyway migration** a fix útja — ne kézi `psql INSERT`.

### "Local-only" szabályok
- `docker-compose up postgres` csak mvn test + fejlesztői debug-hoz
- `npm run dev` + backend lokálisan CSAK unit-szintű frontend debug-hoz
- **Integrációs teszt** = Hetzner produktum + `VITE_API_URL=https://excvaluta.com/api/v1` env

### Session kezdőlépés (KÖTELEZŐ)
Minden új session elején:
```bash
curl -s https://excvaluta.com/api/v1/auth/bootstrap-status   # >= 200
curl -s https://excvaluta.com/api/v1/public/branches?companyCode=EBC   # non-empty
```
Ha **DOWN**: először helyreállítani (Hetzner + Scaleway HA failover), utána kezdeni a fejlesztést.

## KÖTELEZŐ ÉRVÉNYŰ: Session memory workflow
**Minden session elején** olvasd be:
1. `.remember/remember.md` — rövid handoff az előző session-től
2. `docs/knowledge/memory/*.yaml` — részletes session-enkénti memory (legfrissebbet)
3. `docs/knowledge/memory/*.qmd` — ugyanaz Quarto formátumban
4. `C:\Users\Kósa Zoltán\.claude\projects\D--repo-valutavalto-program\memory\MEMORY.md` — globális memory index (Claude runtime)
5. `docs/LESSONS_LEARNED.md` — korábbi hibák, amiket NE ismételj

**Minden session végén** (új session előtt) mentsd:
1. YAML → `docs/knowledge/memory/YYYY-MM-DD-session-name.yaml`
2. QMD → `docs/knowledge/memory/YYYY-MM-DD-session-name.qmd`
3. Cognee (MCP) → amint elérhető (TODO)
4. Obsidian vault → amint telepítve (TODO)
5. `.remember/remember.md` — rövid handoff (remember skill)
6. CLAUDE.md "Nyitott következő feladatok" → frissítés

Ezek **kötelező érvényűek**, nem választható.

## KÖTELEZŐ ÉRVÉNYŰ: Komplex ökoszisztéma megnyitás
Amikor a user "nyissuk meg a valuta programot / indítsd az ökoszisztémát / teljes rendszer / program elindítása" utasítást ad, **MINDIG az összes komponenst együtt kell indítani**, TILOS csak egy részt:

1. **Lokális PostgreSQL** (localhost:5432) — ellenőrzés + V154 migration alkalmazva
2. **Backend** (Spring Boot, port 8080) — `backend/mvnw spring-boot:run`
3. **Frontend-react admin** (Vite, port 3000) — `frontend-react/npm run dev`
4. **Penztar-client Electron** — `penztar-client/npm run dev:main` (a renderer a frontend-react 3000-esét használja)

**Launcher:** `scripts/start-valuta-ecosystem.ps1` — egyetlen paranccsal az összes komponens elindul + health check + log path-ok listázva.

**Leállítás:** `scripts/stop-valuta-ecosystem.ps1` (vagy `Get-Process java,node,electron | Stop-Process -Force`)

**TILOS külön megnyitni!** A helyes állapot ellenőrzése csak komplex rendszer-szinten érvényes — pl. a frontend authentication hitelesítése a backend-hez, az Electron sync a backend-hez és a frontend-hez stb. Külön indítás csak debug célra megengedett, explicit user-megerősítéssel.

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
- **Verzió:** **v2.1.7** (2026-04-21 este). Minden modul egységesen 2.1.7-n. Főbb vízcsömök ma: v2.1.5 (reggel) → v2.1.6 (PR #102, 20:17) → v2.1.7 (PR #105, 21:32).
- **Main HEAD:** `51a9c591` (chore: bump v2.1.6 → v2.1.7 + Production URL SSOT, PR #105).
- **Mai 10 merge:** PR #97 (production-first + branch_code), #98 (claude-review 3 P0 cherry-pick), #99 (legacy dev launcher törölve), #100 (launcher npm.cmd fix), #101 (SetupWizard scroll), #102 (bump v2.1.6), #103 (version single source), #104 (kumulált AI review P1+P2), #22 (dependabot actions/checkout 4→6), #105 (bump v2.1.7 + Production URL SSOT).
- **Telepítő fájlok v2.1.7** (gitignore-osak, `installer/build/`-ban + másolva `%USERPROFILE%\Downloads\`-ba):
  - `Penztar-Setup-2.1.7-20260421.exe` — **273.53 MB**, SHA-256 `648FDF20F728E57D258CDD131B5EA11FF270E383FDEDE1B520FE2471C9F92C65`
  - `Penztar-Eltavolito-2.1.7-20260421.exe` — **60 KB**, SHA-256 `FFFE8FDD250D0A577607EE544CF5BE6873C6E86A945DBCB8EA21ADD7AC587B86`
  - Régi v2.1.6 installerek törölve a Downloads-ból.
- **Újra-buildelés:** `powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 [-SkipDownloads]`. A `$Version` PARAMETER most auto-load a monorepo root `package.json`-ból (PR #103 + #104 `build-common.ps1` helperrel).
- **NSIS encoding szabály:** `.nsi` csak Windows-1252 ASCII. Ékezetek → sima ASCII. Em-dash → `-`.
- **Memory fájlok a mai wave-hez:** `docs/knowledge/memory/2026-04-21-session-ai-review-v2.1.7.yaml` + `.qmd`. `.remember/remember.md` frissítve.
- **Asztali shortcutok** (`C:\Users\Kósa Zoltán\OneDrive\Desktop\`): `Valuta Pénztár — Fejlesztői mód (INDÍTÁS).lnk`, `Valuta Pénztár — Fejlesztői mód (LEÁLLÍTÁS).lnk`, `Valuta Pénztár — Éles kliens (telepített).lnk`.
- **AI review automation:** `.github/workflows/ai-review-auto-fix.yml` minden PR merge után triggerel. A kötelező gyűjtő-script minta: `for pr in 97 98 100 101 102 103 104; do gh api "/repos/kosazoltan/valutavalto-program/pulls/$pr/reviews"; done`. PR #104 ezzel 7 hibát javított.
- **Production URL SSOT (v2.1.7 új):** `config/production-urls.json` + `backend/.../config/ProductionUrls.java` Java konstans osztály. PROBLEMADETAILBUILDER.TYPE_BASE mostantól onnan olvas. **Deferred:** minden @Value default, PS1 launcher hardcoded és Electron `main.ts` fallback teljes refactor a config-ból.
- **Nyitott következő feladatok:**
- **Nyitott következő feladatok (2026-04-22+):**
  - **P0 (éles pénztár frissítés):** user v2.1.7 reinstall az éles gépen — 1) `Penztar-Eltavolito-2.1.7-20260421.exe` admin joggal, 2) `Penztar-Setup-2.1.7-20260421.exe` admin joggal, 3) SetupWizard 5 lépés (Iroda → Program típus → Szerver (**Kapcsolat tesztelése** gomb kötelező!) → Admin jelszó → Telepítés), 4) belépés `EBC / ADMIN / Admin1234!`, 5) új VÉTEL teszt → `VEBC000001` NGM-bizonylat.
  - **P0 (V155 migration Hetzner production-on):** a Spring Boot következő indulásakor a Flyway automatikusan lefuttatja. Ha duplikált `daily_session` vagy `transaction.receipt_number` van, a `DO $$ RAISE EXCEPTION` pre-check megállítja — admin döntheti el a takarítást. Fájl: `backend/src/main/resources/db/migration/V155__add_version_and_unique_constraints.sql`.
  - **P1:** happy path teszt dev módban (Fejlesztői mód INDÍTÁS shortcut) — a SetupWizard 4. lépésnél **Kapcsolat tesztelése gombot** kell nyomni (connectionTest.state=ok kötelező a Továbbhoz).
  - **P1:** Production URL SSOT teljes refaktor — Java konstans osztály (`ProductionUrls.java`) + `config/production-urls.json` meglelve, **deferred**: minden @Value default, PS1 launcher hardcoded és Electron `main.ts` fallback a config-ból lazy-load-olni.
  - **P2:** CB-016 (NavClosingService hardcoded VAT_RATE=0.27 → tax_code mapping).
  - **P2:** Cognee MCP integráció (amint elérhető) — auto-save session memóriába.
  - **P2:** Obsidian vault sync (amint telepítve) — auto-save session memóriába.
  - **P2:** Spring Boot 3.5.14 upgrade (2026-04-23 milestone; amint release-eli Tomcat 10.1.54+ bundle-lel, törlendő az explicit `<tomcat.version>` override a `backend/pom.xml`-ből).
  - **P2:** Installer acceptance test friss Windows VM-en az `installer/tests/installer-validation-suite.ps1` szkripttel.
