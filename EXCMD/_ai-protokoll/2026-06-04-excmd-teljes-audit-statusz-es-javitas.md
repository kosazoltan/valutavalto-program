# EXCMD teljes audit — státusz-revízió + javítás (2026-06-04)

**Módszer:** a teljes EXCMD mappa (595 fájl) finding-listáit (`_compare/2026-06-02-reverify/00-MASTER-GAPS.md`
A1–A7/B1–B10, `b3-arfolyam-karbantarto-hibalista` FR-HL-01..19, `_ai-protokoll/high-priority-explicit-fr`,
b1–b10 spec-FR-ek) **4 párhuzamos verifikáló-ügynökkel a JELENLEGI kód ellen** újra-ellenőriztük
(branch `feat/aml-senior-approval-frontend-flow`, v2.27.86 körül). Kizárólag kódtény (fájl:sor), hallucináció nélkül.

**Fő megállapítás:** a 2026-06-02-i master-gap riport **nagyrészt ELAVULT** — a kód azóta sokat fejlődött
(#1019–1030 PR-ek + az AML felsővezetői jóváhagyás flow). A korábban "OPEN"-ként jelölt tételek többsége
mára KÉSZ.

---

## 1. Időközben JAVÍTVA (a master-riport óta — NINCS teendő)

| Master-gap | Mai állapot | Bizonyíték |
|------------|-------------|-----------|
| **A1** FATF ország-kockázat a tranzakciós AML-úton | ✅ JAVÍTVA | `AmlService.java:113-119` `checkTransaction(...customerNationality)`, `:178-184` `fatfCountryRiskService.classify(customerNationality)`; minden hívó átadja (`TransactionService:296,514`, helper, conversion, multi-line). Enforcement flag mögött (default OFF, szándékos). |
| **A2** Kezelési-díj RBAC: FOERTEKTAR | ✅ JAVÍTVA | `HandlingFeeConfigController.java:34` már tartalmazza a `FOERTEKTAR`-t. |
| **A3** Pmt. 50M forrás-igazolás kényszerítés | ✅ KÉSZ (flag OFF) | `sourceOfFundsBlockReason()` (`TransactionService.java:973-1015`): ≥50M, típus-fehérlista, szlip ≤3 év, két-tanús TILTÁS; flag `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT` default false. Maradék: okirat-FÁJL feltöltés (üzleti döntés). |
| **A4** Körlevél-blokkolás | ✅ KÉSZ (flag OFF) | `CIRCULAR_ACK_BLOCKING_ENFORCEMENT` (`:112-114`), `performAmlCheck:813-827` + `circularAckBlockReason():946-961`. |
| **A7** 10M+ AML hard-block + supervisor UI | ✅ KÉSZ (flag OFF) | Supervisor-approval flow KÉSZ ezen a branchen: `AmlApprovalController` (verify-approver + check-required), `AmlApproverModal.tsx`, `CashierTransactionPage`/`ConversionPage` bekötés, local-first sqlite+sync. `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT` default false → go-live döntés. |
| **B5** "Csak ügyfeles bizonylatok" szűrő | ✅ JAVÍTVA | `TransactionListPage.tsx:49` `customerOnly` → szerverre küldve, checkbox UI (`data-testid="filter-customer-only"`). |
| **B6** Ráta-módosítás audit (név+dátum) | ✅ JAVÍTVA | `RatePublicationAuditDto` + `RatePublishService.getPublicationAuditHistory` (publishedByName+At, immutable), FE `RatePublishHistory.tsx`. |
| **B8** Csoport-ráták SQLite perzisztencia | ✅ JAVÍTVA | `workgroupSheetStorage.ts` dual-write (localStorage + `lf:save-group-rate-values`), IPC bekötve MINDKÉT hostba (arfolyam + kozponti), `group_rate_values` entitás. |
| **B10** FR-RFM-20 napi 5 saját-hatáskörű R/S limit | ✅ JAVÍTVA | `validateAndNormalizeCashierCustomRateQuota` (`TransactionService:1474-1492`) + `countDailyCashierCustomRatesByWorker`, limit=5, bekötve buy+sell. (A reverify-riport MISSING-állítása téves volt.) |
| **FR-HL-01..19** (árfolyamkészítő hibalista) | ✅ TELJES | Mind a 19 tétel implementált (lap-copy, undo/redo max50, mat-kerekítés, navigáció, deviáció-modal, munkacsoport-auto stb.); a doc-beli FTP/ARFDATA.DAT a modern REST-publish-re tudatosan újraértelmezve. |

---

## 2. EBBEN A KÖRBEN JAVÍTVA

### B7 — Foglaló-bizonylat hiányzó mezők (b4-foglalo FR-8/13/14) ✅
`ReceiptGeneratorService.generateReservationReceipt` kiegészítve a FACTUÁLIS/számított mezőkkel:
- **FR-8 Forint-érték**: rendelt összeg × lekötött árfolyam, egész forintra (a doc "ennek ft. erteke" sora).
- **FR-8 Befizetés napja**: a foglalás `createdAt`-je (átvételi bizonylaton).
- **FR-13 (visszafizetés)**: eredeti foglaló bizonylatszáma + foglaló átvétel napja kereszthivatkozás + átvett összeg.
- **FR-14**: beszámítási záró-szöveg ("A foglaló a mai napon végrehajtott ügylet ellenértékébe beszámításra került.").
+ 2 teszt-assertion (`ReceiptGeneratorServiceTest`). Backend 44 receipt/reservation teszt zöld.

> **FR-10 (jogi tájékoztató blokk) SZÁNDÉKOSAN NEM implementálva**: a spec szerint "változatlan formában kell
> nyomtatni", a verbatim szöveg forrása a `Foglaló bizonylatok.jpg` kép, amelyről NINCS OCR-átirat az EXCMD-ben.
> A pontos jogi szöveget NEM hallucináljuk — ez a verbatim forrás-szöveget igényli (üzleti/jogi input).

---

## 3. Üzleti / compliance döntést igényel (NEM nyúlunk hozzá vakon)

| Tétel | Miért nem autonóm |
|-------|-------------------|
| **A3/A4/A7 enforcement-flagek élesítése** | A kód kész, de a flag-ek bekapcsolása **go-live üzleti döntés** — bekapcsolva hard-blokkolná az élő tranzakciókat (compliance go-live terv: `EXCMD/2026-06-03_AML-go-live-terv.md`). |
| **A5** Szankció pontszám-küszöbök (PARTIAL 0.7 vs doc 0.8 stb.) | Screening-tuning paraméter; vak átírás false-positive/negative arányt billent → **compliance-megerősítés** kell, hogy a doc az autoritás. |
| **FR-10** foglaló jogi blokk | Verbatim jogi szöveg forrása kép; **jogi input** kell (lásd fent). |

---

## 4. Valódi OPEN funkcionális gap-ek (külön, fókuszált PR-ekben — méret szerint)

| # | Tétel | Forrás | Méret | Bizonyíték |
|---|-------|--------|-------|-----------|
| A6 | `profit_log` élesben sosem töltődik (`recordProfit` 0 hívó) | b8 FR-8 | Közepes ⚠️ | `WacService.java:101` def, 0 caller. Bekötés executeBuy/Sell-be — DE kettős-számolás kockázat (`ProfitCalculationService` spread-alapú párhuzamos mechanizmus); careful design kell, nem vak wire-up. |
| B2 | Bizonylat-szűrő részletes KYC + AML-jelölő | b5b FR-01..05 | Közepes | `ReceiptPage.tsx:49` csak biz.szám; backend `ReceiptSearchService` fél-kész (number/date/type/amount/customer), nincs KYC/10M, a page nem köti be. |
| B4 | Pillanatnyi pénztárállás: per-valuta KEZ-I DÍJ oszlop + szín | b5 FR-PA-01/03/04 | Közepes | `LiveCashPositionPage.tsx` egy aggregált `handlingFeeHuf`; nyomtatás-gomb KÉSZ. Per-valuta bontás + színkód hiányzik. |
| B3 | "MÉGSEM" (megszakított tranzakció) bizonylat | b4-bizonylatok FR-15/16 | Közepes | Nincs aborted-bizonylat-típus (csak tranziens toast). |
| FR-EFM-02 | NAV pénztárgép explicit parancsok (napnyitás/zárás/valuta törlés/betöltés) | b6b | Közepes | `NavIntegrationPage.tsx` csak tx-küldés + COM-port; explicit parancsok hiányoznak. |
| FR-EFM-01 | Konszolidált "Egyéb feladatok" menü | b6b | Kicsi | Funkciók szétszórtan; választó-menü hiányzik. |
| FR-KC-05/06 | Dedikált címletezés-zárás választó-menü | b5 | Kicsi | Funkciók elérhetők, a menü-belépő hiányzik. |
| B1 | ERB egyedi kötés (Raiffeisen kártyás szerződéskötő) | b3b-erb | NAGY | Teljesen hiányzik (új modul) — üzleti döntés. |
| B9 | Bank API / Raiffeisen REST + `BANK_API_CONFIG` admin-tábla | b3-bank-api | NAGY | Jelenleg HTML-scraping; REST/OAuth2 + admin-konfig új feature. |

---

## 5. C/D — NEM bug (tudatos architektúra-eltérés / scope-on kívül)
A master-riport C/D kategóriái érvényesek: legacy Delphi-screenshot ≠ React UI, FTP→REST publish, technikai
TransactionType-kódok, Zálog (EXZ) külön termék, hardver/hálózati felmérés. Ezeket a CLAUDE.md no-hallucináció
mandátum szerint NEM írjuk át.

---

## Összegzés
- A 2026-06-02-i master-gap riport **A1, A2, A3, A4, A7, B5, B6, B8, B10 + összes FR-HL** tétele a mai kódban
  **már KÉSZ** (a riport elavult — ez a dokumentum a friss státusz).
- **B7 ebben a körben javítva** (foglaló-bizonylat factuális mezők) + teszt.
- A maradék OPEN: A6 (careful design), B1–B4/B9/FR-EFM/FR-KC (külön fókuszált PR-ek), valamint
  compliance/üzleti-döntéses tételek (A5, flag-élesítés, FR-10 jogi szöveg).
