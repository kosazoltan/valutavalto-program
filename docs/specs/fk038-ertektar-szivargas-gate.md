# Spec: FK-038 — Értéktár (is_vault) szivárgás-gate a pénztári nézetekbe

> Dátum: 2026-06-21 · Szerző: Junior AI (Opus) · Állapot: JÓVÁHAGYVA (implementálva + verifikálva)
> Kiváltó: a Dashboard „Zárási állapot (ma)" widget tévesen listázott/elveszített értéktárat (v2.28.13 hibajelentés).

## 1. Cél

Az **értéktár (`is_vault=TRUE`) branch SOHA ne jelenjen meg pénztári nézetekben**, és ne is
keletkezzen rá pénztári adat. Invariáns: értéktárnak **nincs** `cash_balance` (pénztár-kassza)
sora és **nincs** pénztári `daily_session`-je; az értéktár-készlet a `currency_stock` /
`vault_territory` úton él, zárása a `VaultClosingChecklist` + `ClosingControl` úton megy.
A Dashboard „Zárási állapot (ma)" widgetbe értéktár sem az A- (daily_session), sem a B-
(cash_balance) forráson át ne szivároghasson, és a forrásadat se sérthesse az invariánst.

## 2. NEM cél (out of scope)

- A `getCompanyTotals` / `getCompanyCashPosition` cég-szintű aggregátumok szűrése — külön
  üzleti döntés; szándékosan a sima `findByCompanyId`-n maradnak (FK-038 NEM bolygatja).
- Az értéktári **pénzügyi** napizárás (forgalmi snapshot / zárószalag-nyomtatás / könyvelés)
  bevezetése — ilyen entitás ma nincs; külön feature, nem ennek a hibajavításnak a tárgya.
- A `VAULT_COUNTERPARTY` virtuális partnerek kezelése — az FK-032 hatóköre, változatlan.
- A `denomination` (címletezés) init — nem szivárgási vektor a widgetbe, érintetlen.

## 3. Érintett területek

- `service/CashBalanceService.java` — `getCompanyBalances` (R1), `initializeBranchBalances` (G3)
- `repository/CashBalanceRepository.java` — `findByCompanyIdExcludingVault` (R1)
- `service/DailySessionService.java` — `openDay` (G1), `getSessionHistory` (R2)
- `service/SessionOpenService.java` — `openSession` (G2)
- `repository/DailySessionRepository.java` — `findByDateRangeExcludingVault` (R2)
- `frontend-react/.../TreasuryDashboard.tsx` — kapcsolódó UI-fix (teljes iroda-név a chipen)

## 4. Rögzített döntések és kényszerek

- A vault-kizárás a **fogyasztó-specifikus** metódusban történik (FK-036 minta:
  `InventoryService.getAllStock` + `activeNonVaultBranch`), NEM a megosztott repository-queryben.
- A JPQL `is_vault` predikátum a bevált `BranchRepository.findRateCreationAssignableCashierBranches`
  (FK02-C) mintáját tükrözi: `AND (branch.isVault IS NULL OR branch.isVault = false)`.
- A write-oldali gyökér-gate (G3) a `initializeBranchBalances` egyetlen chokepointján áll (a
  branch-create / bulk-init / session-lazy-init mind ezen megy át), a tenant-guard UTÁN.
- A session-gate (G1/G2) a metódus elején, MINDEN mellékhatás (cash_balance lazy-init,
  session-mentés, stale-session-zárás) ELŐTT dob; `Boolean.TRUE.equals(...)` null-safe.

## 5. Edge case-ek

- `isVault == null` (defenzív): `IS NULL OR = false` → pénztárként kezelt (nem szűrt ki).
- REOPEN-ág (`openDay`/`openSession` már létező mai CLOSED session): a gate a metódus elején
  van, így a REOPEN is gated.
- Cross-tenant init: a G3 a tenant-guard UTÁN áll → cross-tenant vault init `AccessDenied`
  (biztonság előbb), same-tenant vault init → skip (return 0).
- Legacy/szivárgott adat: ha mégis létezik vault `cash_balance` vagy vault `daily_session`
  (pl. korábbi bug), az R1/R2 read-szűrő kiszűri a widgetből (defense-in-depth).
- Idempotencia: G3 skip → `0` (= „semmi nem jött létre"), a hívók (BranchService, bulk-init) ezt
  natívan kezelik.

## 6. Elfogadási kritériumok (EARS)

- WHEN `getCompanyBalances()` lefut THEN the system SHALL csak `is_vault=false` branch-ek
  egyenlegeit adja vissza (`findByCompanyIdExcludingVault`).
- WHEN `openDay()` vagy `openSession()` hívás történik `is_vault=TRUE` branch-re THEN the system
  SHALL `ValidationException`-t dobjon, és NE hozzon létre `daily_session`-t vagy `cash_balance`-t.
- WHEN `initializeBranchBalances(branchId)` `is_vault=TRUE` branch-re fut THEN the system SHALL
  `0`-t adjon vissza és NE hozzon létre `cash_balance` sort.
- WHEN `getSessionHistory(from,to)` lefut THEN the system SHALL kizárja az `is_vault=TRUE`
  branch-ek `daily_session`-jeit (`findByDateRangeExcludingVault`).

## 7. Tesztterv

- `CashBalanceServiceTest#getCompanyBalances_excludesVault` (R1 wiring).
- `CashBalanceServiceTest#initializeBranchBalances_vaultBranch_skipped` (G3).
- `DailySessionServiceTest#openDay_vaultBranch_rejected` (G1), `#getSessionHistory_excludesVault` (R2).
- `SessionOpenServiceTest#testOpenSession_vaultBranch_rejected` (G2).
- JPQL bootstrap-validáció: bármely `@SpringBootTest` kontextus-betöltés (a két új `…ExcludingVault`).
- Teljes regresszió: `mvnw test` (2200 teszt, 0 hiba).
- Adverzariális verifikáció: 4 refuter (gate-teljesség/biztonság/kód-helyesség) — mind UPHELD.

## 8. Kockázatok / visszavonási terv

- Kockázat: ha létezne legitim vault-pénztári flow, a G1/G2 eltörné. Adverzariális ellenőrzés
  + 2200 zöld teszt szerint nincs ilyen flow (vault zárása `VaultClosingChecklist`/`ClosingControl`).
- Visszavonás: tiszta revert (nincs migráció, nincs adatmódosítás, nincs API-forma-változás);
  a read-szűrők és a gate-ek egymástól függetlenül is visszavonhatók.
