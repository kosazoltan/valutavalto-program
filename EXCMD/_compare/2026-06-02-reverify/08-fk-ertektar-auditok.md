# 08 — FK értéktári auditok: doc↔kód konformancia-reverifikáció

**Dátum:** 2026-06-02
**Hatókör:** 4 javítási utasítás finding-onkénti ellenőrzése az AKTUÁLIS kód ellen.
**Módszer:** minden pont egyenként; IMPLEMENTED csak file:line bizonyítékkal; nincs találat → MISSING.

Auditált dokumentumok:
1. `FK-007_ertektar_kartyan_valutanemek_kodaudit_javitasi_utasitas.md`
2. `FK02-C_irodak_lista_szures_kodrevizio_es_javitasi_utasitas.md`
3. `ertektar_atadas_szallito_plomba_kodrevizio_javitasi_utasitas.md`
4. `ertektar_felhasznalokezeles_google_oauth_szemelyes_belepes_kodaudit_javitasi_utasitas.md`

---

## 1. FK-007 — Értéktár kártyákon valutanemek (Országos készlet)

| Utasítás-pont / Finding | Státusz | Bizonyíték file:line | Prio | Megjegyzés |
|---|---|---|---|---|
| P1: üres értéktár-kártya kapja meg a központi valutalistát (0-soros) | ✅ JAVÍTVA | `frontend-react/src/pages/inventory/CashierStocksPage.tsx:194-216` | P1 | `currencies.map(...)` → `currentBalance: 0` sorok; keresőszűrő is alkalmazva; `currencies.length===0` esetén FK-003 üres fallback marad (a spec szerint best-effort) |
| P2: regressziós teszt a stock-sor nélküli értéktárra | ✅ JAVÍTVA | `frontend-react/src/pages/inventory/CashierStocksPage.test.tsx:102-` | P2 | „a KÉSZLETSOR NÉLKÜLI értéktár-kártya is a teljes aktív valutalistát mutatja" |
| FK-007: TST (ismeretlen) nem jelenik meg 0-egyenleggel | ✅ JAVÍTVA | `CashierStocksPage.test.tsx:55`; migr. `V272__fk007_deactivate_unknown_tst_currency.sql` | P2 | Teszt + migráció együtt fedi |
| P2: BR105 `vault_territory_id` — NE vak migráció, előbb adatdiagnosztika | ✅ JAVÍTVA (by-design követve) | `V288__bekescsaba_branch_region_fix_and_br105_stock.sql` | P2 | A V288 region-overwrite + BR105 stock-init irányt választott (NEM vak vault_territory_id pótlás), egyezik a spec „region/region_code releváns" következtetésével |

**FK-007 részösszeg:** 4/4 ✅. Nincs nyitott gap.

---

## 2. FK02-C — Irodák listájának szűrése (Árfolyamkészítő)

| Utasítás-pont / Finding | Státusz | Bizonyíték file:line | Prio | Megjegyzés |
|---|---|---|---|---|
| P0: lista endpoint csak PENZTAR-t adjon (ne minden aktív branch) | ✅ JAVÍTVA | `service/RateCreationService.java:684` | P0 | `findRateCreationAssignableCashierBranches(companyId)` váltja a régi `findByCompanyIdAndIsActiveTrue`-t |
| 1. repo pénztár-only query (`bt.code='PENZTAR'`, `isVault!=true`, aktív) | ✅ JAVÍTVA | `repository/BranchRepository.java:181-184` | P0 | INNER JOIN branchType, ORDER BY name — pontosan a spec szerint |
| P0: mentési endpoint (`updateWorkgroupBranches`) elutasítsa a nem-pénztárt | ✅ JAVÍTVA | `RateCreationService.java:741-744` + helper `:778-784` | P0 | `isRateCreationAssignableCashierBranch` validáció a ciklusban; üzenet „csak pénztár típusú iroda rendelhető" |
| P1: ne csak `ExcludingCounterparties`-t használd (az ERTEKTAR-t nem zárja) | ✅ JAVÍTVA | `BranchRepository.java:178-184` (külön, szigorúbb metódus) | P1 | A régi metódus megmaradt, de a rate-creation a szigorút hívja |
| P1: frontend keresés maradjon backend-szűrt listán (ne FE üzleti szűrő) | ✅ JAVÍTVA (változatlan) | `frontend-react/src/pages/rates/RateCreationPage.tsx` (név/kód/város szűrő, nincs `excludeBankPartners`) | P1 | Backend ad pénztár-only listát; FE-szűrő nem helyettesít |
| P2: opcionális `branchTypeCode` a `BranchListDTO`-ban | ⚠️ PARTIAL (by-design elhagyva) | `dto/ratecreation/BranchListDTO.java` (nincs branchTypeCode) | P2 | A spec explicit „nem kötelező / elhagyható" — backend szűrés garantált, így nem gap |
| Teszt: lista csak assignable cashier-t kér | ✅ JAVÍTVA | `test/.../RateCreationServiceTest.java:141` | — | mock `findRateCreationAssignableCashierBranches` |
| Teszt: VAULT_COUNTERPARTY / ERTEKTAR elutasítás | ✅ JAVÍTVA | `RateCreationServiceTest.java:152,171` (`hasMessageContaining("csak pénztár")`) | — | Mindkét típus fedve |

