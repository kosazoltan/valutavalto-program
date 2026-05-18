---
title: Belso log+audit modul implementacio (V234) - autonomous build
date: 2026-05-18
session_type: implementation
status: complete
---

# Belso log+audit modul - V234 (2026-05-18)

## Cel

A user szerint a kollegak hibait NEM lehet kulso szerveren (Datadog/Sentry/Loki) figyelni — a sajat Hetzner-en futo backend-en belul kell egy belso log+audit rendszert epiteni, amely:

1. AI-olvashato hibakat ad ki (event_type + error_code + ai_fix_hint)
2. Strukturalt audit-log-ot vezet hash-chain-nel (tamper-evidence)
3. PII-mossuk (jelszo, JWT, IBAN, kartyaszam, email, magyar szig.szam)
4. Frontend + Electron klienseket is forwardol a backend-re

Forras-tervezet: `vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md`

## Megvalositott komponensek

### Lepes 1: `packages/shared-logging/` (TS + YAML SSOT)

- `error-codes.yaml` - 30 AI-olvashato hibakod (VV-AML / VV-BIZ / VV-RATE / VV-MT /
  VV-SYNC / VV-NET / VV-REG / VV-SEC / VV-VOICE / VV-TECH kategoria)
- `src/log-schema.ts` - VVLogEntry TS interface (a backend ES frontend ezt hasznalja)
- `src/redactor.ts` - PII regex redactor (7 pattern)
- `package.json` - `@valuta/shared-logging` v1.0.0

### Lepes 2a: Flyway `V234__audit_log_immutable_hash_chain.sql`

ALTER TABLE audit_log ADD COLUMN (idempotens, IF NOT EXISTS):
- `event_id` UUID UNIQUE (idempotency)
- `ts` TIMESTAMPTZ (idozona-tudatos, backfill `created_at AT TIME ZONE 'UTC'`-bol)
- `event_type` VARCHAR(80) (AI-olvashato categorizalas)
- `before_state` / `after_state` JSONB
- `amount` NUMERIC(18,2) + `currency` + `receipt_number`
- `trace_id` VARCHAR(32) (W3C TraceContext)
- `client_context` ('CASHIER' | 'TREASURY_HQ' | 'RFM' | 'ADMIN')
- `signed_by` (manager-approval), `worker_role`

3 uj index (trace_id, event_type+ts, entity+ts).

KRITIKUS: postgres `audit_log_immutable()` trigger - UPDATE+DELETE blokk.
A meglevo INSERT-csak flow-k zavartalanul mennek tovabb.

### Lepes 2b: Backend Logger

- `backend/src/main/java/.../logging/VVLogger.java` - SLF4J wrapper MDC-management-tel.
  Metodusok: `info()`, `warn()`, `error()`, `fatal()`, `debug()`.
  `error()`: errorCode-bol auto-derivalt `error_category` (VV-AML → AML, etc.)
- `RedactingPatternConverter.java` - Logback `%redact(%msg)` custom converter.
  7 PII pattern (OpenAI key, JWT, Bearer, email, IBAN, card PAN, HU id card)
- `logback-spring.xml` - production: JSON (LogstashEncoder) + 100MB rolling +
  90 nap retention + 10GB total cap; dev: default Spring console
- pom.xml: logstash-logback-encoder 8.0 + micrometer-tracing + tracing-bridge-otel

### Lepes 2c: AuditLog entity bovites + AuditEventService

`AuditLog.java` 12 uj mezovel bovult (event_id, ts, event_type, before_state,
after_state, amount, currency, receipt_number, trace_id, client_context,
signed_by, worker_role). Backward-compat: regi entry_hash + previous_hash
mezok megmaradnak, az UJ AuditEventService is ezeket allitja be (NEM par
oszlop, ugyanaz a chain).

`AuditEventService.java` (NEW):
- `appendEvent(AuditEventRequest)` - hash-chain INSERT
  - GENESIS_PREV_HASH = '0'.repeat(64)
  - SHA-256(prev_hash || event_id || ts || event_type || after_state)
- `findAuditChain(entityType, entityId)` - idorendi lekerdezes
- `verifyHashChainIntegrity(int lastN)` - tamper-detection
- Builder-pattern `AuditEventRequest` record (22 mezo)

`AuditLogRepository.java` 4 uj metodus:
- `findTopByOrderByCreatedAtDesc()` - prev_hash lekerdezes
- `findTopNByOrderByCreatedAtDesc(int n)` - integritas-check
- `findByEntityTypeAndEntityIdOrderByTsAsc(String, String)`
- `findByTraceIdOrderByTsAsc(String)`
- `findRecentTopN(int)` - admin dashboard

### Lepes 2d: REST API + DTOs

