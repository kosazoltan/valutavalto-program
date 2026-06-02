# Mester gap-riport — EXCMD spec ↔ AKTUÁLIS kód újra-audit (2026-06-02)

> Forrás: 9 párhuzamos fókuszált audit-ágens, kód-bizonyítékkal (`01`–`09` riportok ugyanitt).
> A kód v2.27.84+ (backend 4.0.6). A 2026-05-22-i `00-KONSZOLIDALT-GAPS.md` (23/23 KÉSZ) baseline
> ÓTA a kód jelentősen fejlődött; ez az audit az AKTUÁLIS állapotot verifikálta, kiterjesztve az
> újabb FK/audit/b-extension fájlokra is. Minden tétel file:line bizonyítékkal (lásd al-riportok).
>
> **Módszertani elv (CLAUDE.md):** a doc↔kód eltérés NEM mindig bug. Sok legacy Delphi-screenshot
> követelmény a modern React/REST architektúrában tudatosan újraértelmezett. Az alábbi A/B = VALÓDI
> javítandó; a C = tudatos architektúra-eltérés (NEM bug); a D = scope-on kívül / üzleti döntés.

---

## A. VALÓDI compliance / jogi gap (P0–P1) — javítandó

| # | Gap | Forrás | Bizonyíték | Prio | Megjegyzés |
|---|-----|--------|-----------|------|------------|
| A1 | **FATF ország-kockázat nem aktív a tranzakciós AML-úton** | b9-compliance FR-04 | `AmlService.java:101` `screenCustomer(name,doc,null,null,null,null)` — állampolgárság/ország mindig null → `FatfCountryRiskService.classify` NONE-t kap | **P0** | Az adat (ügyfél állampolgárság) létezik, csak nincs beplumbolva. Tiszta wire-up javítás. |
| A2 | **Kezelési-díj config RBAC: hiányzik a FOERTEKTAR role** | b5/b6 FR-KC-15 | `HandlingFeeConfigController.java:31` `@PreAuthorize` MANAGER/ADMIN/UGYVEZETO/IRODAVEZETO/BELSO_ELLENOR — `FOERTEKTAR` kimaradt | **P1** | A spec explicit kéri. Egysoros, biztonságos javítás. |
| A3 | **Pmt. 50M Ft forrás-igazolás kényszerítés hiányzik** | b4-foglalo FR-16, b4-bizonylatok FR-8, b9 FR-05 | `AmlService.java:439-441` csak WARNING; nincs magánokirat-kötelezettség / két-tanús tiltás / banki szlip ≤3 év dátum-check / okirat-feltöltés | **P0(jogi)** | NAGY feature + jogi pontosság kell. Üzleti megerősítés a kényszerítés módjára (hard-block vs. kötelező mező). |
| A4 | **Körlevél-blokkolás (403 olvasatlan körlevélre) nincs** | b9-korlevelek FR-02 | `TransactionService`-ben 0 unacknowledged-ellenőrzés; lista+ack UI van (`CircularPage.tsx:114`), de nem blokkol; SQLite-mirror hiányos (`sync-engine.ts:1471` csak `cached_circulars`) | **P1** | Viselkedés-változás → feature-flag + üzleti megerősítés ajánlott. |
| A5 | **Szankció pontszám-küszöbök eltérnek a spectől** | b8-terrorlista | `SanctionScreeningService.java:42-45` PARTIAL=0.7 (doc 0.8), ALIAS=0.5 (doc 0.9), stale=7nap (doc 30) | **P1** | ⚠️ Screening-tuning paraméter — vakon NEM állítjuk át; compliance-megerősítés kell, hogy a doc az autoritás. |
| A6 | **profit_log élesben sosem töltődik** | b8 FR-8 | `WacService.recordProfit` (`:101`) implementálva, de **0 hívó**; `ProfitCalculationService` spread-alapú | **P1** | Riport/haszon-követés helyesség. Bekötés executeBuy/Sell-be — vigyázni a kettős-számolásra. |
| A7 | **G11 — 10M+ AML hard-block flag default KI + nincs supervisor UI** | b5-kezeles FR-KC-11 | `TransactionService.java:809-817` blokk létezik, de flag default `false`=WARN (`:104-106`), prod migráció nem kapcsolja, nincs pénztáros supervisor-approval UI; anonim 10M+ nem blokkol (`:792`) | **P1** | Tudatosan flag mögött (production-biztos). Élesítés = üzleti döntés + supervisor-approval UI. |

## B. VALÓDI funkcionális gap (P1–P2) — javítandó

