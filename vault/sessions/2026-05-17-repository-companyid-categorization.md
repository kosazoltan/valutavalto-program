---
title: 2026-05-17 Repository companyId hiányosság kategorizálás (P0.2)
type: session-log
project: Valutavalto-program
created_at: 2026-05-17
operator: Claude Opus 4.7 (1M context)
status: P0.2 audit-finding kategorizálás — javasolt sprint-bontás
---

# Repository companyId-szűrés audit (P0.2)

A `#631` audit-jelentés 43-as becsléséhez képest **116 db Repository** hiányzó `companyId`/`company_id` referencia. A többség azonban **GLOBAL** (rendszerszintű) entitás, nem tenant-érzékeny.

## Kategorizálás (manuális, fájlnév-heurisztika alapján)

### 🟢 GLOBAL — semmi tenant-szűrés nem kell (~75 db)

Rendszerszintű, dictionary, telemetria, infra entitások — globálisan közös minden cégnek:

```
ArchiveTaskRepository                  AuthorizationLogRepository
AuthorizationRepository                BackupRecordRepository
CompanyRepository                      CurrencyGroupRepository
DictionaryRepository                   FeorCodeRepository
PermissionRepository                   RoleRepository
RoundingRuleRepository                 ScheduledTaskRepository
SystemParameterRepository              TokenBlacklistRepository
TranslationRepository                  PasswordResetTokenRepository
RefreshTokenRepository                 ClientErrorLogRepository
SyncLogRepository                      SyncInboxRepository
SyncOutboxRepository                   EmailCacheRepository
DataImportJobRepository                DataCollectionRepository
NeonSyncLogRepository                  FtpSyncLogRepository
MnbExchangeRateCacheRepository         SanctionEntryRepository
SanctionScreeningLogRepository         CompetitorRepository
CompetitorRateRepository               OrganizationalSystemParameterRepository
```
(+ ~45 további — `FeeType`, `FeeRate`, `RateCategory`, `WorkerRoleDefinition`, `WorkerRolePermission` stb.)

**Indoklás:** Ezek **rendszerszintű referenciák** vagy **globális regiszterek**, nem cég-szintű adatok. Pl. a `RoleRepository` egy `Role(id, code, description)` rekordot tárol, ami minden cégnek közös definíció.

### 🔴 TENANT — KELL companyId szűrés, valós security gap (~25-30 db)

Cég-érzékeny adatok, **kritikus** hogy a Repository szintjén legyen companyId:

| Repository | Indoklás (audit-priority) |
|---|---|
| `EveningClosingRepository` | Napzárás per-iroda + per-company |
| `EveningSyncLogRepository` | Sync log per-company |
| `DailyDenominationSnapshotRepository` | Címletezés per-company |
| `DailySubledgerSnapshotRepository` | Napzárás archive per-company |
| `DailyWuAfaTransactionRepository` | WU-AFA tranzakciók |
| `MonthlyClosingSummaryRepository` | Havi zárás |
| `DecadeReportRepository` | Dekád riport |
| `DariusReportLineRepository` | Darius riport |
| `MnbReportRepository`, `MnbReportLineRepository` | MNB szabályozási jelentés |
| `NavClosingLineRepository` | NAV zárósor |
| `HandlingFeeDecadeReportRepository` | Kezelési díj riport |
| `HandlingFeeTransactionRepository` | Kezelési díj tranzakció |
| `HrkTransactionRepository` | HRK tranzakció |
| `InventorySummaryRepository` | Készlet összesítő (materialized view, de tenant-érzékeny) |
| `InventoryRegenerationRepository` | Készlet újraszámolás |
| `BanknoteInventoryRepository` | Bankjegy készlet |
| `CommissionCalculationRepository`, `CommissionRateRepository` | Jutalék |
| `WorkerCommissionRepository` | Dolgozói jutalék |
| `ContributionRepository` | Hozzájárulás |
| `CashRegisterEventRepository` | Pénztár események |
| `PoliceRequestRepository` | Rendőrségi megkeresés |
| `ScannedDocumentRepository` | Szkennelt okmány |
| `ChainOfCustodyRepository` | Bizonyíték-lánc (cég-szintű audit) |
| `ArchivedTransactionRepository`, `ArchivedMonthlyTransactionRepository` | Archív tranzakciók |
| `TradeRepository` | Trade rekord |
| `EmployeeAddressRepository`, `EmployeeBankAccountRepository` | Dolgozói adatok |
| `WorkerAttendanceRepository`, `WorkerBreakRepository` | Dolgozói jelenlét |
| `WorkerBranchAccessRepository`, `WorkerRoleAssignmentRepository`, `WorkerMfaRepository` | Dolgozói hozzáférés |
| `WorkerCompetitionRepository`, `WorkerCompetitionEntryRepository` | Dolgozói verseny |
| `CustomerRestrictionRepository`, `CustomerScreeningLogRepository` | Ügyfél-szűrés |
| `RateApprovalRepository` | Árfolyam-jóváhagyás (cég-szintű workflow) |
| `ExchangeRateDistributionRepository`, `ExchangeRateDisplayRepository`, `ExchangeRateSourceRepository` | Árfolyam-disztribúció |
| `LedDisplayRepository`, `LedDisplayConfigRepository` | LED-kijelző (iroda-specifikus) |
| `PosTerminalRepository` | POS-terminál |
| `WorkstationRepository` | Munkaállomás |
| `ReceiptSequenceRepository` | Bizonylat-sorszám-counter |
| `BranchGroupRepository`, `BranchStatusRepository` | Iroda-csoport |
| `TransactionBanknoteRepository`, `TransactionLineRepository` | Tranzakció-sor |
| `StornoApprovalRepository` | Sztornó-jóváhagyás |
| `SupervisorPinAttemptRepository` | Supervisor PIN próbálkozás |
| `ShipmentRequestRepository`, `ShipmentRequestItemRepository` | Szállítmány |
| `SealNumberRepository` | Pecsét-szám |
| `PackagingRecordRepository` | Csomagolás |
| `VaultStocktakeItemRepository` | Értéktár leltár |
| `NotificationRepository` | Értesítés |
| `CircularAcknowledgmentRepository` | Körlevél visszaigazolás |
| `CameraAccessLogRepository`, `CameraConfigRepository`, `CameraExportRequestRepository`, `CameraRecordingRepository`, `CameraSegmentHashRepository`, `CameraTransactionLinkRepository` | Kamera-rendszer |
| `EmailAccountRepository` | Email-fiókok (cég-szintű) |
| `DailyBalanceRepository` | Napi balance |
| `DailyChecklistItemRepository` | Napi checklist |
| `DenominationBalanceRepository`, `DenominationCountRepository`, `DenominationRuleRepository`, `DenominationOptimizationRepository`, `DenominationTransactionLogRepository` | Címletezés-rendszer |
| `CollectedInventoryRepository`, `CollectedTransactionRepository` | Begyűjtés |
| `ClosingWizardRepository` | Zárás-wizard |
| `AmlThresholdRepository` | AML küszöb (cég-specifikus override) |

