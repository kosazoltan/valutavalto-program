# 09 — Dátumozott auditok + high-priority FR: doc↔kód re-verifikáció (2026-06-02)

Cél: a három dátumozott EXCMD-audit (2026-05-20…06-01 modulfejlesztés-terv, 2026-06-01
audit-verifikáció, 2026-06-02 tranzakciós audit) + a `high-priority-explicit-fr.md` állításainak
**tény-alapú újraellenőrzése a JELENLEGI kód ellen** (HEAD: main, V288 / #1001 után).

Szabály: minden pont egyenként; "IMPLEMENTED" csak `file:line` bizonyítékkal; nincs találat →
MISSING + mit kerestem; backend vs frontend/kliens külön; bizonytalan → VERIFIKÁLANDÓ.
PR-leírásnak NEM hiszek — a kódot néztem.

---

## A) 2026-06-02 tranzakciós audit 6 pontja (a #995–#999 állítólag lefedte)

| # | Audit-pont | Prio | Állapot | Kód-bizonyíték |
|---|-----------|------|---------|----------------|
| 1 | Készletmozgás vétel/eladás (a doc "új szabályt" kért: vételnél semmi, eladásnál csak valuta) | P0 | ⚠️ **SZÁNDÉKOSAN VÁLTOZATLAN** (STANDARD modell megmaradt) | `TransactionService.java:361-362` (BUY: valuta+, HUF−), `:571-572` (SELL: valuta−, HUF+). A doc "új szabálya" téves megfigyelésen alapult; a MEMORY-mandate (`project_transaction_business_rules_2026_06_02`) szerint a STANDARD elszámolás HELYES, NEM írandó át. A #995–999 helyesen NEM módosította. Nincs `underNewStockPolicy` teszt (nem is kell). |
| 2 | Két 06.02-i tétel hiánya a listából | P1 | ✅ rész-fix IMPLEMENTED (diagnosztika DB-függő) | Tartós sync-hiba mezők: `penztar-client/electron/sqlite.ts:387-393` (`sync_error TEXT`, `retry_count`, `last_attempt_at`) + `:533-534`. Lista felszínre hozza: `TransactionListPage.tsx:97-101` (`syncError`/`syncAttempts`), `:324-332` (PIROS státusz sikertelen feltöltésnél). A konkrét 2 tétel DB-állapota továbbra is csak éles lekérdezéssel dönthető el (a doc maga is így rögzítette). |
| 3 | Állampolgárság teljes törzs | P1 | ✅ IMPLEMENTED (backend + frontend) | Migráció: `V286__nationality_dictionary_seed.sql` (HU + ~100 ország + OTHER, `NATIONALITY` kategória, idempotens). Backend endpoint: `DictionaryController.java:36` `getByCategory`. Frontend: `CustomerPanel.tsx:150,153` (`dictionaryApi.getByCategory('NATIONALITY')`), select-ek `:696-700`, `:784-786`, `:949-950`; 3-opciós fallback megmaradt (`:955-956`). |
| 4 | Sávos árfolyam Electron cache adatvesztés | P1 | ✅ IMPLEMENTED (cache-mapper); ⚠️ kézi sávválasztó NEM (by-design auto) | `electronTransactions.ts:12-22` (`ElectronCachedRate` limit1/2/3 + official_rate mezők), mapper `:241-250` (mind átadva). UX: a sávválasztás továbbra is AUTOMATIKUS (`CashierTransactionPage.tsx:335,393,490` `getBandForAmount`) — a doc "kézi választó" kérése NYITOTT kérdés volt, nem kemény követelmény; az adatvesztés (a tényleges hiba) megoldva. |
| 5 | Kezelési díj beállítás (jogosultság) | P1 | ✅ IMPLEMENTED (RBAC bővítve) | `HandlingFeeConfigController.java:31` `@PreAuthorize("hasAnyRole('MANAGER','ADMIN','UGYVEZETO','IRODAVEZETO','BELSO_ELLENOR')")` — a doc által kért főértéktáros/ügyvezető szint bekerült (UGYVEZETO). Pénztáros NEM jogosult. |
| 6 | Kezelési díj override (felezés/elengedés/speciális, ügyfélkártya, jóváhagyás) | P0 | ✅ IMPLEMENTED (teljes vertikum) | Migráció: `V287__transaction_handling_fee_override.sql` (4 oszlop). Entity: `Transaction.java:373,377,380,383`. Enumok: `HandlingFeeOverrideType.java`, `HandlingFeeOverrideReason.java`. Szerver-autoritatív validáció+mátrix: `HandlingFeeOverrideService.java:51-106` (HALF=base/2 szerver-számolt, WAIVED=0, SPECIAL=csak DIRECTOR; CUSTOMER_CARD→kártyaszám kötelező). Bekötés: `TransactionService.java:213-218` (BUY), `:441` (SELL), worker-role `:994`. DTO: `BuyRequestDto.java:42-45`, `SellRequestDto.java:42-45`. Frontend F9 dialog: `CashierTransactionPage.tsx:146-147,1061-1101` (típus/jogcím/kártyaszám, SPECIAL director-gated). API: `transactions.ts:197-199,236-238`. Teszt: `HandlingFeeOverrideServiceTest.java`. |
| 7 | Kedvezmény vs kezelési díj fogalmi szétválasztás | P1 | ✅ szétválasztva | Külön override-modell (`HandlingFeeOverrideService`) NEM terheli a `discountPercent`-et; `discountPercent` továbbra is külön ágon (`applyBuyDiscount`, `DiscountApprovalService`). |

**6/6 audit-pont VERIFIKÁLT.** P0#1 szándékosan változatlan (helyes), P0#6 teljes, a 4 P1 implementált.
Maradék enyhe gap: kézi sávválasztó UX (4), tartós sync-hiba in-memory→DB már megvan de a konkrét
06.02 tételek DB-diagnosztikája külső.

---

## B) 2026-06-01 audit-verifikáció állításai (re-check)

A 2026-06-01 doc azt állította, hogy a 2026-05-31 audit 24 findingje túlnyomóan JAVÍTVA. Spot-check:

| Finding | 06-01 doc állít | Re-verifikáció |
|---------|-----------------|----------------|
| publishBatch megkerüli RateSpreadGate | ✅ JAVÍTVA | VERIFIKÁLANDÓ — nem ellenőriztem újra ebben a körben (kívül a 6 ponton) |
| P3 DailyBalance dual-source | ⬜ nyitott | VERIFIKÁLANDÓ — változatlanul nyitott a doc szerint |
| hash-strict OFF / localStorage rate-maker | by-design / user-döntés | egyezik a 06-01 doc-kal (nem 6-pont scope) |

A 06-01 doc fő következtetése (a 05-20…06-01 PLAN elavult, a fixek `2026-05-31` komment-markert
hordoznak) konzisztens a kód-jelenléttel; teljes 24-finding re-grep nem volt e feladat tárgya.

---

## C) high-priority-explicit-fr.md (12 modul, 457 FR) — gap spot-check

A lista egy szélesebb doc-audit modul-kiválasztása; a teljes 457 FR verifikáció kívül esik e
re-verify scope-ján (a 6 dátumozott ponton). Célzott MISSING-keresés a legkockázatosabb tételre:

| Modul (FR) | Állapot | Bizonyíték / mit kerestem |
|-----------|---------|---------------------------|
| b3b-erb-egyedi-kotes — ERB Egyedi kötés / Raiffeisen kártyás szerződéskötő képernyő (FR:4) | ❌ **MISSING** | `grep -rln "ErbEgyedi\|erb-egyedi\|ErbKotes\|egyedi kötés\|kártyás szerződ"` a `backend/src/main` és `frontend-react/src` és `penztar-client` alatt → 0 valós találat (a "ERB"-substring hitek false-positive: MonthlyReport stb.). Sem backend controller/entity, sem frontend oldal nincs. |
| b6b-egyeb-feladatok-menu — NAV pénztárgép + OTP POS (FR:4) | ✅ rész-IMPLEMENTED | `NavClosingController.java`, `NavIntegrationController.java`, `PosTerminalController.java`, `PosTerminalStubController.java` léteznek (FR-szintű teljesség VERIFIKÁLANDÓ). |
| b1/b2/b3/b5 többi modul | VERIFIKÁLANDÓ | Nem ellenőriztem FR-szinten ebben a körben (a feladat fókusza a 6 dátumozott pont). |

---

## Záró minősítés

- **6/6 2026-06-02 audit-pont kód-szinten verifikált.** A két P0 közül #1 (készletmozgás) szándékosan
  és helyesen VÁLTOZATLAN (STANDARD modell — a doc "új szabálya" téves volt), #6 (díj-override)
  teljes vertikumban kész (migráció→entity→service→DTO→bekötés→frontend→API→teszt).
- **Genuine maradék:** (4) kézi sávválasztó UX (nyitott kérdés, nem kötelező), (2) a konkrét
  06.02 tételek DB-diagnosztikája külső adattól függ.
- **Új MISSING felfedezés (high-prio FR):** ❌ ERB Egyedi kötés (Raiffeisen kártyás) képernyő
  teljesen hiányzik (sem backend, sem frontend).
- A teljes 457-FR és a teljes 24-finding re-grep NEM volt e feladat tárgya → VERIFIKÁLANDÓ.

Készítette: AI doc↔kód konformancia-audit. HEAD: main (V288/#1001). Dátum: 2026-06-02.
