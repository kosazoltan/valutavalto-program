# 2026-05-24 — AI_INTERNAL_SECURITY_AUDIT V2.0 végrehajtás (v2.26.37)

## Összefoglalás

Az `AI_INTERNAL_SECURITY_AUDIT_INSTRUCTIONS.md` V2.0 audit kézikönyvet (8 szabály, Antigravity AI Senior Security Architect Agent) végrehajtottuk a teljes valutaváltó kódbázison. PR #824 squash-merged, Hetzner deploy SUCCESS, production HEALTHY 200.

## Auditált szabályok és eredmény

| Szabály | Státusz | Finding | Javítás |
|---------|---------|---------|---------|
| BOLA-101 Multi-tenant IDOR | ✅ PASS (2 false positive) | TransactionService/DailySessionService branchId JWT-ből jön (nem user input) | — |
| AUTH-102 Controller PreAuthorize | ⚠️ HIGH javítva | CustomerController.findCustomers() csak isAuthenticated() | @PreAuthorize("hasAnyRole(...)") |
| AUTH-102 ArchiveTask | ⚠️ HIGH javítva | ArchivingService nincs company-scope | F3.1 teljes fix |
| CONC-103 Pessimistic lock | ✅ PASS | findByIdForUpdate() PESSIMISTIC_WRITE meglévő | — |
| MFA-104 | ✅ PASS | BCrypt12 backup kódok (PP-16) | — |
| XXE-105 XML parser | ✅ PASS | DocumentBuilderFactory disallow-doctype-decl=true | — |
| PREC-201 SQLite REAL | ✅ intentional | REAL + roundFin (PP-09 döntés) | — |
| IPC-202 Electron | ✅ PASS | contextIsolation=true | — |
| TRIG-301 BEFORE DELETE trigger | ✅ PASS (V263 javította) | V234 trigger bug már javítva | — |
| F8.B RTSP injection | ⚠️ MEDIUM javítva | error message credential szivárgás | validateRtspUrl() credential redact |

## Implementált javítások (PR #824, 4 commit)

### Commit 1 — alapjavítások
- **WebSocketConfig** (F1.2): `valuta-frontend.vercel.app` stale origin eltávolítva
- **ArchiveTask** entity: `Company @ManyToOne` + V264 migration
- **ArchiveTaskRepository**: `findByCompanyId` + `findByIdAndCompanyId`
- **ArchivingService**: getAllTasks/createTask/executeTask company-scope + branchId IDOR check + task.setId(null)
- **ArchivingServiceTenantTest**: 5 unit teszt
- **rtsp-recorder.ts** (F8.B): `validateRtspUrl()` credential redact

### Commit 2 — Copilot P1 (korábbi review alapján)
- ArchivingService `task.setId(null)` task-hijacking prevention (explicit)
- branchId cross-tenant ownership check
- RTSP error message nem tartalmaz teljes URL-t

### Commit 3 — AUTH-102 CustomerController
- `CustomerController.findCustomers()` `@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")` hozzáadva

### Commit 4 — Copilot P1 × 2
- `ArchiveTask.company`: `@JsonIgnore` (LAZY + REST controller közvetlen entity return → LazyInitializationException)
- V264 migration: branch-ownership backfill (criteria branchId → branch.company_id), csak fallback az első cégre

## False positive-ok dokumentálva

- **BOLA-101 TransactionService.executeBuy/executeSell**: `branchId = SecurityUtils.getCurrentBranchId()` — JWT-ből jön, nem user input
- **BOLA-101 DailySessionService.openDay**: ugyanez
- **PREC-201**: 32 REAL kolumna szándékos döntés (PP-09), TEXT → REAL visszaállítás Codex P1 alapján (TEXT + `.toFixed()` = runtime crash)

## AI review eredmény

- **Codex**: boilerplate (commit 8d9f065c — nincs P0/P1)
- **Sourcery**: weekly rate-limit (skipping)
- **Copilot**: P1 × 2 javítva, P2 × 5 kezelve (3 stale/már javított, 1 WebSocketConfig szándékos, 1 V264 backfill javítva)

## Verzió

- **v2.26.37** — backend + Electron rtsp-recorder.ts érintett
- **4-WAY TELEPÍTŐ-BUILD SZÜKSÉGES** (rtsp-recorder.ts Electron-natív)
- Production: excvaluta.com/api/v1/auth/bootstrap-status → HTTP 200

## Nyitott következő feladatok

- 4-way installer build (v2.26.37) — rtsp-recorder.ts változás miatt kötelező
- N5 METRO/TESCO elkülönített ÁFA-visszatérítő (halasztva)
- DigiCert EV CS cert (folyamatban)