`AuditDiagnosticsController.java` (prefix `/api/v1/diagnostics/audit`):
- `GET .../recent-errors` - utolso N esemeny (ADMIN/SUPPORT/MANAGER)
- `GET .../trace/{traceId}` - korrelacios kereses
- `GET .../entity/{entityType}/{entityId}` - audit-lanc
- `GET .../error-codes` - YAML katalogus (authenticated)
- `GET .../hash-chain-verify` - tamper-detection (ADMIN only)
- `POST .../log` - frontend ERROR/WARN forward (authenticated)

4 DTO: `AuditLogEntryResponseDto`, `ErrorCodeCatalogDto`, `HashChainIntegrityResponseDto`,
`FrontendLogEntryRequestDto`.

`ErrorCodeCatalogService.java` - YAML loader (`@PostConstruct` cache).
pom.xml `<resource>` definicio masolja a `packages/shared-logging/error-codes.yaml`
fajlt a classpath gyokere ala.

### Lepes 2e: Backend tesztek (20/20 PASS)

- `RedactingPatternConverterTest` - 9 teszt (7 PII pattern + null + multi-PII)
- `AuditEventServiceHashChainTest` - 7 teszt (determinizmus + hossz + lanc invarians)
- `VVLoggerTest` - 4 teszt (MDC cleanup garancia)

Maven: `./mvnw test -Dtest='Red*,AuditEventServiceHash*,VVLoggerTest'`
→ `Tests run: 20, Failures: 0, Errors: 0, Skipped: 0` ✅

### Lepes 3: Frontend (React)

- `frontend-react/src/utils/vvLogger.ts` - kliens-oldali wrapper.
  ERROR/WARN: lokalis console + backend `/api/v1/diagnostics/audit/log` forward.
  INFO/DEBUG: csak lokalisan.
- `frontend-react/src/services/api/diagnostics.ts` - V234 API client kibovites
  (auditDiagnosticsApi: recentErrors, byTrace, entityChain, errorCodes,
   verifyHashChain, forwardLog).
- `frontend-react/src/pages/admin/AuditDiagnosticsPage.tsx` - admin UI.
  Funkciok: hash-chain integritas check + trace-ID kereses + utolso 100 esemeny
  + hibakod-katalogus.
- `App.tsx`: `/admin/audit-diagnostics` route hozzaadva.
- `menuGroups.ts`: "Audit-diagnosztika (V234)" menupont (ugyvezeto/belso_ellenor/
  biztonsagi_vezeto).

Frontend tsc: clean (0 error).

### Lepes 4: Electron 3 kliens (penztar / kozponti / arfolyam)

`<client>/electron/vv-logger.ts` (mindharom kliensben):
- electron-log/main wrapper
- WARN/ERROR -> backend net.request forward (send-and-forget)
- auth bearer token kotelezo (a backend endpoint @PreAuthorize('isAuthenticated()'))
- anti-spam: min 2 mp ket forward kozott
- truncate: message 500ch, stack 4000ch
- Default clientContext: penztar=CASHIER, kozponti=TREASURY_HQ, arfolyam=RFM

KULONBSEG az existing `error-reporter.ts`-tol:
- error-reporter.ts: unhandled exception forward `/error-report` -> client_error_log
- vv-logger.ts: STRUKTURALT business event-ek `/audit/log` -> audit_log (V234)

mindharom kliensben node-tsc: clean (0 vv-logger.ts error).

### Lepes 5: CLAUDE.md update

V234 mandate hozzaadva: minden `vvLogger.error()` hivasban kotelezo
error_code (lasd packages/shared-logging/error-codes.yaml-t). Uj kodot
hozzaadni az error-codes.yaml-be is.

## Tesztelesi terv (kovetkezo lepes)

1. **Lokalis Flyway migracio**: `./mvnw spring-boot:run -Dspring-boot.run.profiles=dev`
   - V234 ALTER TABLE futtatasa
   - 12 uj oszlop ellenorzese
   - immutable trigger smoke check

2. **Backend smoke test (Hetzner)**:
   - PR-be tenni a V234 migraciot
   - merge utan auto-deploy
   - audit_log tabla `\d audit_log` ellenorzes
   - 1 test transaction → ts/event_id auto-fill

3. **Frontend kapcsolat-teszt**:
   - `npm run dev` - admin login
   - `/admin/audit-diagnostics` route latogatas
   - hash-chain-verify gomb (ervenyes valasz)
   - error-codes katalogus betoltodes

4. **Electron kliens teszt**:
   - `npm run dev:main` indul a penztar-clienttel
   - `configureVvLogger({ clientContext: 'CASHIER' })` hivas
   - artificial `vvLogger.error('VV-TECH-002', 'test.error', new Error('teszt'))`
   - PostgreSQL `audit_log` ellenorzes: event_type='test.error' bejegyzes

## Kovetkezo PR scope

Egy PR (#680?):
- `feat(audit): V234 belso log+audit modul (AI-olvashato hibakodok + hash chain)`
- 31 fajl modositas/uj
- BREAKING: nincs (csak ALTER TABLE ADD COLUMN IF NOT EXISTS)
- Telepito impact: nincs (csak runtime config)
