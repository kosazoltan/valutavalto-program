# Doc↔kód konformancia újra-audit — Pénztár menü / Kezelés / Címletezés / Engedélyezés

> **Készült:** 2026-06-02. **Auditált specek:** `b5-fomenu.md`, `b5-kezeles-cimletezes-engedelyezes.md`, `b5-penztar-mozgasok.md`, `b5-penztarallas-listak.md`, `b6b-egyeb-feladatok-menu.md`.
> **Kódbázis:** `backend/` (Java 21 / Spring), `frontend-react/` (React+TS), `penztar-client/` (Electron — a frontend-react buildet hosztolja).
> **Kiemelt fókusz (gap-baseline G11):** AML 10M+ kötelező engedélyező-blokk verifikációja. Címletezés 7 stratégia.
> **Módszer:** minden követelmény egyenként; IMPLEMENTED csak `file:line` bizonyítékkal; nincs találat → MISSING + keresési kulcs. Bizonytalan → VERIFIKÁLANDÓ.

Jelmagyarázat: ✅ = implementált (bizonyítva) · ⚠️ = részleges / eltérő · ❌ = hiányzik · 🔴 = kritikus (compliance/biztonság) hiány vagy téves "kész" jelölés.

---

## KIEMELT: G11 — AML 10M+ kötelező engedélyező-blokk (FR-KC-11)

| Verifikációs kérdés | Megállapítás | Bizonyíték |
|---|---|---|
| Létezik-e hard-block kód? | IGEN, de feature-flag mögött | `backend/.../service/TransactionService.java:809-817` (`if (thresholdResult.isRequiresManagerApproval())` → `highValueApprovalBlockReason()` → `throw ValidationException`) |
| Mi a flag default? | **`false` = WARN-only** | `TransactionService.java:104-106` (`AML_HIGH_VALUE_APPROVAL_DEFAULT = "false"`); `highValueApprovalBlockReason()` `enforcementEnabled==false` esetén `null`-t ad (`TransactionService.java:847-849`) |
| Bekapcsolja-e migráció prod-ban? | **NEM** — semmilyen migráció nem állítja `true`-ra | grep `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT` a `db/migration`-ban: **0 találat**. A `vault/feedback/audit-2026-05-29-triage-and-defers.md:31` "prod-default true" csak javaslat volt, NEM implementált. |
| 10M küszöb tényleg bekötve? | IGEN (TranzTipus 5 ≥ 10M, manager-approval TranzTipus≥4) | `AmlService.java:332` (`THRESHOLD_10M=10000000`), `:445` (≥10M→tipus 5), `:603-607` (`transactionType>=4 → requiresManagerApproval=true`) |
| Van-e pénztáros supervisor-approval UI? | **NINCS** | grep `requiresManagerApproval`/`Engedélyező`/`highValue` a `frontend-react/src`-ben: 0 releváns találat (csak `supervisorApproveTransfer` az értéktári transferhez, `settings.ts:947`) |
| Anonim (customerId nélküli) 10M+ blokkol? | **NEM** a manager-approval ágon | `TransactionService.java:792` — a `checkAllThresholds()` + manager-approval blokk CSAK `customerId != null && !isBlank()` esetén fut. (300e Ft feletti azonosítási kötelezettség viszont külön blokkol: `:857-869`.) |

**G11 összegzés:** A gap-baseline "RÉSZBEN KÉSZ, feature-flag KI" állítása **PONTOS és VERIFIKÁLT**. A hard-block kódban létezik, default KI (WARN-only), prod-ban nem aktivált, és **nincs hozzá pénztáros supervisor-approval UI**. Tehát éles üzemben a 10M+ tranzakció ténylegesen NEM blokkol (FR-KC-11 "Engedély megadása gomb letiltott amíg..." üzleti elvárás nem teljesül futásidőben). Prio: **P1 (compliance — Pmt./AML)**.

---