**FK02-C részösszeg:** 7/8 ✅, 1 ⚠️ (by-design opcionális, nem valódi gap). Acceptance-checklist teljesül.

---

## 3. Értéktári átadás — szállító neve + plombaszám

| Finding | Státusz | Bizonyíték file:line | Prio | Megjegyzés |
|---|---|---|---|---|
| F1/P1: backend DTO szerződés (`@NotBlank`/`@Size 128/64`/`@Pattern`) | ✅ JAVÍTVA | `dto/transfer/CreateTransferDto.java:37-48` | P1 | carrierName: NotBlank+Size128 (ékezet OK); sealNumber: NotBlank+Size64+`^[A-Za-z0-9\-/]+$` — pontosan a spec |
| F2/P2: DB+entity 128/64 szerződés (volt 200/100) + védett migráció | ✅ JAVÍTVA | `entity/Transfer.java:100-104`; `migration/V283__transfer_carrier_seal_contract.sql` | P2 | V283 védett szűkítés (RAISE EXCEPTION ha hosszabb) + seal CHECK; nem írta át a V208-at |
| F3/P1: értéktári `ShipmentNewPage` flow megkapja a két mezőt | ✅ JAVÍTVA | `pages/shipments/ShipmentNewPage.tsx:18,57,207,219,389-409`; backend `V284__shipment_request_carrier_seal.sql` | P1 | UI mezők + validateCarrierSeal + payload; shipment_request backend is bővült (nem keverte a transfer aggregate-tel) |
| F4/P1: sikeres mentés után `Nyomtatás` gomb a transfer flow-ban | ✅ JAVÍTVA | `pages/transfers/TransferPage.tsx:145,393,708-717,1097-1116` | P1 | `printReceiptData` state + Nyomtatás gomb + `ReceiptPreviewModal` + `electronAPI.printReceipt` |
| F5/P1: print adatmodell `carrierName` + sablon kiírja szállító+plomba | ✅ JAVÍTVA | `types/receipt.ts:45,59`; `electron/printer.ts:105,119,350-354,726-727`; `components/electron/ReceiptPreviewModal.tsx:283-287` | P1 | Mindkét PrintReceiptData type + text+HTML sablon + preview modal kiírja |
| F6/P2: offline SQLite kész + közös validátor | ✅ JAVÍTVA | `validateCarrierSeal` használat (`ShipmentNewPage.tsx:207`, `TransferPage.tsx:276`); `electron/sqlite.ts` (carrier_name/seal_number) | P2 | Közös FE validátor mindkét oldalon; SQLite oszlopok megvannak |
| F7/P2: tesztlefedettség (backend validáció + FE + Electron print) | ✅ JAVÍTVA | `test/.../dto/CreateTransferDtoValidationTest.java`; `transactions.test.ts`; `transferRules.test.ts`; `ShipmentNewPage.test.tsx`; `electron/__tests__/printer.test.ts` | P2 | Dedikált DTO-validációs teszt + FE + printer teszt léteznek |

**Átadás/szállító részösszeg:** 7/7 ✅. Nincs nyitott gap.

---

## 4. Értéktári felhasználókezelés — Google OAuth + személyes belépés

