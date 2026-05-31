# 2026-05-31 — Több-ügynökös kódbázis-audit + multi-tenant IDOR batch (v2.27.58)

## Kontextus
Új gép, `git pull` (a másik gép feltöltötte a hiányzó állapotot → HEAD `a3496b8b`, v2.27.57).
Production HEALTHY (bootstrap 200, EBC branches non-üres). A user kérése: dynamic workflow-val
több külön ügynökkel átnézni a teljes kódbázist hibákra/hiányosságokra, alapos ellenőrzés után folytatni.

## Audit (Workflow `vv-codebase-audit`, 53 ügynök, ~3M token, ~7,5 perc)
10 review-sáv párhuzamosan (multi-tenant IDOR, OSIV/LazyInit, pénzügyi integritás, AML/Pmt.,
security/OWASP, audit/error_code, FK/rate korrektség, frontend, electron-sync, teszt-hiányok),
minden találat **adverzariálisan verifikálva** a valós kód ellen (refute-default → 13 false-positive kiszűrve).

**Eredmény: 43 találat → 30 megerősített** (3×P0, 7×P1, 14×P2, 6×P3).

### A domináns minta: multi-tenant IDOR-klaszter
`@PreAuthorize` van (szerep), de hiányzik a `companyId` tulajdonos-ellenőrzés a single-id load után.

## JAVÍTVA — PR #934 (v2.27.58, branch `fix/tenant-idor-batch-audit-2026-05-31`)
- **P0** `RatePublishService.publish()` — workgroup + sablon tenant-check (idegen cég árfolyam-publikálása blokkolva).
- **P0** `InventoryService` approve/receive/cancel/getMovement — `assertMovementInCompany` (cash_balance-írás idegen mozgásra blokkolva).
- **P1** `InventoryMovementRepository.search()` — companyId-szűrés (LEFT JOIN, bank-mozgásra null-biztos).
- **P1** `InventoryService` bank/transfer/correction (`findBranch`) — `assertBranchInCompany`.
- **P1** `BranchService.create()` — cég a SecurityContextből, nem a kliens DTO-ból.
- Lappangó: `InventoryMovementService.getMovements/getDailyBalance` company-szűrt.
- **Teljes backend suite: 1762 teszt 0 hiba** (JDK 21). Új IDOR tesztek: Inventory 18/18, RatePublish 11/11, Branch 13/13.

## MARADÉK AUDIT-BACKLOG (verifikált, JAVÍTANDÓ — ld. külön referencia: audit-2026-05-31-confirmed-findings.md)
**P1 (4):** RateTemplate entity szerializálás → LazyInit 500 (nincs @JsonIgnore+@Transient getCompanyId, ellentétben RateWorkgroup); receiveMovement receivedAmount≠amount → készlet=SUM(tx) csendben sérül; AmlService.setHighRiskFlagIfNeeded SOHA nincs meghívva (halott AML-kontroll); TransactionServiceMultiTenancyTest tautologikus teszt.
**P2 (14):** árfolyam 24h TTL ~25h (ChronoUnit.HOURS csonkol); multi-line per-valuta HUF a kedvezmény ELŐTTI értékből; publishBatch megkerüli RateSpreadGate-et; Ertektar /bank-transactions nincs idempotencia → dup készletmozgás; V279 grace időablakos fiókátvétel; audit error_code-hiányok (AdminCurrencyService, TransactionOperationHelper VV-AML-004 a katalógusban van); outbox effektív-ráta NPE+divergencia; sync-engine standalone abandoned-szűrés hiánya; 3 tautologikus e2e teszt; korábbi-napi sztornó DailyBalance újraszámolás.
**P3 (6):** stockHuf longValue() csonkol; DailyBalance transfersIn/Out kettős igazságforrás; kamera hash-lánc error_code; fix vs képlet tizedes; recompute stale ctx; Pmt 300k boundary-teszt.

## Munkamód-tények (ezen a gépen)
- **JDK:** `JAVA_HOME` default JDK 25 → a surefire fork ELSZÁLL (byte-buddy-agent javaagent init).
  **Maven futtatás ELŐTT:** `$env:JAVA_HOME="C:\Program Files\Microsoft\jdk-21.0.11.10-hotspot"`.
- **Git identitás** repo-szinten: `Junior AI <kosa.zoltan.ebc@gmail.com>` (globálisan nincs beállítva).
- **Bash tool ≠ PowerShell here-string:** `@'...'@` NEM működik bash-ben (commit-msg fájlból `-F`).
- Verzió-bump 4-way: 5 package.json + backend/pom.xml; `node scripts/check-version-sync.mjs`.

## Következő lépés
PR #934 CI + AI-review readback (Codex triggerelve), majd a P1 maradék (RateTemplate LazyInit,
receiveMovement difference, AmlService highRiskFlag) következő batch-ben.