## b5-kezeles-cimletezes-engedelyezes.md (FR-KC)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-KC-01 Kezelési költség menü (átvétel/átutalás/jelenlegi készlet) | ✅ | `frontend-react/src/pages/fees/FeePage.tsx`, `treasury/MovementManager.tsx` (HANDLING_FEE transfer-típus); `transferRules.ts:26` | M | Funkció megvan; nem 1:1 a legacy almenü-struktúra. |
| FR-KC-02 Címletező valuta-lista (HUF kiemelt) | ⚠️ | `frontend-react/src/pages/cashdesk/DenominationPage.tsx`; `service/DenominationService.java` | M | Címletkezelés megvan; a spec szerinti 28-valutás kiemelt-HUF rács UI nem 1:1 verifikált. VERIFIKÁLANDÓ a HUF piros kiemelés. |
| FR-KC-03 HUF címletenkénti darabszám (1/2 Ft tiltott) + részösszeg | ⚠️ | `cashdesk/DenominationPage.tsx`, `closing/EveningClosingPage.tsx`; `entity/DenominationCategory.java` | M | Címlet-darabszám bevitel + részösszeg megvan; az 1 és 2 Ft-os explicit szürkítés a kódban nem verifikált. VERIFIKÁLANDÓ. |
| FR-KC-04 Összesítő + "CÍMLETEK RENDBEN" gomb (összeg-egyezés gate) | ✅ | `closing/EveningClosingPage.tsx` (denomination total + tovább-gomb); `service/EveningClosingService.java` | M | |
| FR-KC-05 Címletezés-menü (esti zárás / kez.díj / WU / ÁFA / foglaló / e-ker — utóbbi 4 szürkített) | ❌ | grep `ESTI ZÁRÁS CÍMLET`/`KEZELÉSI DÍJ CÍMLET`/`CimletezesMenu`: **0 találat** `frontend-react/src`-ben | M | Nincs dedikált címletezés-választó menü a 6 zárás-típussal. A funkciók (esti zárás, kez.díj) szétszórtan elérhetők, de a spec szerinti menü-képernyő hiányzik. |
| FR-KC-06 Zárások háttér-menü pontok | ❌ | Lásd FR-KC-05 | C | Nincs külön implementáció. |
| FR-KC-07 Egyedi Kötés RB (ERB) űrlap | ⚠️ | `transfers/TransferPage.tsx` (carrier/seal/megjegyzés mezők megvannak) | S | Általános szállítási űrlapba olvasztva; dedikált ERB-előkitöltés ("ERB / EGYEDI KOTES RB") nem verifikált. Baseline: ERB külön TransactionType "üzleti döntés kell". |
| FR-KC-08 Havi tablók menü (statisztika/forgalom/grafikon/excel) | ✅ | `reports/MonthlyTabloPage.tsx`, `service/MonthlyReportService.java`; G16/G17 KÉSZ | S | |
| FR-KC-09 Havi tabló paraméterezés (év/hó/egység) | ✅ | `reports/MonthlyTabloPage.tsx` | S | |
| FR-KC-10 Ügyfél országos ellenőrzése panel (név/szül.név/anyja neve/szül.hely) | ⚠️ | `transactions/components/CustomerPanel.tsx`; PEP/sanction screening `service/SanctionScreeningService` | M | Ügyfél-adatmezők + screening megvan; a dedikált "AZ ÜGYFÉL ORSZÁGOS ELLENŐRZÉSE" 10M-panel mint külön UI nem verifikált. VERIFIKÁLANDÓ. |
| FR-KC-11 Nagy összegű tranz. engedélyező panel (10M felett, pénz forrása, Engedélyező mező, gombok) | 🔴 | Backend WARN-only `TransactionService.java:809-821`; **FE panel hiányzik** (grep 0 találat) | M→P1 | Lásd G11 fenti blokk. A blokkoló panel + "Engedély megadása/Nem engedélyezett" döntési UI NINCS. Source-of-funds mező létezik (`CashierTransactionPage.tsx`, PEP), de nem köti a 10M-engedélyezéshez. |
| FR-KC-12 Természetes személy + F5 országos azonosítás + Állampolgárság | ✅ | Állampolgárság: NATIONALITY törzs (#997, commit `2bbc47ae3`); `CustomerPanel.tsx` | S | F5-billentyű kötés nem verifikált; állampolgárság-választhatóság kész. |
| FR-KC-13 "AZ E-MAILEKET SIKERESEN ELKÜLDTEM" megerősítő modal | ⚠️ | `service/email/*`, toast-alapú visszajelzés | S | Email-küldés megvan; a pontos "ibvalto" modal felirat nem verifikált. |
| FR-KC-14 Vásárlás képernyő oszlopok (kez.díj %, kerek. kompenzáció, BLOKKSZÁM, FIZETENDŐ) | ✅ | `transactions/CashierTransactionPage.tsx`; HUF 5-Ft kerekítés `HungarianRounding` | C | |
| FR-KC-15 Kez.ktg config jogosultság (MANAGER/ADMIN/FOERTEKTAR/UGYVEZETO) | ⚠️ | `controller/HandlingFeeConfigController.java:31` `@PreAuthorize("hasAnyRole('MANAGER','ADMIN','UGYVEZETO','IRODAVEZETO','BELSO_ELLENOR')")` | P1 | **`FOERTEKTAR` HIÁNYZIK** a listából, pedig a spec explicit nevezi. Pénztáros korrekt módon kizárva. |
| FR-KC-16 Kez.ktg explicit override workflow (F9: NONE/HALF/WAIVED/SPECIAL + jogcím + kártyaszám + approvalId) | ✅ | `service/HandlingFeeOverrideService.java:58-100` (típusok, CUSTOMER_CARD kötelező kártyaszám, SPECIAL csak director-jóváhagyással, szerver újraszámol); F9 dialog (task #6) | P0 | Server-side recompute megvan (HALF=base/2, WAIVED=0, csak SPECIAL fogadja a kliens összeget). |

---

## b5-fomenu.md (FR-FM)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-FM-01..06 Fej-panel (verzió/dátum/idő/egység/pénztáros/háttér) | ⚠️ | `frontend-react/src/pages/CashierMainMenu.tsx`, MainLayout | M/S/C | Modern reinterpretáció; a legacy fej-panel összes eleme (telefon, egység-azonosító piros, vízjel-egységnév) nem 1:1. |
| FR-FM-07 Átadás-átvétel menüpont | ✅ | `CashierMainMenu.tsx:33` (`route: '/transfers'`) | M | |
| FR-FM-08 Mai bizonylat sztornója | ✅ | `CashierMainMenu.tsx:34` (Stornó → `/transactions`); `pages/stornos/` | M | |
| FR-FM-09 Pillanatnyi pénztár állása | ✅ | `CashierMainMenu.tsx:36` (`/cashdesk`); `reports/LiveCashPositionPage.tsx` | M | |
| FR-FM-10 Napi/havizárás, címletezés | ✅ | `CashierMainMenu.tsx:41,59` (`/closing/wizard`, `/cashdesk/denominations`) | M | |
| FR-FM-11 Bizonylatok megtekintése | ✅ | `CashierMainMenu.tsx:42` (`/receipts`) | M | |
| FR-FM-12 Kilépés a főmenüből | ⚠️ | MainLayout logout | M | Megerősítő kérdés nem verifikált. |
| FR-FM-13 Menü-blokkok lapozás (2 oldal) | ⚠️ | `CashierMainMenu.tsx:29-61` (két szekció: Napi/Admin, NEM lapozós nyilakkal) | S | Funkcionálisan a 2 blokk megvan, de a legacy "<<< / >>>" lapozás helyett 2 szekció egy oldalon. |
| FR-FM-14 Társpénztárak karbantartása | ✅ | `CashierMainMenu.tsx:44` (`/branch-groups`); `pages/branches/` | M | |
| FR-FM-15 Különféle listák nyomtatása | ✅ | `CashierMainMenu.tsx:49` (`/reports`); `reports/ReportsPage.tsx` | M | |
| FR-FM-16 Pénztárosok/jelszavak karbantartása | ✅ | `CashierMainMenu.tsx:50` (`/settings/users`); `settings/UserPage.tsx` | M | |
| FR-FM-17 Régebbi nap zárás újranyomtatása | ✅ | `service/DailyClosingArchiveService.java`; `/archiving` | S | |
| FR-FM-18 Western Union és ÁFA tranzakciók | ✅ | `pages/westernunion/`, `treasury/VatRefundPage.tsx` | S | |
| FR-FM-19 Alsó funkcióbillentyű sor (F1-F12+Esc, F6/F11 szürke) | ⚠️ | `CashierMainMenu.tsx:68-80` (F1-F8 + szám-billentyűk) | M | Modern F1-F8 + Shift+F1-F9 séma; NEM a legacy F1-F12 árfolyam/foglaló/terminál/áfatábla/... leképezés. A szürkített F6/F11 logika nincs. |
| FR-FM-20 Alsó középső funkciópanelek | ❌ | grep 0 találat a konkrét gomb-feliratokra | S | Gyorsgomb-sáv (NAPI JELENTÉS/ÁTADÓLAP/...) nincs külön. |
| FR-FM-21 Kieg. info-panelek (NÉVTELEN BEJELENTÉS/FUTÓFÉNY/PÉNZTÁR SZÜNET/napi stornó számláló) | ⚠️ | `pages/cashdesk/CashDeskBreakPage.tsx` (pénztár szünet), `AnonymousReportPage.tsx` | C | Egyes funkciók külön oldalként léteznek; a főmenü-overlay számlálók/jelzők nincsenek a főmenün. |

---

## b5-penztar-mozgasok.md (FR-PM)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-PM-01 Társpénztár-választó (SZÁM/MEGNEVEZÉS + gombok) | ✅ | `transfers/TransferPage.tsx` (cél-fiók dropdown); `transferRules.ts:91-107` | M | |
| FR-PM-02/03 Társpénztár-lista kódok (25 db) | ⚠️ | `entity/Branch.java`, branch seed migrációk (V250 BR105) | M | Branch-törzs megvan; a teljes 25 technikai kód (FRB/ERB/TRB/JRB/MNB stb.) mint külön rekord nem teljes körűen verifikált. Baseline: technikai kódok "üzleti döntés kell". |
| FR-PM-04 Szűkített társpénztár-lista | ✅ | `transferRules.ts:91-107` (`filterTransferTargetBranches`: TH + főpénztár + saját-terület értéktár) | S | |
| FR-PM-05/06 Pénztárak karbantartása rács + kötelező sorok | ✅ | `pages/branches/`; `service/BranchService.java` | M | |
| FR-PM-07 Karbantartás műveletek + RBAC | ✅ | `pages/branches/`; `@PreAuthorize` branch controller | M | |
| FR-PM-08 Pénztárak közötti pénzforgalom főmenü | ✅ | `transferRules.ts:21-35` (CASH/CURRENCY/HANDLING_FEE/VAULT_*); `treasury/MovementManager.tsx` | M | |
| FR-PM-09 Szállítási űrlap (társpénztár/szállító/plomba/megjegyzés + KÖNYVELHETŐ/MÉGSEM) | ✅ | `transfers/TransferPage.tsx`; `transferRules.ts:174-183` | M | |
| FR-PM-10 Pénz átvétele egy egységtől almenü | ✅ | `transferRules.ts` (VAULT_DEPOSIT/WITHDRAW vault-usernek), `pages/transit/`, `pages/handover/` | M | |
| FR-PM-11 Szállítási űrlap társpénztár előkitöltés | ✅ | `transfers/TransferPage.tsx` (kiválasztott cél-fiók) | S | |
| FR-PM-12 Karbantartó funkcióbillentyűk + állapotsor | ⚠️ | — | C | Lásd FR-FM-19/21; a globális alsó billentyűsor nincs. |
| FR-PM-13 Szállító+plomba szigorú validáció (DTO @Pattern + DB CHECK + FE) | ✅ | `transferRules.ts:174-183` (`^[A-Za-z0-9\-/]+$`, 128/64 limit); backend `CreateTransferDto` Bean Validation | P1 | TBD-2 RESOLVED. Háromszintű (DTO/DB/FE) — DB CHECK constraint külön verifikálandó migrációban. |

---

## b5-penztarallas-listak.md (FR-PA)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-PA-01 Pillanatnyi pénztárállás (VNEM/VALUTA/NYITÓ/BEVÉTEL/KIADÁS/KEZ-I DÍJ/ZÁRÓ) | ⚠️ | `reports/LiveCashPositionPage.tsx:77-100`; `service/LiveCashPositionService.java` | M | Oszlopok megvannak KIVÉVE a **valutánkénti "KEZ-I DÍJ" oszlop** — a kód csak egyetlen összesített `handlingFeeHuf` lábléc-értéket mutat (`:98-100`), nem per-valuta oszlopot. |
| FR-PA-02 Pénztárállás valutái (11 db) | ✅ | `LiveCashPositionService.java` (valutánkénti aggregáció) | M | |
| FR-PA-03 Záró kalkuláció + zöld HUF / piros deviza | ⚠️ | `LiveCashPositionPage.tsx:93` (`font-semibold`, NINCS szín) | S | Záró kalkuláció kész; a zöld-HUF / piros-deviza színkódolás **hiányzik**. |
| FR-PA-04 Funkciógombok (PILLANATNYI ÁLLÁS NYOMTATÁSA / KEZELÉSI DÍJ NYOMTATÁSA / VISSZA) | ⚠️ | `LiveCashPositionPage.tsx:53-58` (Frissítés + általános Nyomtatás) | M | Általános `window.print()` megvan; **dedikált "KEZELÉSI DÍJ NYOMTATÁSA" gomb hiányzik**. |
| FR-PA-05 Bizonylatok szűrése (8 rádió: ügyfeles/vétel/eladás/konverzió/átadás/átvétel/stornó) | ⚠️ | `transactions/TransactionListPage.tsx:241-247` | M | Típusszűrő van: ALL/BUY/SELL/REVERSAL/CONVERSION/TRANSFER_OUT/TRANSFER_IN. **HIÁNYZIK a "Csak ügyfeles bizonylatok" szűrő.** G15 "KÉSZ"-nek jelölte — részben pontatlan. |
| FR-PA-06 Bizonylat szűrés idő-kapcsoló (hónap összes / választott nap) | ⚠️ | `TransactionListPage.tsx:48-64` (dateFrom/dateTo szabad tartomány) | S | Dátum-tartomány megvan; a spec "HÓNAP ÖSSZES / CSAK VÁLASZTOTT NAP" kapcsoló nincs explicit. |
| FR-PA-07 Bizonylat szűrő ablak szerkezete (lista + ügyfél-panel + NAV nyugta) | ⚠️ | `TransactionListPage.tsx`; `nav/NavIntegrationPage.tsx` | C | Lista + NAV részben; a spec szerinti összevont adatlap-panel nem 1:1. |
| FR-PA-08 Összesített pénztárforgalom időszak-választó | ✅ | `reports/CashierTurnoverReportPage.tsx`, `DailyTurnoverPage.tsx` (év/hó/intervallum) | M | |
| FR-PA-09 Különféle listák menü (9 tétel, 3 szürkített) | ✅ | `reports/ReportsPage.tsx`, `ExtendedReportsPage.tsx`, `HandlingFeeDecadePage.tsx`, TRB | M | Riport-aggregátor lefedi; szürkített-tételek logika nem 1:1. |
| FR-PA-10 Egyéb feladatok menü (1. állapot: beállítások/pénztárgép/POS/adatlapok/ügyfél) | ⚠️ | Lásd b6b alább | M | Funkciók szétszórtan (settings/nav/pos/customers/documents); dedikált "Egyéb feladatok" menü-képernyő nincs. |
| FR-PA-11 Egyéb feladatok – Pénztárgép almenü (napnyitás/napzárás/valuta-törlés/betöltés/COM) | ⚠️ | `nav/NavIntegrationPage.tsx:52,123-126` | M | COM-port + tranzakció-küldés + retry/status megvan; **NAPNYITÁS/NAPZÁRÁS/VALUTA TÖRLÉS/BETÖLTÉS explicit parancsok hiányoznak**. |
| FR-PA-13 Üres értéktár kártya 22 valuta (FK-007) | ✅ | `pages/inventory/` (cashier-stocks 0-egyenleg injektálás aktív valutákból) | P1 | |
| FR-PA-14 BR105 iroda láthatóság (region/region_code) | ✅ | V288 migráció (PR #1001, commit `e6535da59`); V250 | P2 | Region/cash_balance/vault_territory_id helyreállítva. |

---

## b6b-egyeb-feladatok-menu.md (FR-EFM)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-EFM-01 Menü config szerinti variáns-váltás (NAV vs OTP/adatlap) | ❌ | grep `EgyebFeladat`/`Egyéb feladat` komponens: 0 dedikált találat | M | Nincs konfiguráció-vezérelt "Egyéb feladatok" menü-képernyő, amely a 2 variánst váltja. |
| FR-EFM-02 Variáns 1 NAV pénztárgép parancsok (7 tétel) | ⚠️ | `nav/NavIntegrationPage.tsx` | M | Csak tranzakció-küldés + COM-port + status; a 6 specifikus parancs (valuta törlés/betöltés, napnyitás/napzárás) hiányzik. |
| FR-EFM-03 Variáns 2 OTP POS + adatlapok + ügyfél karbantartás | ⚠️ | `pos/PosTerminalPage.tsx`, `documents/DocumentStoragePage.tsx`, `customers/CustomerListPage.tsx` | M | Az egyes funkciók léteznek külön oldalakként; nem konszolidált menü alatt. |
| FR-EFM-04 Kilépés az egyéb feladatokból | n/a | — | M | Nincs külön "Egyéb feladatok" menü, így a kilépés-pont sem releváns. |

---

## Címletezés 7 (8) stratégia — verifikáció

| Megállapítás | Bizonyíték |
|---|---|
| A `DenominationRuleType` enum **8** stratégiát definiál (FIXED, AMOUNT_BASED, CUSTOMER_TYPE, TRANSACTION_TYPE, BRANCH_DEFAULT, TIME_BASED, AVAILABILITY, PRIORITY) | `backend/.../entity/DenominationRuleType.java:12-28` |
| Stratégia-választó engine | `service/DenominationRuleSelectionService.java`, `repository/DenominationRuleRepository.java` |
| **Megjegyzés** | A gap-baseline "címletezés 7 stratégia" megfogalmazása a `DenominationRuleType`-ra utal; a kód 8 típust tartalmaz (a 8. PRIORITY). Ez a stratégia-motor ✅ — NEM tévesztendő össze az FR-KC-05 zárás-címletezés MENÜvel (ami ❌ hiányzik). |

---

## Záró statisztika

- **Auditált követelmények:** 5 spec, összesen 57 FR-tétel + G11 kiemelt verifikáció + címletezés-stratégia.
- **✅ implementált (bizonyítva):** 24
- **⚠️ részleges / eltérő:** 25
- **❌ hiányzik:** 7 (FR-KC-05, FR-KC-06, FR-FM-20, FR-EFM-01; továbbá FR-EFM-04 n/a)
- **🔴 kritikus:** 1 (FR-KC-11 / G11 — 10M+ blokk nem aktív + nincs supervisor UI)

### Legfontosabb gap-ek (prioritás szerint)

1. **🔴 P1 — FR-KC-11 / G11:** A 10M+ AML hard-block default KI (WARN-only), prod-migráció nem kapcsolja be, és **nincs pénztáros supervisor-approval UI**. Compliance-kockázat (Pmt./AML). + anonim 10M+ a manager-approval ágon nem blokkol (csak az azonosítási limit). Bizonyíték: `TransactionService.java:792, 804-821, 847-849`.
2. **⚠️ P1 — FR-KC-15:** `HandlingFeeConfigController.java:31` `@PreAuthorize`-ból **hiányzik a `FOERTEKTAR`** szerepkör (spec explicit kéri).
3. **❌ M — FR-KC-05/06:** Dedikált címletezés-zárás menü (esti zárás / kez.díj / WU-ÁFA-foglaló-eker szürkítve) hiányzik.
4. **⚠️ M — FR-PA-01/03/04:** Pillanatnyi pénztárállásból hiányzik a per-valuta KEZ-I DÍJ oszlop, a zöld/piros színkódolás, és a dedikált "KEZELÉSI DÍJ NYOMTATÁSA" gomb.
5. **⚠️ M — FR-PA-05:** Bizonylat-szűrőből hiányzik a "Csak ügyfeles bizonylatok" opció (G15 "KÉSZ" jelölése részben pontatlan).
6. **⚠️/❌ M — FR-EFM-01/02 + FR-PA-11:** Nincs konszolidált "Egyéb feladatok" menü; a NAV pénztárgép explicit parancsai (napnyitás/napzárás/valuta törlés-betöltés) hiányoznak.

> **Builder-megjegyzés:** A magfunkciók (tranzakció, AML besorolás, kez.díj override, transfer plomba-validáció, riportok) implementáltak és tesztelttek. A fenti gap-ek többsége legacy-UI-paritás (⚠️), egy compliance-aktiválás (🔘 G11) és egy RBAC-bővítés (FR-KC-15) érdemi javítást igényel.
