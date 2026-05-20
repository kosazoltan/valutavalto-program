# VV Capability Map

> A VV-ELVI (`valutavalto-program-mukodes-leiras-2026-05-16.md`) minden elvárását kódbeli helyre, tesztre és státuszra (IMPLEMENTED / PARTIAL / MISSING / BLOCKED) képezi le.
>
> **Utolsó frissítés:** 2026-05-17 (PR #630 — v2 mandate betöltés)
> **Karbantartási szabály:** minden VV-ELVI capability-t érintő PR kötelezően frissíti ezt a fájlt.

## Státusz-jelölések

- **IMPLEMENTED** — kód jelen, teszt fed, működik
- **PARTIAL** — viselkedés-szinten működik, de hiányos teszt-coverage vagy hibás config
- **MISSING** — még NEM implementált, terv-tétel
- **BLOCKED** — külső függőség (pl. DigiCert cert kiadás) miatt nem indítható

## Capability táblázat

| Capability | VV-ELVI ref | Státusz | Kódbeli hely (irányadó) | Teszt | Gap |
|---|---|---|---|---|---|
| AML 100k identifikáció | 9.1 | IMPLEMENTED | `service/AmlService.java:SIMPLIFIED_IDENTIFICATION_LIMIT` | `AmlThresholdTest` (7 eset) | küszöb-coverage: <100k / 100-300k azonosítással és nélkül / ≥300k / ≥1.5M / érvénytelen összeg |
| AML 300k PEP | 9.1 | IMPLEMENTED | `service/AmlService.java:IDENTIFICATION_LIMIT` | `PepDeclarationTest` (TERVEZETT) | teszt-coverage |
| Sanction-list valós idejű | 9.1 | IMPLEMENTED | `service/SanctionScreeningService.java` (DB-cache + napi scheduler import) | `SanctionOfflineFallbackTest` (5 eset) | offline cache fallback KÉSZ (v2.5.91): `staleData`+`listAgeDays`, >7 nap/üres → degradált-jelzés + warning |
| SAR auto-flag | 9.1 | IMPLEMENTED | `service/AmlService.java` (4. szekció, `DAILY_SUSPICIOUS_LIMIT` 900k) | `SarAutoFlagTest` (5 eset) | napi göngyölt >= 900k → `suspiciousFlag`; blank customerId hardening |
| HUF kerekítés | 14.1 | IMPLEMENTED | `util/RoundHuf.java` | `RoundHufTest` (TERVEZETT bővítés) | — |
| Bizonylet-sorszám atomic | 14.2 | IMPLEMENTED | `service/ReceiptSequenceService.java` | `ReceiptSequenceTest` (TERVEZETT) | teszt-coverage |
| Sztornó szabályok (5) | 5.6 | IMPLEMENTED | `service/ReversalService.java` | `ReversalRulesTest` (TERVEZETT) | teszt-coverage |
| Napzárás kettős dimenzió | 5.7 | PARTIAL | `service/DailyClosingService.java` | `DailyClosingTest` (TERVEZETT) | per-companyId összesítés |
| Outbox 3× retry | 5.8 | IMPLEMENTED | `penztar-client/electron/sync/...` | `OutboxRetryTest` (TERVEZETT) | teszt-coverage |
| Outbox replay idempotens | 5.8 | IMPLEMENTED | `backend/.../IdempotencyFilter.java` | `IdempotencyTest` (TERVEZETT) | teszt-coverage |
| Heartbeat Zod-validált | 5.8 | IMPLEMENTED | `penztar-client/src/config/heartbeat.ts` | `HeartbeatConfigTest` (TERVEZETT) | teszt-coverage |
| RFM optimistic locking | 7.3 | MISSING | — | — | RateStateMachine + version + test |
| RFM spread-kapu (5%) | 7.2/4 | IMPLEMENTED | `service/RateSpreadGate.java` (egzakt kereszt-szorzás, bekötve `RateCreationService.publishGroupRateInternal`) | `RateSpreadGateTest` (8 eset) | v2.5.81: (sell−buy)/reference ≤ 5%, official/mid fallback |
| Központ aggregál, nem vezérel | 6. | PARTIAL | `kozponti-client/controller/*` (verify) | — | debt-scan szabály kell |
| `lastSyncedAt` minden aggregáción | 6. | PARTIAL | `CentralReceivedDataOverviewDto.lastSyncedAt` + `ReceivedDataOverviewPage` badge | `CentralReceivedDataServiceTest` | v2.5.80: ELSŐ surface (központi átvett-adat) kész; további aggregációk (Treasury, Region) hátravan |
| MNB 14:30 cron | 9.3 | IMPLEMENTED | `config/MnbDailyReportScheduler.java` (in-app `@Scheduled` 14:30 MON-FRI) | `MnbDailyReportSchedulerTest` (2 eset) | munkanapokon 14:30 generál napi DRAFT-ot minden aktív irodához (skip-if-exists); beküldés marad emberi (`/submit`) |
| NGM havi export | 9.2 | BLOCKED | — | manuális | a havi PTGSZLAH XML on-demand kész (`NavClosingController /ptgszlah/monthly`); automatizáláshoz **kézbesítési cél hiányzik** (hova/hogyan, auth) — üzleti input kell |
| NAV NPG real-time | 9.4 | PARTIAL | `service/NavService.java` (verify) | — | fallback offline bizonylat |
| SAR webhook | 9.1 | BLOCKED | `service/AmlService.java` (`suspiciousFlag` kész) | — | nincs definiált értesítési cél-URL/auth és a kódban semmilyen webhook/HTTP-notify infra — **üzleti input kell** (cél-endpoint + hitelesítés) mielőtt értelmesen megépíthető |
| Code-signing signed-only | 11. | BLOCKED | `windows-signed-release.yml` | smoke (TERVEZETT) | DigiCert HSM cert kiadás ~2026-05-21 |
| 4-way version sync | 11.1 | IMPLEMENTED | `business-invariant-guard.yml` #14 (BLOCKING) → `scripts/check-version-sync.mjs` (dedikált, csak verzió) | CI gate (PR-en fut) | release-atomikusság: 5 package.json + backend/pom.xml (valuta-backend) verzió eltérésnél exit 1; a pom.xml-t IS ellenőrzi |
| Multi-tenant izoláció | 3. | IMPLEMENTED | `*Repository.java` (companyId minden query-n) | `CrossTenantTest` (TERVEZETT) | teszt-coverage |
| TransactionStatus enum | v2 5.1 | MISSING | — | — | enum + state machine |
| RateStatus enum | v2 5.2 | MISSING | — | — | enum + state machine |
| `business-invariant-guard.yml` | v2 6. | PARTIAL (jelen PR-ben elindítva) | `.github/workflows/business-invariant-guard.yml` | — | 1/15 minta blocking (cash counter mező), 6/15 warning-only. Pontosabb regex/AST kell a többi blocking-ra konvertálásához. |

## Hivatkozott külső doksik

- `vault/feedback/_active_mandates.md` — aktív mandate-index
- `vault/feedback/claude-code-korrekcios-mandate-2026-05-17.md` — v1 mandate
- `vault/feedback/claude-code-valutavalto-korrekcios-mandate-2026-05-17-v2.md` — v2 mandate
- `vault/elvi/vv-elvi-mirror.md` — VV-ELVI tükör

## Karbantartási szabály

Minden PR, amely VV-ELVI capability-t érint:
1. Frissíti a megfelelő sor státuszát ebben a táblázatban
2. ELVI-compliance gate "VV-ELVI fejezet hivatkozás" sorában megjelöli a kapcsolódást
3. Új capability esetén új sor hozzáadása

## Tervezett tesztek prioritása (P0 → P3)

P0 (Pmt./AML kritikus): `AmlThresholdTest`, `PepDeclarationTest`, `SanctionListEnforcementTest`, `DailyAggregationTest`, `SarAutoFlagTest`
P0 (pénzügyi invariáns): `CashInventorySumInvariantTest`, `ReceiptSequenceTest`, `RoundHufTest`, `RateValidityTest`
P0 (multi-tenant): `CrossTenantTest`, `MultiTenantIsolationTest`
P0 (sztornó): `ReversalRulesTest` (5 negatív teszt)
P1 (outbox): `OutboxRetryTest`, `OutboxReplayTest`, `IdempotencyCoverageTest`
P1 (RFM): `RateStateMachineTest`, `OptimisticLockTest`, `SpreadGateTest`
P2 (heartbeat): `HeartbeatConfigTest`
