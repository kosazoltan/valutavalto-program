# 2026-05-05 — Error-reporting pipeline E2E + valuta-error-monitor routine + v2.5.18 installer

## Mit zárult le

### Backend reporter PR sorozat (mind merge-elve)
- **#407** `feat(diagnostics): auto kliens-oldali hibajelentes (Sentry-style HTTP endpoint + PostgreSQL)` — V182 + DiagnosticsController + ErrorReportDto + ClientErrorLog entity
- **#410** `feat(diagnostics): kritikus kliens hiba -> AUTO GitHub Issue auto-create` — GitHubIssueAutoCreator @Async + 24h dedup signature
- **#411** `fix(security): /api/v1/diagnostics/** endpoint permitAll a SecurityConfig-ban` — requestMatcher
- **#412** `fix(diagnostics): /api/v1/diagnostics/ idempotency-skip a IdempotencyFilter-be` — EXCLUDED_PREFIXES
- **#413** `fix(diagnostics): JsonNode -> Map<String,Object> Jackson 3 kompatibilitas` — DTO field type
- **#414** `fix(diagnostics): client_ip INET -> VARCHAR(45) Hibernate kompat (V183 migracio)` — V183

### E2E verifikáció
- 07:04 UTC smoke POST `/api/v1/diagnostics/error-report` → 200 OK + `{"ok":true,"id":1}`
- Hetzner SQL: `client_error_log` row id=1 confirmed
- Backend log: "GitHubIssueAutoCreator: issue created for client-error #1, response=201"
- GitHub Issue #415 created: title `[auto] FINAL smoke test - uncaughtException simulated — electron-main`, labels `[client-error, auto-reported]`
- Issue #415 closed manually with comment

### Tokenek tárolva (gitignored)
- `D:\repo\valutavalto-program\.env` (repo root, gitignore-olt) — ANTHROPIC, OPENAI, GEMINI, VERCEL, RENDER, ELEVENLABS, GITHUB PAT, TAILSCALE, NEON, CF, SOURCERY, ELECTRON GitHub Actions, GITHUB_ISSUE_AUTO_CREATE_TOKEN
- Hetzner backend `/etc/valuta/valuta.env` — `GITHUB_ISSUE_AUTO_CREATE_TOKEN`, `GOOGLE_DESKTOP_CLIENT_ID`
- GitHub Actions secrets — `GITHUB_ISSUE_AUTO_CREATE_TOKEN` repo-scope

### Schedule routine létrehozva
- `mcp__scheduled-tasks__create_scheduled_task` lokális Claude Code-ban
- TaskId: `valuta-error-monitor`
- Cron: `13 * * * *` helyi (8 perc jitter → ~`:21`)
- Path: `C:\Users\Kósa Zoltán\.claude\scheduled-tasks\valuta-error-monitor\SKILL.md`
- Workflow: `gh issue list` (last 90 perc) + Hetzner SSH `client_error_log` → klasszifikál → kommentál + opcionális <20 LOC auto-fix PR (NEM auto-merge)

### v2.5.18 telepítő build
- 4-way version sync: package.json (root + frontend-react + penztar-client) + backend/pom.xml mind 2.5.18
- `installer\build-installer.ps1 -SkipDownloads` futás
- Várt outputok (ha lefut): `installer/build/Penztar-Setup-2.5.18-20260505.exe`, `Penztar-Eltavolito-2.5.18-20260505.exe`
- Jellegzetességek a 2.5.13-hoz képest: V183 migráció bundled JAR-ban (FULL mode), Backend recompile a recent diagnostics PR-ekkel

## Mit tanultam

### Bizonyított architektúra patterns
- **Sentry-style data-ingest** önálló deployment-ben: HTTP POST + JSONB context + async eskala működik kis felhasználói körre.
- **Send-and-forget queue** klienseen: max 50 pending + 5 perc flush + 5s anti-spam — nem akasztja a UX-et.
- **`@PreAuthorize("permitAll()")` ÖNMAGÁBAN nem elég:** SecurityFilterChain HTTP filter blokkol előtte → kötelező a `requestMatchers().permitAll()` a SecurityConfig-ban.
- **IdempotencyFilter** EXCLUDED_PREFIXES kell a "stateless" diagnosztikai endpointokra — különben 400 "Missing Idempotency-Key".

