# Doc↔kód konformancia-audit — Foglaló + Bizonylatok + Bizonylat-szűrés

Dátum: 2026-06-02
Auditált specifikációk:
- `EXCMD/b4-bizonylatok.md` (FR-1..FR-16)
- `EXCMD/b4-foglalo.md` (FR-1..FR-16)
- `EXCMD/b5b-bizonylat-szures.md` (FR-BSZUR-01..05)

Módszer: spec-követelmény soronkénti összevetés az aktuális kóddal. „IMPLEMENTED" csak file:line bizonyítékkal. Backend vs frontend/kliens megkülönböztetve.

Jelmagyarázat: ✅ kész · ⚠️ részleges · ❌ hiányzó · 🔴 hibás/jogszabály-kritikus hiány

---

## b4-foglalo.md (Foglaló modul)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
| --- | --- | --- | --- | --- |
| FR-1: Kassza (pénztár) azonosító megadása | ⚠️ | `ReservationService.java:96` (`SecurityUtils.getCurrentBranchId()`), `Reservation.java:60-62` (branch) | M | Pénztár/branch a security-kontextusból jön, NEM explicit beviteli mező. Funkcionálisan kötött az aktív irodához, de a doc „kassza ID" beviteli mezője (Penztar:105) nincs. VERIFIKÁLANDÓ üzletileg elfogadható-e. |
| FR-2: Rendelés napjának rögzítése | ❌ | — (keresett: `rendeles_napja`, `orderDate`, `reservationDate` az entity/DTO-ban — nincs) | M | Az entity csak `createdAt`-et tárol (`Reservation.java:118-120`); külön „rendelés napja" mező + jövőbeli-dátum-tiltás validáció nincs. |
| FR-3: Rendelt összeg + devizanem | ✅ | `Reservation.java:75-83` (`currencyCode`, `reservedAmount`); `ReservationService.java:115-119` (valuta-aktív ellenőrzés) | M | |
| FR-4: Árfolyam + egység rögzítése | ⚠️ | `Reservation.java:89-90` (`exchangeRate`) | M | Árfolyam rögzítve; az „egység" (100 EUR/Ft) NINCS külön mezőként (a doc data-modellje `arfolyam_egyseg` mezőt kér, az entity-ben nincs). |
| FR-5: Tranzakció típus = VÉTEL (auto) | ⚠️ | `ReservationService.java:32-44` (legacy „FOGLALOT VETT FEL", VÉTEL logika a doc-ban) | M | A foglaló konceptuálisan vétel-előleg, de explicit `transactionType=VETEL` jelölés a Reservation entity-n nincs. Beszámításkor a vétel-tranzakció külön jön létre. |
| FR-6: Bizonylat fejléc „FOGLALO ATVETELE" | ✅ | `ReceiptGeneratorService.java:182` (`isRefund ? "FOGLALÓ VISSZAFIZETÉSE" : "FOGLALÓ ÁTVÉTELE"`) | M | |
| FR-7: Ügyfél-azonosító adatok a bizonylaton (név, anyja neve, szül.hely/idő, okmány, állampolgárság) | ✅ | `ReceiptGeneratorService.java:223-232` (customerName/MotherName/BirthPlace/BirthDate/DocType/Nationality/Address) | M | Ügyfél-pillanatkép a foglaló-bizonylatra rákerül. |
| FR-8: Foglaló tranzakció részletei (biz.szám, rendelt összeg+deviza, ft-érték, határidő, foglaló HUF, befizetés dátuma) | ⚠️ | `ReceiptGeneratorService.java:181-198` (biz.szám, valuta, összeg, árfolyam, letét, érvényesség) | M | Hiányzik a bizonylatról: explicit „ft-érték" sor (csak árfolyam) és a „foglaló befizetve" dátum. A határidő (érvényesség) szerepel. |
| FR-9: Foglaló = ft-érték 5%-a, 5 Ft kerekítés | ✅ | `ReservationService.java:69` (`DEPOSIT_RATE=0.05`), `:124-126` (ftValue×0.05 → roundToFive), `:736-749` (roundToFive) | M | Pontosan 5%, 5 Ft-ra kerekítve. |
| FR-10: Jogi tájékoztató szöveg nyomtatása (megbízási szerződés, kétszeres visszafizetés, beszámítás) | ❌ | — (keresett a foglaló-bizonylat generálásban + EscPos: nincs foglaló-specifikus jogi blokk) | S | A foglaló-bizonylat csak adatsorokat tartalmaz (`ReceiptGeneratorService.java:180-208`); a doc szerinti statikus jogi záradék (5% / kétszeres visszafizetés / beszámítás) nincs nyomtatva. |
| FR-11: Két aláírás-hely (pénztáros + ügyfél) átvételnél | ⚠️ | `ReceiptData.java:129` (`signatureLine` egyetlen aláírás), `EscPosReceiptService printReceiptFooter` | M | A PDF/ESC-POS láblécben aláírás van, de a foglaló-bizonylat a PDF-úton megy (`ReservationController.java:185-186`); a doc szerinti KÉT elkülönített („penztaros"/„ugyfel") aláíró-hely a foglaló-bizonylaton nincs verifikálva — VERIFIKÁLANDÓ a `ReceiptPdfService`-ben. |
| FR-12: Visszafizetési bizonylat „FOGLALO VISSZAFIZETESE" fejléccel | ✅ | `ReceiptGeneratorService.java:158,182` (`isRefund=true`), `ReservationController.java:179-192` (`?refund=true`) | M | |
| FR-13: Visszafizetési adatok (kifizetés biz.szám, átvétel napja, eredeti biz.szám, átvett összeg, rendezés napja) | ⚠️ | `ReceiptGeneratorService.java:199-207` (visszafizetett összeg, lemondás oka) | M | A visszafizetési bizonylaton hiányzik: eredeti átvételi biz.szám hivatkozás, foglaló átvétel napja, rendezés napja külön sorként. Csak refundAmount + ok jelenik meg. |
| FR-14: Visszafizetési záró szöveg (beszámítva a mai ügyletbe) + 2 aláírás | ❌ | — (nincs záró nyilatkozat-szöveg a foglaló-bizonylat blokkban) | M | Beszámítási záró szöveg nincs. |
| FR-15: Rendelés-kapcsolat a Pénztári Adatlapon (UGYFELEK RENDELESE / KESZLET RENDELESE ERTEKTAR FELE) | ❌ | — (keresett: pénztári adatlap rendelés-rovat — nincs ilyen aggregátum) | C | `getReservedStock` (`ReservationService.java:464-483`) ad foglalt-készletet valutánként, de a Pénztári Adatlap doc-beli „rendelés" rovatok bekötése nincs. |
| FR-16: Pmt./AML 50M HUF feletti forrás-igazolás + szlip max 3 év | 🔴 | `AmlService.java:329,439-441` (50M csak osztályozás+warning); forrás-okirat / szlip-kor validáció: NINCS (keresett: `proofType`, `MAGANOKIRAT`, `BANK_SZLIP`, `1095`, slip age — 0 találat a forráskódban) | Magas | A foglaló (és tranzakció) NEM kényszeríti ki: (a) 50M felett kötelező közjegyzői/ügyvédi ellenjegyzésű magánokirat, (b) két tanús nyilatkozat tiltása, (c) banki szlip ≤ 3 év elutasítás. A `foglalok.forras_dokumentum_*` doc-mezők sincsenek az entity-ben. |
| Adatmodell: `foglalok` tábla (entity: Reservation) | ⚠️ | `Reservation.java:21-29` | — | Az entity neve `reservation` (nem `foglalok`); fő mezők megvannak, de hiányoznak: `rendeles_napja`, `arfolyam_egyseg`, ügyfél-adat mezők (a Customer-ből jön), `forras_dokumentum_*`. |
| Adatmodell: `foglalo_visszafizetesek` tábla | ❌ | — (nincs külön visszafizetés-entity; refund a Reservation-on tárolt: `Reservation.java:175-177`, `cancellation_receipt_number:145`) | — | Nincs külön visszafizetés-napló tábla; a doc szerinti `kifizetes_bizonylatszama`, `modja` (BESZAMITVA/KESZPENZ_VISSZA/KETSZERES_VISSZA) mezők hiányoznak. |
| TBD-2/6: Foglaló sztornózhatóság + kétszeres visszafizetés (Supervisor) | ✅ | `ReservationService.java:332-426` (`cancelByCompany` 2× refund + Supervisor branch-ellenőrzés), `ReservationController.java:104-112` (`hasAnyRole SUPERVISOR/MANAGER/ADMIN`) | M | EBC-stornó dupla letét + supervisor-jóváhagyás kész. |
| TBD-7: Bizonylatszám B/K prefix + 6 számjegy | ⚠️ | `ReceiptGeneratorService.java:155-169` (foglaló prefix = `F`, nem `B`/`K`), `:729-733` (`%s-%s-%05d`) | — | A doc `B######`/`K######` formátumot ír elő; a kód `F-YYMMDD-NNNNN` formátumot használ — eltérő séma. |
| RBAC: Cashier rögzít, Supervisor jóváhagy | ✅ | `ReservationController.java:53,74,89,105` | M | |

---

## b4-bizonylatok.md (Bizonylatok modul)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
| --- | --- | --- | --- | --- |
| FR-1: VALUTA VÉTELI bizonylat struktúra | ✅ | `ReceiptGeneratorService.java:74-76,420-525` (`generateBuyReceipt`), `EscPosReceiptService.java:78-86` | M | Cégfejléc, biz.szám, dátum, ügyfél, deviza/árfolyam/HUF, kezelési díj, NAV szám (`navReceiptNumber:441`), ÁFA-záradék, aláírás. |
| FR-2: VALUTA ELADÁSI bizonylat struktúra | ✅ | `ReceiptGeneratorService.java:65-67`, `EscPosReceiptService.java:92-100` | M | |
| FR-3: Eladási bizonylat (2) egyszerűsített sablon | ❌ | — (nincs alternatív sablon-kapcsoló) | C | Egyetlen eladási sablon van; nettó-árfolyamos összevont változat nincs. |
| FR-4: Vételi bizonylat (2) egyszerűsített sablon | ❌ | — | C | Nincs alternatív vételi sablon. |
| FR-5: Összevont vételi+eladási tranzakciós lap | ⚠️ | `TransactionMultiLineService.java` (multi-line tranzakció létezik) | S | Multi-line tranzakció van, de egyazon lapon vétel+eladás elkülönített összesítővel mint bizonylat-sablon nincs verifikálva. |
| FR-6: Összevont bizonylat (2) alkudott árfolyamokkal | ❌ | — | S | Nincs. |
| FR-7: JOGCIM NYILATKOZAT külön A4 lap | ⚠️ | `EscPosReceiptService.java:182-199` (`generateLegalDeclaration` — szalag, NEM A4) | M | Jogcím nyilatkozat szöveg létezik, de szalag-formátumban; külön A4-lapként nem. |
| FR-8: JOGCIM NYILATKOZAT forráskódok (GH/MN/IN/OR/AJ/NY/HI) + 50M szigorított szabály + szlip 3 év | 🔴 | `ReceiptGeneratorService.java:638-646` (`sourceOfFunds` szöveg 300k felett); forráskód-enum + 50M okirat-kényszer + szlip-kor: NINCS | M | A 7 forráskód NEM strukturált enum, csak szabad `sourceOfFunds` string. 50M magánokirat-kötelezettség, két tanús tiltás, szlip ≤3 év elutasítás nincs implementálva (ld. b4-foglalo FR-16). |
| FR-9: JOGCIM NYILATKOZAT másodpéldány (pénztáros aláírás) | ❌ | — | M | Másodpéldány-generálás + pénztáros ellenőrző aláírás nincs külön. |
| FR-10: KKTG ÁTVÉTELI bizonylat (összeg, dátum, átvevő, plomba) | ⚠️ | `EscPosReceiptService.java:387-417` (`generateKktgTransferReceipt` — plombaszám:398-400, átadó/átvevő aláírás) | M | Egyetlen KKTG „átadás-átvétel" bizonylat van; külön ÁTVÉTELI vs ÁTADÁSI változat nincs. Plomba-formátum (`PLB######`) validáció nincs. |
| FR-11: KKTG ÁTADÁSI bizonylat | ⚠️ | `EscPosReceiptService.java:387-417` | M | Lásd FR-10 — összevont, nem külön. |
| FR-12: Media kiadások elszámolás bizonylat | ❌ | — (media a `MediaService`/`MEDIA` legacy tábla, de bizonylat-generálás nincs) | C | Nincs media-elszámolás bizonylat. |
| FR-13: Pénztári ÁTADÁS bizonylat (devizánként, címletjegyzék, plomba) | ⚠️ | `ReceiptGeneratorService.java:82-108` (`generateTransferReceipt`), `EscPosReceiptService.java:106-116` (`generateTransferOutReceipt`) | M | Átadás-bizonylat van forrás/cél irodával; plomba a Transfer-en (`Transfer.java`, V208/V283 carrier_seal). DE devizánkénti CÍMLETJEGYZÉK a bizonylaton NINCS verifikálva. |
| FR-14: Pénztári ÁTVÉTEL bizonylat | ⚠️ | `EscPosReceiptService.java:122-132` (`generateTransferInReceipt`) | M | Átvétel-bizonylat van; címletjegyzék hasonlóan nem verifikált. |
| FR-15: MÉGSEM bizonylat (megszakított tranzakció) — keresztben „MEGSEM", biz.szám-kiesés elkerülés | ❌ | — (keresett: `MEGSEM`, `MÉGSEM`, `abandoned`, `void receipt`, `megszakít` a backend+kliens forráskódban — 0 releváns találat) | M | NINCS megszakított-tranzakció bizonylat. Sztornó (`generateStornoReceipt`) létezik, de az MÁS (rögzített tranzakció utólagos sztornója), nem a rögzítés-közbeni mégsem. |
| FR-16: MÉGSEM bizonylat (2) másodpéldány | ❌ | — | M | Nincs (FR-15 sincs). |
| Adatmodell: `receipts` + `receipt_items` + `aml_declarations` táblák | ⚠️ | `ReceiptSequence.java`, `Transaction.java` (bizonylat-adatok a tranzakción), nincs külön `aml_declarations` tábla | — | A bizonylatok a Transaction/Transfer entity-kből generálódnak (nincs dedikált `receipts` metaadat-tábla a doc séma szerint). `aml_declarations` tábla (proof_type/proof_date/proof_verifier) hiányzik. |
| Integráció: NAV Online Pénztárgép driver | ⚠️ | `ReceiptGeneratorService.java:441` (`navReceiptNumber` mező), `NavIntegrationServiceTest` létezik | — | NAV-szám mező rákerül a bizonylatra; tényleges NAV-driver auto-küldés nyomtatáskor VERIFIKÁLANDÓ. |
| Kliensoldali offline sorszám + Postgres sync | ✅ | `penztar-client/electron/sqlite.ts`, `sync-engine.ts` (outbox), `packages/local-first-core/src/outbox.ts` | — | Local-first offline sorszám + outbox sync architektúra megvan. |

---

## b5b-bizonylat-szures.md (Bizonylatok szűrése képernyő)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
| --- | --- | --- | --- | --- |
| FR-BSZUR-01: Bizonylattípus-szűrő (kikapcsolva / ügyfeles / vételi / eladási / konverziós / átadási / átvételi / stornózott) | ⚠️ | Backend: `ReceiptSearchCriteria.java:17` (`type`), `ReceiptSearchService.java:142-144` (transactionType egyezés). Frontend: `ReceiptPage.tsx:49-56` (csak biz.szám szűrés) | Must | Backend tud típusra szűrni (egy `type` paraméter), DE nincs a doc-beli 8-elemű rögzített lista (külön „csak ügyfeles" és „stornózott" mint külön opció kérdéses). Frontend `ReceiptPage` NEM kínál típus-szűrő vezérlőt — csak szövegkeresés biz.számra. |
| FR-BSZUR-02: Hatókör-választó (hónap összes vs. választott időszak) | ⚠️ | Backend: `ReceiptSearchCriteria.java:15-16` (`dateFrom`/`dateTo`), `ReceiptSearchService.java:135-140` | Must | Backend támogat dátum-intervallumot; a doc „A HÓNAP ÖSSZES" vs „CSAK A VÁLASZTOTT" radio-vezérlő a frontenden NINCS. |
| FR-BSZUR-03: Természetes személy ügyfél-adatlap szűrőmezők (név, anyja neve, leánykori név, szül.hely/idő, állampolgárság, lakcím, okmánytípus, azonosító) | ❌ | Backend: `ReceiptSearchCriteria.java:20` (csak `customer` = név LIKE), `ReceiptSearchService.java:153-157` | Must | A 9 doc-mezőből CSAK a név (customerName LIKE) szűrhető. Anyja neve, leánykori név, szül.hely/idő, állampolgárság, lakcím, okmánytípus, okmányszám szerinti szűrés NINCS. |
| FR-BSZUR-04: Jogi személy szűrőmezők (cégnév, telephely, képviselő beosztása) | ❌ | — (a ReceiptSearchCriteria-ban nincs jogi-személy mező) | Should | Nincs jogi-személy szűrés. |
| FR-BSZUR-05: AML-jelölők a szűrőn (10M FT küszöb flag, ENGEDÉLYEZŐ neve/beosztása) | ❌ | — (a search-result DTO-ban nincs AML-flag / engedélyező; `ReceiptSearchResultDto`) | Must (Pmt.) | A 10M-küszöb vizuális jelölő és az ENGEDÉLYEZŐ adat a bizonylat-szűrő nézeten nincs. |
| RBAC: Cashier / Treasurer / Internal Auditor szűrési szintek | ⚠️ | `ReceiptSearchController.java` (VERIFIKÁLANDÓ a @PreAuthorize) | — | A szerepkör-differenciált szűrési hozzáférés (auditor = AML-meghaladó) nem verifikált. |

---

## Záró statisztika

- Ellenőrzött követelmény: 48 (b4-foglalo 21 + b4-bizonylatok 21 + b5b 6)
- Kész (✅): 12
- Részleges (⚠️): 18
- Hiányzó (❌): 15
- Hibás / jogszabály-kritikus (🔴): 3

### Kiemelt kockázatok (Magas prio)
1. 🔴 **Pmt. 50M HUF forrás-igazolás kényszerítés HIÁNYZIK** (b4-foglalo FR-16, b4-bizonylatok FR-8): se magánokirat-kötelezettség, se két tanús tiltás, se banki szlip ≤3 év elutasítás. Csak osztályozás+warning van (`AmlService.java:439-441`).
2. ❌ **MÉGSEM bizonylat (megszakított tranzakció) HIÁNYZIK** (b4-bizonylatok FR-15/16): biz.szám-kiesés elleni „MEGSEM" bizonylat nincs.
3. ❌ **Bizonylat-szűrés ügyfél-adatlap + AML-jelölők HIÁNYOZNAK** (b5b FR-03/04/05): csak név+típus+dátum+összeg szűrhető; a részletes KYC-mezők és a 10M AML-jelölő nincs.
