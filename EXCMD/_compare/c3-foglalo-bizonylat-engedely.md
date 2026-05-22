# C3 összevetés — Foglaló (b4-foglalo) + Bizonylatok (b4-bizonylatok) + Engedélyezés-adatok (b3)

Forrás-spec-ek vs. tényleges kód (v2.26.18). Kutatás-only, nincs kódmódosítás.

## b4-foglalo.md — Foglaló (ügyfél-előleg)

| FR | Státusz | Kód-bizonyíték | Hiány |
| --- | --- | --- | --- |
| FR-1 pénztár(kassza) azonosító | PARTIAL | `Reservation.branch` + `worker` (`entity/Reservation.java:60-69`); SecurityUtils branchId | Nincs explicit "Penztar: 105" kassza-szám mező |
| FR-2 rendelés napja | PARTIAL | `createdAt` (`Reservation.java:118-120`) | Nincs külön "rendelés napja" üzleti mező |
| FR-3 rendelt összeg+deviza | IMPLEMENTED | `reservedAmount`, `currencyCode` (`Reservation.java:75-83`) | — |
| FR-4 árfolyam + egység | PARTIAL | `exchangeRate` (`Reservation.java:89`) | Nincs árfolyam-egység (100 EUR/Ft) mező |
| FR-5 tranzakció típus = VÉTEL | MISSING (backend) | backend nincs típus; frontend `transactionType` BUY/SELL (`ReservationPage.tsx:174,293-303`) | Backend entity nem tárol tranz-típust; nincs VÉTEL-kötés |
| FR-6 bizonylat fejléc "FOGLALO ATVETELE" | MISSING | nincs reservation-receipt render (Grep: 0 találat `FOGLAL` a receipt-service-ekben) | Teljesen hiányzik |
| FR-7 ügyfél-azonosító snapshot a bizonylaton | MISSING | `Reservation.customer` csak FK (`Reservation.java:53-55`), nincs anyja neve / szül.hely / szül.idő / okmány snapshot | Nincs ügyfél-snapshot a foglalón |
| FR-8 bizonylat-tételek (biz.szám, Ft-érték, határidő, foglaló HUF, befizetve) | PARTIAL | `receiptNumber`, `depositAmount`, `expiresAt` (`Reservation.java:96-139`) | Nincs bizonylat-render; "befizetve dátum" = createdAt közelítés |
| FR-9 foglaló = megbízás 5%-a | MISSING | `createReservation` letét = `amount × rate` (`ReservationService.java:114-115`), NEM 5% | Az 5% szabály nincs implementálva |
| FR-10 jogi/tájékoztató szöveg | MISSING | nincs | Teljes jogi sablon hiányzik |
| FR-11 két aláírás (pénztáros+ügyfél) | MISSING | nincs reservation-bizonylat | — |
| FR-12 visszafizetési bizonylat "FOGLALO VISSZAFIZETESE" | MISSING | van `cancelByCustomer`/`cancelByCompany`/`fulfill` logika (`ReservationService.java:188-390`), de nincs bizonylat-render | Bizonylat-render hiányzik |
| FR-13 visszafiz. bizonylat mezők (K-szám, B-szám hivatkozás stb.) | PARTIAL | `cancellationReceiptNumber` mező létezik (`Reservation.java:145-146`) de SOHA nincs kitöltve a service-ben | Nincs K→B párosítás-render |
| FR-14 visszafiz. záró szöveg + 2 aláírás | MISSING | nincs | — |
| FR-15 foglaló↔ügyfél-rendelés kapcsolat (Pénztári adatlap) | MISSING | nincs | — |

**Fő probléma:** A backend `ReservationService` valódi pénzmozgás-logikával él (5-re kerekítés `roundToFive`, dupla visszafizetés EBC-stornónál, készlet-elkülönítés), DE az 5% foglaló-számítás hiányzik és **a frontend egészen más API-kontraktust hív**: `ReservationPage.tsx` `/reservations/branch/{id}/active`, `/confirm`, `guaranteedRate`, `sourceCurrency/targetCurrency`, `validityHours` — a backend `ReservationController` viszont `/active?branchId=`, `currencyCode`, `exchangeRate`, `expiresAt`, NINCS `/confirm` és `PENDING/CONFIRMED` státusz (entity: `ACTIVE/FULFILLED/CANCELLED_*/EXPIRED`). A frontend és backend nem ugyanazt a foglalót implementálja.

## b4-bizonylatok.md — Bizonylat-minták

