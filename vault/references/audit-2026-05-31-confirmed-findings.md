# Audit 2026-05-31 — 30 megerősített finding (adverzariálisan verifikálva)

Forrás: `vv-codebase-audit` workflow (53 ügynök, 10 sáv, refute-default verifikáció → 13 false-positive kiszűrve).
HEAD `a3496b8b` (v2.27.57). Minden finding kód-tény (file:line + idézet) alapú.

## ✅ JAVÍTVA — PR #934 (v2.27.58)
- **P0** `RatePublishService.publish()` (publish 64–136) — workgroup+sablon tenant-check.
- **P0** `InventoryService` approve/receive/cancel/getMovement (findMovement* 660–680) — assertMovementInCompany.
- **P1** `InventoryMovementRepository.search()` (31–44) — companyId LEFT JOIN.
- **P1** `InventoryService` bank/transfer/correction (`findBranch` 645) — assertBranchInCompany.
- **P1** `BranchService.create()` (390–399) — cég a SecurityContextből.

## ⬜ MARADÉK — P1 (4)
1. **RateTemplate entity szerializálás → LazyInit 500.** `entity/RateTemplate.java:24-26` lazy `company`, nincs `@JsonIgnore`+`@Transient getCompanyId()` (ellentétben RateWorkgroup:28,82). A RateManagementController GET/approve/revoke az ENTITÁST adja vissza → OSIV=false → 500. Fix: RateWorkgroup-minta v. DTO v. JOIN FETCH.
2. **receiveMovement receivedAmount ≠ amount.** `InventoryService.java:234-256` a forrást `movement.getAmount()`-tal terheli, a célt a kliens `receivedAmount`-tal írja; difference-rekord + audit nélkül → készlet=SUM(tx) csendben sérül. (Vö. TransferService.receiveTransfer:146-183 helyes mintája.)
3. **AmlService.setHighRiskFlagIfNeeded SOHA nincs meghívva.** `AmlService.java:997-1020` — halott write-oldali AML-kontroll; a highRiskFlag éles üzemben sosem aktiválódik. Hívás kell a BUY/SELL/KONVERZIO könyvelés után.
4. **Tautologikus multitenancy teszt.** `test/.../TransactionServiceMultiTenancyTest.java:157-182` közvetlen mockot hív+verifikál (nem a service-en át) → nulla IDOR-regresszió-védelem.

## ⬜ MARADÉK — P2 (14)
- Árfolyam 24h TTL ~25h: `ExchangeRateService.java:84-85` `ChronoUnit.HOURS.between` csonkol + `> maxAgeHours`. Fix: percalapú `>=`.
- Multi-line per-valuta HUF a kedvezmény/díj/kerekítés ELŐTTI sorértékből: `TransactionMultiLineService.java:119-128,222` + `TransactionLineRepository:42`.
- publishBatch megkerüli a RateSpreadGate-et: `RateManagementController.java:82-100` (spread-kapu csak RateCreationService.publishGroupRateInternal:562).
- Ertektar `/bank-transactions` nincs idempotencia → dup készletmozgás replay-nél: `ErtektarController.java:127` + `VaultBankTransactionService.createBankTransaction:64-132`.
- V279 grace időablakos publikus fiókátvétel: `V279__worker_setup_grace_transition.sql:14-17` + `WorkerFirstTimeSetupService.java:139-146`.
- Audit error_code-hiány: `AdminCurrencyService.java:140` (audit-write fail, nincs kód az error-codes.yaml-ben) és `TransactionOperationHelper.java:66` (VV-AML-004 LÉTEZIK a katalógusban, mégsem használt).
- Outbox effektív-ráta NPE+divergencia: `RatePublishService.java:199-200` nyers `add()` null-spread NPE + skála/officialRate eltér a perzisztálttól (addSpread/mergeRate helper létezik, nem hívott).
- Lokál csomag-publish tenant: `RateCreationService.java:458-503,522-541,598` findById(groupId) tenant-check nélkül (a #934 publish-fixe részben fedi).
- Korábbi-napi sztornó → DailyBalance újraszámolás: `TransactionReversalService.java:70-72,175` (nyitott-nap esetre).
- Sync-engine standalone abandoned-szűrés hiánya: `penztar-client/electron/sync-engine.ts:1521-1657` (head-of-line block + végtelen retry).
- 3 tautologikus e2e teszt: `frontend-react/e2e/rates.spec.ts:158,172`; `penztar-client/e2e/bootstrap-auth.spec.ts:164-171`; `frontend-react/playwright/visual/receipt-snapshots.spec.ts:26-42`.

## ⬜ MARADÉK — P3 (6)
- `StockSnapshotService.java:215` stockHuf `longValue()` csonkol (HALF_UP kell).
- `DailyBalanceService.java:92-102,294` transfersIn/Out Transfer-ből, az InventoryMovement-ág nem látszik (kettős igazságforrás).
- `CameraHashChainService.java:122-125,157` tamper-log error_code nélkül (audit_log megvan).
- `RateCreationPage.tsx:227-229` fix vs képlet eltérő tizedes-megjelenítés.
- `RateCreationPage.tsx:254-256` recompute stale sheetCtxRef (több-tab edge).
- `test/.../PmtComplianceValidatorTest.java:72-81` nincs 300k boundary-teszt.

## ✅ Helyesen kiszűrt false-positive-ok (13) — NE jelentsd újra
fallback-J megkerülés (középérték-ág garantálja buy≤J); localStorage Zod-hiány (van try/catch); float a képletmotorban (passzonkénti toFixed); kozponti full-mód 404 (renderer sosem hívja a save handlereket); 3.6M self-approve (role-gate megvan); Google-login/setup error_code (kódbázis-szintű norma, ConflictException blokkol); 0-érték snapshot-vesztés (numerikus rows-ból ment); önreferáló self-snapshot (DB UNIQUE); parseNum 0-fallback (validRates szűr); backend-500 test.skip (nem CI-gated).
