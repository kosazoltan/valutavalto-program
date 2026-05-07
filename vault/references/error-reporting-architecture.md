# Error-reporting architektúra (Sentry-style, in-house)

> **Tárgy:** Valutaváltó Pénztár automatikus kliens-hibajelentés pipeline.
> **Felépítés dátuma:** 2026-05-05.
> **Iparági inspiráció:** Sentry data-ingest model (HTTP POST + persistence + alerting), de saját szervereinken (Hetzner + PostgreSQL).

## Miért nem külső SaaS (Sentry, Bugsnag, Rollbar)?

1. **Tokenek és PII saját kontroll alatt** — magyar valuta ERP-ben van email, IP, branch-kód.
2. **Költség** — kis felhasználói kör (3-5 kollégák gépei), nem éri meg havidíjat fizetni.
3. **Auto-fix integráció a kód-CI-ba** — GitHub Issue + auto-triage routine közvetlen.
4. **Egyszerűbb network konfig** — ugyanaz a domain mint a backend (excvaluta.com), nincs CSP/CORS issue.

## Komponensek (data flow)

```
[Penztar.exe Electron client]
   │
   │ uncaughtException / setupWizard fail / axios error
   │ → ErrorReporter.report(...)
   ▼
[error-reporter.ts queue] (in-memory, max 50, anti-spam 5s)
   │
   │ HTTPS POST /api/v1/diagnostics/error-report (send-and-forget)
   ▼
[Hetzner backend: DiagnosticsController]
   │
   │ permitAll + idempotency-skip + rate-limit
   │ ErrorReportDto → ClientErrorLog entity
   ▼
[PostgreSQL: client_error_log table]
   │ (JSONB context, VARCHAR(45) IPv4/IPv6)
   │
   │ async @Transactional save
   ▼
[GitHubIssueAutoCreator @Async]
   │
   │ CRITICAL_PATTERN regex match? (uncaughtException|timeout|ECONNREFUSED|setupWizard.*fail)
   │ 24h dedup signature (component+errorMessage[0:80])
   ▼
[GitHub Issues] (label: client-error, auto-reported)
   │
   │ óránkénti cron (helyi Claude Code scheduled-tasks)
   ▼
[valuta-error-monitor routine]
   │
   │ gh issue list --label client-error,auto-reported (last 90 perc)
   │ classify + comment + opcionális <20 LOC auto-fix PR
   ▼
[Human review → merge → Hetzner deploy]
```

## Kliens-oldali pipeline (Electron)

**Fájl:** `penztar-client/electron/error-reporter.ts`

- `init()` regisztrál: `process.on('uncaughtException')`, `process.on('unhandledRejection')`.
- `report(component, message, error?, context?)` — anti-spam (min 5s ugyanazon msg között), max 50 pending.
- HTTPS request `electron.net.request` (TLS, default cert validation).
- Fire-and-forget: a kliens NEM várja a választ, így a hiba-bejelentés sem akasztja meg a UX-et.
- 5 perces flush ciklus a queue-n.
- Renderer process-ből: `window.electronAPI.reportError(...)` IPC hívás.

**Frontend (React, frontend-react/src/services/api/client.ts):**
- `axios` response interceptor: 4xx/5xx automatikusan elküldi (kivétel: auth/refresh).
- `window.onerror` + `unhandledrejection` capture.

## Backend-oldali pipeline (Spring Boot)