| Finding | Státusz | Bizonyíték file:line | Prio | Megjegyzés |
|---|---|---|---|---|
| P0: Google után kétlépcsős személyes dolgozóválasztás | ✅ JAVÍTVA | `service/GoogleLoginService.java:178-223` (selection) + `:231-299` (selectVaultWorker); `controller/GoogleAuthController.java:109-139` | P0 | shared_account → dolgozólista (NINCS végleges session); 2. fázis jelszóval végleges JWT a SZEMÉLYES workerrel |
| P0: `/inventory/vault-stock` engedje az ERTEKTAR role-t + scope | ✅ JAVÍTVA | `controller/InventoryController.java:108-111` | P0 | `@PreAuthorize(... 'ERTEKTAR')` hozzáadva; `getVaultStockFlow()` territory-scope szűr (komment 103-106) |
| P1: NE új `vault_user` tábla — meglévő Worker modell | ✅ JAVÍTVA (követve) | `service/VaultWorkerService.java` (Worker entity, passwordHash, branch, ertektar role) | P1 | Worker-alapú, nincs párhuzamos identitásmodell |
| P1: szűkített értéktári dolgozó-felvétel végpont (nem teljes admin CRUD) | ✅ JAVÍTVA | `controller/VaultWorkerController.java:27-47`; `service/VaultWorkerService.java:54-113` | P1 | `POST/GET /api/v1/vault-workers`; company+branch SecurityContextből; csak ertektar role; nincs szabad companyId; googleLoginEnabled=false |
| P1: offline személyes auth NE implementálódjon automatikusan | ✅ JAVÍTVA (követve) | (nincs password_hash a `cached_workers`-ben) | P1 | Online azonosítás; offline hash-cache nem készült (spec szerint külön security-terv kell) |
| P2: elfelejtett jelszó → admin-tájékoztató (nem önkiszolgáló reset a vault flow-n) | ✅ JAVÍTVA | `pages/auth/LoginPage.tsx:554-566` | P2 | hu-HU info: „visszaállítást az adminisztrátor végzi" a dolgozóválasztó képernyőn |
| Cél-arch.: dolgozólista company+branch scope szűréssel | ✅ JAVÍTVA | `GoogleLoginService.java:202-223`; `WorkerRepository.findSelectableVaultWorkers` | — | branch+company + ertektar role filter |
| Cél-arch.: végleges JWT csak jelszóellenőrzés után | ✅ JAVÍTVA | `GoogleLoginService.java:287-299` | — | `passwordEncoder.matches` + lockout + id-enumeráció-védelem (generikus üzenet) |
| Cél-arch.: lockout NE új in-memory map | ✅ JAVÍTVA | `GoogleLoginService.java:286-292` (`workerService.assertVaultLoginNotLocked / recordVaultFailedAttempt / clearVaultLoginAttempts`) | — | Közös WorkerService számláló, nincs duplikált map |
| FE: Google siker → dolgozólista → jelszó → belépés | ✅ JAVÍTVA | `pages/auth/LoginPage.tsx:214-223,488-566` | — | Teljes 2-fázis UI; egy találatnál auto-kiválasztás |
| FE: header/sidebar a SZEMÉLYES nevet mutatja | ✅ JAVÍTVA | `buildSessionResponse(personal,...)` (`GoogleLoginService.java:299`) → `user.fullName` a személyes worker | — | A session a személyes workerhez tartozik |
| Migráció: shared_account flag | ✅ JAVÍTVA | `migration/V285__worker_shared_account_flag.sql`; `entity/Worker.java` (sharedAccount) | — | — |

**Google OAuth részösszeg:** 12/12 ✅. Nincs nyitott gap. (#992 vault-stock RBAC + #993 feature + #994 bump.)

---

## Záró statisztika

| Dokumentum | ✅ JAVÍTVA | ⚠️ PARTIAL | ❌ NEM | 🔴 HIBÁS | Összes pont |
|---|---|---|---|---|---|
| FK-007 | 4 | 0 | 0 | 0 | 4 |
| FK02-C | 7 | 1 | 0 | 0 | 8 |
| Átadás/szállító/plomba | 7 | 0 | 0 | 0 | 7 |
| Google OAuth / felhasználókezelés | 12 | 0 | 0 | 0 | 12 |
| **ÖSSZESEN** | **30** | **1** | **0** | **0** | **31** |

**Eredmény:** 30/31 pont kódból igazoltan JAVÍTVA. Az egyetlen ⚠️ (FK02-C P2 `branchTypeCode` DTO-mező) a spec által explicit opcionálisnak/elhagyhatónak jelölt diagnosztikai kényelmi elem — a backend pénztár-only szűrés garantált, így nem funkcionális gap. Egyetlen MISSING vagy HIBÁS finding sem maradt.