### Hibernate gotcha (PR #414)
- A PostgreSQL `INET` típus + Hibernate alapértelmezett String mapping = `PSQLException: column is of type inet but expression is of type character varying`.
- Megoldás: `VARCHAR(45)` (IPv6 max 39 char + IPv4-mapped 45 char).

### Jackson 3 kompat (PR #413)
- A backend Jackson 3-at használ (`tools.jackson.databind.*`), de a `JsonNode` import még `com.fasterxml.jackson.databind.JsonNode` lenne — type incompatible.
- `Map<String, Object>` dual-stack (Jackson 2 + 3) kompatibilis.

### 4-way version sync (Build Gate)
- 4 helyen kell ugyanaz: `package.json` (root + frontend-react + penztar-client) + `backend/pom.xml`.
- A build-installer.ps1 gate hibázik exit 2-vel ha bármelyik nem stimmel.
- Manuális bumpoláshoz: `npm version X.Y.Z --no-git-tag-version` 3 helyen + Edit a pom.xml-ben.

### Local scheduled-tasks vs RemoteTrigger
- `mcp__scheduled-tasks__create_scheduled_task` — lokális Claude Code-ban tárol, `prompt` mező accepted.
- `RemoteTrigger` cloud — bonyolultabb session_request schema, prompt nem volt felvehető (proto-rejected fields). Egy disabled test trigger maradt: `trig_01QJNZFQpGxiyZiQeQQycsRo`.
- A user always-on desktop-on dolgozik (Windows 11 Pro), ezért lokális task elegendő.

## TODO (következő session)

- [ ] **v2.5.18 installer küldése Borsi + Helga + Tomi + Heni-nek** — Outlook + telepítési útmutatóval (NEM parancssori, csak dupla-klikk + UAC + admin jelszó!).
- [ ] **Ellenőrizni, hogy az első óránkénti routine futás (08:21 UTC) ad-e error reportot** — várhatóan üres lista, mert a smoke teszt issue le van zárva.
- [ ] **Vault memo: error-reporting iparági standard architektúra** — kész (`references/error-reporting-architecture.md`).
- [ ] **Sentry-style symbolicate** ha sok renderer minified stack jönni fog — nem most, csak ha tényleg jelentkezik.

## Hivatkozott commitok

```
7ebddb58 fix(diagnostics): client_ip INET -> VARCHAR(45) Hibernate kompat (V183 migracio) (#414)
4c64782f fix(diagnostics): JsonNode -> Map<String,Object> Jackson 3 kompatibilitas (#413)
1ded9206 fix(diagnostics): /api/v1/diagnostics/ idempotency-skip a IdempotencyFilter-be (#412)
8d788b07 fix(security): /api/v1/diagnostics/** endpoint permitAll a SecurityConfig-ban (#411)
efca745d feat(diagnostics): kritikus kliens hiba -> AUTO GitHub Issue auto-create (#410)
51ea70a8 feat(diagnostics): auto kliens-oldali hibajelentes (Sentry-style HTTP endpoint + PostgreSQL) (#407)
```

## User-direktíva alkalmazva

- ✅ NULLADIK PRIORITAS (NEM-INFORMATIKUS VÉGFELHASZNÁLÓK ALAPELV) — minden auto-eskala body-ban tilos parancssor / registry / hosts / antivirus
- ✅ Server-side Cloudflare IPv6 OFF (Cloudflare API PATCH /zones/{id}/settings/ipv6, token/id érték nélkül dokumentálva)
- ✅ Tokenek gitignored .env-ben + GitHub Push Protection-kompatibilis
- ✅ Auto error-reporting "automatikusan visszakerül hozzád javításra" (E2E verifikálva)