**Endpoint:** `POST /api/v1/diagnostics/error-report` (DiagnosticsController)
- `@PreAuthorize("permitAll()")` + SecurityConfig requestMatcher (PR #411).
- IdempotencyFilter EXCLUDED_PREFIXES (PR #412) — diagnosztikai endpointokra nem kell idempotency-key.
- Rate-limited a globális RateLimitingFilter által.

**DTO:** `ErrorReportDto`
- `Map<String, Object> context` (Jackson 3 kompatibilis, NEM `JsonNode` — PR #413).
- Méretkorlátok: errorMessage 1000, stackTrace 8000, osInfo 200, version 40, userIdentifier 150.
- `@Pattern` validáció a `component`-en (electron-main / electron-renderer / nsis-installer / axios-http / setup-wizard / sync-engine / other).

**Entity:** `ClientErrorLog`
- `client_ip VARCHAR(45)` (IPv4 + IPv6 mapped, NEM `INET` — PR #414 V183).
- `context JSONB` (Hibernate `@JdbcTypeCode(SqlTypes.JSON)` mapping).
- `created_at` PrePersist auto-fill.

**Migrációk:**
- `V182__client_error_log_table.sql` — initial table.
- `V183__client_error_log_ip_varchar.sql` — INET → VARCHAR(45) Hibernate kompat.

## Auto-eskala (GitHubIssueAutoCreator)

**Fájl:** `backend/src/main/java/hu/puzzleir/valuta/service/GitHubIssueAutoCreator.java`

- `@Async` — nem blokkolja a POST response-t.
- `CRITICAL_PATTERN` Pattern: `uncaughtException|timeout|ECONNREFUSED|setupWizard.*fail`.
- Csak akkor escalál, ha a regex matchel ÉS nincs duplikátum az utolsó 24 órában (signature: component+errorMessage[0..80]).
- GitHub REST API v3 issue creation `Authorization: Bearer <PAT>`.
- Token: `GITHUB_ISSUE_AUTO_CREATE_TOKEN` env var (Hetzner `.env` fájlban tárolva).
- **Privacy guard:** a body NEM tartalmaz `userIdentifier`-t, IP-t.

## Auto-triage (valuta-error-monitor scheduled task)

**Hely:** `C:\Users\Kósa Zoltán\.claude\scheduled-tasks\valuta-error-monitor\SKILL.md` (lokális Claude Code-ban tárolva).

**Cron:** `13 * * * *` helyi idő (8 perc jitter → ~`:21`-kor).

**Workflow:**
1. `gh issue list -R kosazoltan/valutavalto-program --label client-error,auto-reported --state open` (utolsó 90 perc).
2. SSH-on Hetzner `client_error_log` lekérdezés (kontextus, ami nem kerül GitHub-ra).
3. Klasszifikáció (Network Error / timeout / Setup Wizard fail / Hibernate / API contract).
4. Komment minden új issue-ra (klasszifikáció + valószínű root cause + javasolt fix).
5. Opcionális auto-fix PR <20 LOC tiszta esetekre (NEM auto-merge — human review).
6. >20 LOC vagy bizonytalan: `needs-human-review` label.
7. Duplikátum: close + `Duplicate of #X` komment + `duplicate` label.

**Token:** ugyanaz a `GITHUB_ISSUE_AUTO_CREATE_TOKEN` PAT (fine-grained, repo-scope: contents+issues+pull-requests).

## Tradeoffs (mit nem ad ez)

| Hiányzik | Miért OK most | Mikor lesz fontos |
|---|---|---|
| Source map symbolicate (renderer stack trace minified) | Devtools megnyitja, nem prod debug | Több ezer hiba/nap |
| Release Tracking automatikus | Manuális: `version` mező a DTO-ban | Több párhuzamos verzió fut |
| User session replay | Nem kell, nem GDPR-érzékeny | Sosem |
| Performance monitoring (transaction tracing) | Más eszköz (Spring Boot Actuator) | Backend-szintű probléma |
| Email/Slack alert | GitHub Issue notification e-mailben jön (Kósa Zoltán Anthropic settings) | Külön on-call rotation |

## Hogyan bővíteni

**Új komponens hibajelzés:**
1. Add a `@Pattern` regex-be a `component` validációba.
2. (Opcionális) Új CRITICAL_PATTERN entry a GitHubIssueAutoCreator-ban.

**Új klasszifikációs minta a routine-ban:**
- Edit `C:\Users\Kósa Zoltán\.claude\scheduled-tasks\valuta-error-monitor\SKILL.md`.
- Update táblázat + workflow.

**Új integráció (pl. Slack webhook):**
- `GitHubIssueAutoCreator` mintájára `@Async` szolgáltatás.
- Token env varba (`SLACK_WEBHOOK_URL`).

## Lezárt hibák (V182 → V183 evolúció)

1. **PR #407 (V182 + DiagnosticsController):** initial endpoint + table.
2. **PR #410 (GitHubIssueAutoCreator):** kritikus minta-eskala.
3. **PR #411 (SecurityConfig):** permitAll request matcher.
4. **PR #412 (IdempotencyFilter):** EXCLUDED_PREFIXES.
5. **PR #413 (ErrorReportDto):** JsonNode → Map (Jackson 3 kompat).
6. **PR #414 (V183):** INET → VARCHAR(45) Hibernate kompat.

E2E verifikáció **2026-05-05 07:04 UTC**: smoke POST → 200 OK → DB row id=1 → GitHub Issue #415 created → Issue closed.

## Hivatkozások

- **Iparági standard:** Sentry data-ingest [docs.sentry.io](https://docs.sentry.io/development/integrations/store/) (HTTP POST → store endpoint → projection).
- **Send-and-forget pattern:** [Async fire-and-forget HTTP queue](https://blog.bytebytego.com/p/event-driven-architecture-explained) (BBG).
- **PostgreSQL JSONB:** [Spring Data JPA + Hibernate JdbcTypeCode mapping](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#jpa.entity-persistence).
- **GitHub REST API v3 issues:** [docs.github.com/en/rest/issues/issues](https://docs.github.com/en/rest/issues/issues).
- **RFC 8252 OAuth Native Apps** (loopback redirect): [tools.ietf.org/html/rfc8252](https://tools.ietf.org/html/rfc8252) — kapcsolódó, mert ugyanazon az endpoint stack-en authentikálunk a desktop kliensből.