| FR | Státusz | Kód-bizonyíték | Hiány |
| --- | --- | --- | --- |
| FR-1 közös cég-fejléc | PARTIAL | `printReceiptHeader` company/branch/address/tax/phone (`EscPosReceiptService.java:539-563`) | Nincs explicit "75. BIKISCSABA" fiók-szám+város formátum (branchName-be olvad) |
| FR-2 Forint átvételi NYUGTA (sorszám/dátum/idő) | IMPLEMENTED | `EscPosReceiptService.java:542,568-575` + `generateReceiptNumber` (`ReceiptGeneratorService.java:607`) | — |
| FR-3 áfa-mentesség szöveg | IMPLEMENTED | `vatExemptionText` (`ReceiptGeneratorService.java:388`), render `EscPosReceiptService.java:579-583` | — |
| FR-4 devizatétel-táblázat (V.nem/Árf/B.jegy/Forint) | IMPLEMENTED | `EscPosReceiptService.java:588-596` | — |
| FR-5 összesítő (Kerekítés/Nettó/Kez.ktsg/Kifizetve) | IMPLEMENTED | `EscPosReceiptService.java:610` + ReceiptData mezők | — |
| FR-6 ügyfél-adat blokk + deviza-státusz/közszereplő | IMPLEMENTED | Belföldi status `EscPosReceiptService.java:668`, PEP `applyPepDeclarationIfNeeded` (`ReceiptGeneratorService.java:472`) | — |
| FR-7 lábléc Raiffeisen/reklám | PARTIAL | `RECEIPT_BANK_PARTNER_NAME` (`EscPosReceiptService.java:680`) | Reklám-szöveg "KEDVEZOBB..." nem talált |
| FR-8 JOGCIM NYILATKOZAT | IMPLEMENTED | Jogcimnyilatkozat blokk (`EscPosReceiptService.java:180,219`), source-decl (`ReceiptGeneratorService.java:516`) | — |
| FR-9 Extra tranzakciós díjak lista (Engedélyező oszlop) | MISSING | Grep `EGYEDI KEZDIJ`/`Engedelyezo`: 0 találat | Lista-bizonylat hiányzik |
| FR-10 Pénztári adatlap (KORLEVELEK/RENDELESEK rovatok) | MISSING | nincs | — |
| FR-11 KKTG ÁTVÉTELI bizonylat | PARTIAL | "KKTG átadás-átvétel" header (`EscPosReceiptService.java:390`) + `MaterialReceipt` entity | Nincs külön ÁTVÉTELI fejléc/B-prefix |
| FR-12 KKTG ÁTADÁSI bizonylat | PARTIAL | ugyanaz a közös KKTG render | Nincs külön ÁTADÁSI fejléc/K-prefix |
| FR-13 Kezelési költség dekádzárása | PARTIAL | `HandlingFeeDecadeService` + `HandlingFeeDecadeReport` entity létezik | Nincs dekád-bizonylat render (Sor/Np/Ft.átvétel/átadás layout) |
| FR-14/15 Pénztári átadás (deviza is) szállító+plomba | IMPLEMENTED | "Átadási bizonylat" (`EscPosReceiptService.java:109`), `sealNumber`/carrier (`ReceiptGeneratorService.java:422`) | — |
| FR-16 Pénztári átvétel + nyilatkozat | IMPLEMENTED | "Átvételi bizonylat" (`EscPosReceiptService.java:125`) | — |
| FR-17 Árfolyam nyomtatás (vételi/eladási) | PARTIAL (arfolyam-keszito) | rate-maker modul létezik | Konkrét lista-bizonylat render nem verifikált e körben |
| FR-18 Elszámoló árfolyam lista | PARTIAL | — | nem verifikált |
| FR-19 Pénztárosi nyilatkozat | MISSING | Grep "NYILATKOZAT"+zárószalag: nem talált dedikált render | Hiányzik |
| FR-20 Pénztár állás | PARTIAL | "Pénztár állás" header (`EscPosReceiptService.java:304`) | Nyitó/Forgalom/Egyenleg 3-oszlopos render nem verifikált |
| FR-21 Pénztár állás kez-díj egyenleg blokk | MISSING | Grep "Napi nyito kez-i dij"/"Pillanatnyi zaro": 0 találat | Hiányzik |

## b3-engedelyezes-adatok.md — Tranzakció-engedélyezés adatlap