| # | Gap | Forrás | Bizonyíték | Prio |
|---|-----|--------|-----------|------|
| B1 | **ERB egyedi kötés** (Raiffeisen bankkártyás szerződéskötő) teljesen hiányzik | b3b-erb-egyedi-kotas FR-1..4 | sem backend controller/entity, sem frontend (grep 0) | P2 |
| B2 | **Bizonylat-szűrő részletes KYC + AML-jelölő mezők** | b5b FR-01..05 | `ReceiptPage.tsx:49` csak biz.szám-keresés; nincs 8-elemű típus-szűrő, KYC-mezők, 10M/ENGEDÉLYEZŐ flag | P2 |
| B3 | **„MÉGSEM" (megszakított tranzakció) bizonylat** | b4-bizonylatok FR-15/16 | nincs (biz.szám-kiesés ellen) | P2 |
| B4 | **Pillanatnyi pénztárállás: per-valuta KEZ-I DÍJ oszlop + szín + nyomtatás-gomb** | b5-penztarallas FR-PA-01/03/04 | `LiveCashPositionPage.tsx:93,98` egy összesített lábléc, nincs színkód/nyomtatás | P2 |
| B5 | **„Csak ügyfeles bizonylatok" szűrő** | b5-penztarallas FR-PA-05 | `TransactionListPage.tsx:241` — hiányzik (G15 részben pontatlan) | P2 |
| B6 | **Ráta-módosítás audit log (branch+név+dátum)** | b3-arfolyam FR-HL-11 | csak `currency_audit_log` (valuta-CRUD), nincs per-pénztár ráta-audit | P2 |
| B7 | **Foglaló-bizonylat hiányzó mezők** (ft-érték sor, befizetés dátum, visszafiz. eredeti biz.szám, jogi záradék) | b4-foglalo FR-8/10/13/14 | `ReceiptGeneratorService.java:181-207` | P2 |
| B8 | **Csoport-ráták perzisztencia: localStorage az SQLite `group_rates` helyett** | b1 FR-RFM-29 | `workgroupSheetStorage.ts:73-99` localStorage, nincs `lf:save-group-rates` IPC | P2 |
| B9 | **Bank API / Raiffeisen REST + admin-konfig tábla hiányzik** | b3-bank-api | `RaiffeisenRateService.java:36` weboldal-scraping, nincs `BANK_API_CONFIG` tábla/OAuth2 | P2 |
| B10 | **FR-RFM-20 napi 5 saját-hatáskörű R/S limit** | b1 FR-RFM-20 | nincs (a meglévő MAX_REVERSAL_COUNT=5 = sztornó) | P2 |

## C. Doc ↔ modern-architektúra eltérés — NEM bug (no-action, dokumentálva)

- **Sztornó/zárás könyvelés**: `TransactionReversalService` STANDARD elszámolás — a repo-memória szerint ez a HELYES (a spec a megfigyelt hibát írta le). NE írd át. (02-riport 🔴 FR-SZT-19)
- **Készletmozgás**: BUY valuta+/HUF−, SELL valuta−/HUF+ STANDARD — HELYES, a #995–999 helyesen nem írta át. (09-riport)
- **RFM UI**: 54-csempe „iroda"-rács → valójában munkacsoport-rács; ARFDATA.DAT/FTP → modern REST publish; 28→22 valuta (tudatos v2.5.61); J–S „szerkesztés letiltott" → FK-04 szerint szerkeszthető. (01-riport 🔴-k)
- **API-útvonal/tábla-név eltérések**: `/api/...` vs `/api/v1/...`, `cash_transfer`→`transfer`, `daily_cash_reports`→`daily_report` stb. — modern névkonvenció, funkcionálisan ekvivalens. (06-riport)
- **WU modell**: MTCN send/receive tranzakció vs. doc napi kézi egyenleg — implementáció-választás. (06-riport)
- **penztar-client legacy F1–F12 / animációk / checklista-panelek**: modern React UI-ban újraértelmezve; sok „MISSING" valójában a kliens-dist (forrás nincs a repóban) → futó-app verifikáció kell, nem kód-gap.

## D. Scope-on kívül / üzleti input kell

- **Zálog (EXZ)** — külön termék (b10-zalog).
- **Hardver/hálózati felmérés** (b10-hardver), **futófény/szkenner/nyomtató COM/IP runtime kötés** (G20 sub-scope) — telepítés/hardver, nem szoftver-logika.
- **ERB/FRB/TRB/PRB technikai kötés-kódok** külön TransactionType-ként — üzleti döntés.
- **NGM havi export automatizálás + SAR webhook** — kézbesítési cél/auth hiányzik.
- **A5 szankció-küszöbök, A3 Pmt-enforcement mód, A4 körlevél-blokk mód** — compliance/üzleti megerősítés kell az élesítés módjára.

---

## Javítási sorrend (ebben a körben)

1. **A2 (FOERTEKTAR role)** — triviális, biztonságos → AZONNAL.
2. **A1 (FATF ország beplumbolása)** — tiszta compliance wire-up → AZONNAL (signature + caller + teszt).
3. **A6 (profit_log bekötés)** — óvatosan, kettős-számolás elkerülésével → következő kör.
4. **A3/A4/A7 (Pmt 50M, körlevél-blokk, 10M hard-block élesítés)** — üzleti megerősítés a kényszerítés módjára, majd feature-flag mögött.
5. **B1–B10** — funkcionális gap-ek, prioritás szerint külön PR-ekben.

> A C/D tételek NEM kerülnek vakon átírásra (CLAUDE.md no-hallucináció + „ne írd át a helyes compliance-logikát" mandátum).
