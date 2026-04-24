# Changelog

A `valutavalto-program` monorepo verzió-történet.

Formátum: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
verziószám: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.3] — 2026-04-24

### Kritikus bug-fix (frontend / desktop klienst érinti)
- **PR #163** — `frontend-react/src/services/api/client.ts`: Idempotency-Key header
  AxiosHeaders 1.x kompatibilis `set()` API használat (direkt assignment helyett).
  A pénztáros Electron kliens ugyanezt a frontend build-et használja, tehát
  ez a fix desktop-on is blokkoló volt a VETEL/ELADÁS/STORNO flow-ra.
  Live verify: **V017100012 10 EUR VETEL** sikeresen szerveren 2026-04-23 20:05.

### Új feature-k
- **PR #164** — `backend/DailySessionService`: új `cash_balance` auto-init
  `updateCashBalancesForOpening()`-ben (Issue #110 lezárás). Új branch-ek
  napnyitáskor automatikusan kapnak üres cash_balance rekordokat minden
  aktív valutára, így a tranzakció-sync nem esik el 404-gyel.

- **PR #175** — `.github/workflows/playwright-live.yml`: új GitHub Actions
  workflow manuális + nightly 03:30 UTC Playwright e2e tesztekhez
  `excvaluta.com` ellen. 10 teszt (T01–T10), T09 authenticated flow
  GitHub Secrets credentials-szel.

### Refaktor
- **PR #172** — `docs/LEGACY_COVERAGE_MATRIX.md`: 2026-04-24 legacy audit,
  129/129 = 100% modern lefedés bizonyítva (tiltcopy, recguard, vevo_mend
  mind `SanctionScreeningService`, `CameraCleanupService`, `CustomerController`
  révén ellefedve).

- **PR #173** — Production URL SSOT teljes propagáció (3 réteg):
  - Backend: `WebSocketConfig` + `ProductionCorsFilter` `List.of(...)`
    helyett `ProductionUrls.BASE_URL` + `WWW_BASE_URL`.
  - **ÚJ** `scripts/_production-urls.ps1` shared PowerShell helper
    (`$PRODUCTION_URLS` hash + getter funkciók a `config/production-urls.json`-ból).
  - `scripts/start-valuta-ecosystem.ps1`: dot-source helper,
    minden hardcoded URL `$PRODUCTION_URLS.*`-ra cserélve.
  - Electron `penztar-client/electron/main.ts`: új `loadProductionUrls()`
    — packaged path (`process.resourcesPath`) vs dev path, graceful fallback.
  - `electron-builder.json`: `extraResources += config/production-urls.json`.

### Infrastruktúra (nem végfelhasználó-látható)
- **PR #165** — session-memory-save Windows PowerShell wrapper
  (`scripts/session-memory-auto-save.ps1`) + session handoff YAML+QMD
  (`docs/knowledge/memory/2026-04-24-*`).
- **PR #170** — `scripts/setup-knowledge-mcp.ps1` diagnosztikai script
  (Cognee MCP + Obsidian Local REST API) + `docs/knowledge/COGNEE_OBSIDIAN_SETUP.md`.
- **PR #171** — Obsidian host IPv4 (`127.0.0.1`) default (plugin IPv6 IPv6 fail-hez).

### AI review follow-up fixek
- **PR #166** — Sourcery 3 finding javítva PR #165-re (1 bug_risk + 2 P2).
- **PR #167** — Sourcery 2 finding javítva PR #166-ra (splat cleanup + default logic).
- **PR #168** — Sourcery 2 finding javítva PR #167-re ([switch] + DRY splat).
- **PR #169** — Sourcery case-insensitive regex javítva PR #168-ra.
- **PR #174** — Sourcery 3 finding javítva PR #173-ra (scope + summary + fallback log).
- **PR #176** — Sourcery 4 finding javítva PR #175-re (explicit waits + stabil
  selectors + health check exit 1 + komment egyesítés).

### Quality gate
- Backend tesztek: **978/978 zöld**
- Penztar-client tesztek: **97/97 zöld**
- Frontend-react tesztek: zöld
- Playwright live (T10 smoke): zöld
- Open PR: 0 / aktív remote branch: 1 (main) — branch policy v2 teljesítve
- Hetzner deploy: minden merge után SUCCESS

### Upgrade path
- **Backend**: automatikus Hetzner deploy minden main merge után (nincs manuális lépés).
- **Frontend (admin)**: automatikus Hetzner deploy (deploy-hetzner.yml → deploy-frontend job).
- **Pénztáros Electron kliens**: **v2.2.3 installer telepítése javasolt** a PR #163 fix miatt.
  A régi v2.2.2 desktop app-ban a VETEL tranzakció 400-as hibával elesik a
  Hetzner backend-re, amíg a user nem frissíti az installerre.

---

## [2.2.2] — 2026-04-23

### Kezdeti release (installer v2.2.2-20260423)
- `Penztar-Setup-2.2.2-20260423.exe` — 273.46 MB
- `Penztar-Eltavolito-2.2.2-20260423.exe` — 60 KB
- Backend v2.2.2 JAR deployment Hetzner VPS-re
- PostgreSQL V159 migration (vault HUF stock init)
- Frontend manuális sync `excvaluta.com`-ra (3 hónapos deploy gap után)

## [2.2.0 – 2.2.1]

Részletes release-history: lásd `git log --oneline v2.1.7..v2.2.2`
és a megfelelő GitHub Release notes-okat.

## [2.1.7] — 2026-04-21

Production URL SSOT bevezetése (`config/production-urls.json` + `ProductionUrls.java`).
Részletek: lásd `git log v2.1.6..v2.1.7` és CLAUDE.md "Aktuális release-állapot".

Korábbi verziók: lásd GitHub Releases oldalt.