| FR | Státusz | Kód-bizonyíték | Hiány |
| --- | --- | --- | --- |
| FR-1 pénztár szám+név | MISSING | nincs "engedélykérő adatlap" entity/render | — |
| FR-2 bizonylatszám az engedélyezőn | MISSING | — | — |
| FR-3 tranz. összeg (HUF) | MISSING | — | — |
| FR-4 valuta-soronkénti bontás | MISSING | — | — |
| FR-5 ügyfél-azonosító adatok az engedélyezőn | MISSING | — | — |
| FR-6 engedélyező személy | PARTIAL | `DiscountApprovalService` szint-meghatározás (engedélyező-szerep), `StornoApproval.approvedByWorker` (`StornoApproval.java:87`), `RateApproval` | Nincs ÁLTALÁNOS tranzakció-engedélykérő adatlap; csak diszkont/sztornó/árfolyam-eltérés approval létezik |

**Megjegyzés:** A b3 nem általános tranzakció-engedélyeztetést ír le, hanem egy konkrét engedélykérő ADATLAP mezőkészletet. A program approval-mechanizmusai (Discount/Storno/Rate) léteznek, de a hivatkozott "Engedély megadása egy tranzakcióhoz" adatlap (pénztár+bizonylat+valuta-sorok+ügyfél-snapshot+engedélyező egy lapon) nincs.

---

## VALÓS GAP-EK (prioritással)

**P0 — Foglaló frontend↔backend kontraktus-törés.** A `ReservationPage.tsx` által hívott endpointok és mezők NEM léteznek a `ReservationController`-ben:
- FE hívja: `/reservations/branch/${branchId}/active|today|expiring`, `POST /reservations/${id}/confirm`, mezők `guaranteedRate`/`sourceCurrencyId`/`targetCurrencyId`/`validityHours`, státusz `PENDING/CONFIRMED`.
- BE nyújt: `/reservations/active?branchId=`, nincs `/confirm`, mezők `currencyCode`/`exchangeRate`/`expiresAt`, státusz `ACTIVE/FULFILLED/...`.
- Következmény: a foglaló-lista lekérés 404-re fut (`catch { setReservations([]) }` → mindig üres lista), létrehozás 400/404. A foglaló funkció a UI-ból gyakorlatilag nem működik. Vagy a BE-t kell a FE-hez igazítani, vagy fordítva.

**P1 — Foglaló 5% letét-szabály hiányzik.** Spec FR-9: `foglaló = megbízás 5%-a`. Tényleges:
```java
BigDecimal rawDeposit = amount.multiply(exchangeRate).setScale(2, RoundingMode.HALF_UP);
BigDecimal depositAmount = roundToFive(rawDeposit);   // ReservationService.java:114-115
```
A letét a TELJES Ft-érték, nem 5%-a. (TBD-4 kerekítés a 5-re kerekítés `roundToFive`-val megoldott.)

**P1 — Foglaló-bizonylat render teljesen hiányzik (FR-6..14).** Sem a `ReceiptGeneratorService`, sem az `EscPosReceiptService` nem ismer foglaló-fejlécet ("FOGLALO ATVETELE"/"FOGLALO VISSZAFIZETESE"), ügyfél-snapshotot, jogi szöveget, K→B párosítást. A `cancellationReceiptNumber` mező létezik (`Reservation.java:145`), de a service sosem tölti ki.

**P2 — Foglaló ügyfél-snapshot hiányzik (FR-7).** A `Reservation` csak `customer` FK-t tart (`Reservation.java:53-55`); nincs anyja neve / szül.hely / szül.idő / okmány-snapshot, így jogszerű, módosíthatatlan foglaló-bizonylat nem állítható ki (vö. a tranzakció-receipt-ek viszont tárolnak snapshotot).

**P2 — Pénztár állás kez-díj egyenleg blokk (b4 FR-21) és Pénztárosi nyilatkozat (FR-19) hiányzik.** Grep 0 találat ("Napi nyito kez-i dij", "Pillanatnyi zaro", zárószalag-nyilatkozat).

**P3 — Extra tranzakciós díjak lista (b4 FR-9) + Pénztári adatlap (FR-10) nincs.** "EGYEDI KEZDIJ"/"Engedelyezo" oszlopos lista-bizonylat hiányzik.

**Nem-gap (jól lefedett):** Forint átvételi NYUGTA, JOGCIM nyilatkozat, devizatétel-táblázat, áfa-mentesség, kezelési költség sor, Belföldi/PEP státusz, pénztári átadás/átvétel szállító+plomba — mind él (`EscPosReceiptService.java`, `ReceiptGeneratorService.java`).