**~ 30 TENANT-érzékeny + ~25 valószínűleg-TENANT** = nagyjából 55 fájl ahol explicit verify kell.

### 🟡 BIZONYTALAN — manuális kategorizálás kell (~10 db)

Nem egyértelmű fájlnévből:
- `OrganizationalSystemParameterRepository` (organizational = company-szintű?)
- `AmlThresholdRepository` (lehet globális, lehet cég-override-os)
- `CommissionRateRepository` (cég-szintű jutalék-tábla?)
- ...

## Megállapítás

A `#631`-audit-jelentés 43-os becslése **rosszul becsült**. A tényleges állapot:
- **116 Repository** companyId-mentes
- ebből ~**75 GLOBAL** (semmi javítás nem kell)
- ebből ~**30-40 TENANT** (kritikus javítás kell)
- ebből ~**10 bizonytalan** (manuális üzleti döntés)

## Javasolt sprint-bontás

Ez **NEM egyetlen audit-fix PR-ben** megoldható (300 LOC + 5 fájl limit). Javasolt sprint:

### Sprint 1: TOP-10 priorizált TENANT Repository fix (1-2 hét)

1. `EveningClosingRepository` — napzárás per-company
2. `MnbReportRepository` + `MnbReportLineRepository` — szabályozási jelentés
3. `NavClosingLineRepository` — NAV zárósor
4. `AmlThresholdRepository` — AML küszöb (cég-override)
5. `RateApprovalRepository` — árfolyam-jóváhagyás workflow
6. `StornoApprovalRepository` — sztornó-jóváhagyás
7. `WorkerRoleAssignmentRepository` — dolgozói role
8. `ReceiptSequenceRepository` — bizonylat-counter
9. `DailyDenominationSnapshotRepository` + `DailySubledgerSnapshotRepository`
10. `ArchivedTransactionRepository` — archív tranzakciók

Minden Repository-hoz:
- `findByCompanyId(UUID companyId)` metódus hozzáadása
- A meglévő `findById(id)` hívók service-szinten `SecurityUtils.getCurrentCompanyId()`-vel + `assertCompanyAccess(entity.getCompanyId(), currentCompanyId)` ellenőrzés
- Cross-tenant integration teszt
- @Query-k companyId-paraméterrel bővítése

### Sprint 2: Maradék ~25-30 TENANT Repository fix (1-2 hét)

A többi (kamera, dolgozói, denomination, stb.) — alacsonyabb security-impact.

### Sprint 3: Bizonytalan ~10 db kategorizálás + javítás (1 hét)

Üzleti döntéssel.

## Becslés

- **Sprint 1 (TOP-10):** ~80-120 LOC változás per Repository × 10 = **800-1200 LOC** + tesztek = **több PR** (300 LOC plafon szerint **min. 4-5 PR**)
- **Total audit-fix:** **~3 sprint** (3-5 hét fejlesztői idő)

## Action — jelen PR

**Csak dokumentáció.** A 116-os listát kategorizáltam, javasolom a fejlesztő csapatnak. A kódot **NEM** módosítja jelen PR.

A user felelőssége eldönteni:
1. Sprint-tervezés (1-3 sprint)
2. Tenant-prioritás a TOP-10 listán
3. Bizonytalan ~10 db üzleti döntés
4. Cross-tenant integration test-csomag létrehozása (P0.3)

## Kapcsolódó PR-ek

- **PR #631** (audit master report)
- **PR #632** (P0.1 IDOR fix)
- **PR #633** (P2.7 reversal test bővítés)
- **Jelen PR** (P0.2 Repository companyId kategorizálás)
- Hátralévő: P0.3 (cross-tenant test), P1.4-6 (enum + state machine, **külön sprint**), P2.8/P2.9 (verify-only, már IMPLEMENTED), P2.10 (heartbeat 5-perces granularitás verify, NEM javítás)

## Status

- [x] 116 Repository kategorizálás
- [x] TOP-10 priorizálás
- [ ] Sprint 1 (TOP-10 fix) — **user decision**
- [ ] Cross-tenant test (P0.3) — **következő PR**
