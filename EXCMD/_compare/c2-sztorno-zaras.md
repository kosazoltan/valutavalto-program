# C2 — Sztornó + Zárás szakaszonkénti összevetés (spec ↔ kód)

> Forrás-specek: `EXCMD/b2-sztorno.md` (18 FR), `EXCMD/b2-zaras-ablak.md` (23 FR), `EXCMD/b2-zaras-kepernyok-bizonylatok.md` (30 FR).
> Verifikáció: kódbázis Grep/Read (backend `service/`, `controller/`, frontend `pages/`). KUTATÁS-only.

## b2-sztorno.md (18 FR)

| Spec | FR-ID | Követelmény | Státusz | Bizonyíték | Hiány |
|---|---|---|---|---|---|
| sztorno | FR-1 | Sztornó kezdeményezés rendszerben + POS-on | IMPLEMENTED | `StornoPage.tsx:104` execute; `StornoService.executePosStorno():308`, `executeOtpTerminalStorno():341` | — |
| sztorno | FR-2 | Eredeti tranzakció lekérése/azonosítás (idő, deviza, árf., összeg) | IMPLEMENTED | `StornoService.resolveTransaction():86` (id v. receiptNumber); `StornoPage.tsx:193-237` adatpanel | — |
| sztorno | FR-3 | Visszafizetés eredeti tranzakció szerint, ha nincs eltérő árf. | IMPLEMENTED | `TransactionReversalService.executeReversal():131-169` eredeti árf.+összeg, kassza-visszaállítás | — |
| sztorno | FR-4 | NAV felé sztornó automatikus (bekötött pénztárgép) | MISSING | nincs pénztárgép NAV-sztornó integráció (spec TBD-1 is jelzi) | NAV pénztárgép sztornó-jelentés interfész |
| sztorno | FR-5 | Napi sztornó-szám automatikus számlálás | IMPLEMENTED | `StornoService.doCheckStorno():118-119` `countReversalsByBranchAndDate` + `...AndWorkerAndDate` | — |
| sztorno | FR-6 | 3. utáni sztornó tiltva, külön engedély | IMPLEMENTED | `StornoService:55-59` limit (branch 3 / cashier 2); `:131-135` `requiresApproval` | — |
| sztorno | FR-7 | Rendszer értesíti a pénzügyi vezetőt az engedélykérelemről | MISSING | `requestApproval():202` csak `StornoApproval` rekordot ment + `log.info`, nincs notification | aktív értesítés (notification/push) a jóváhagyóhoz |
| sztorno | FR-8 | Pénzügyi vezető jóváhagy/elutasít; elutasítás → blokk | PARTIAL | `StornoService.approve():237` APPROVED/REJECTED státusz | nincs "elutasítás után minden további sztornó blokkolt engedélyezésig" globális gate (NFR-3); elutasítás csak az adott kérelmet zárja |
| sztorno | FR-9 | Eredeti árf. ellenőrzés + aktuális árfolyamok megjelenítése | IMPLEMENTED | `StornoService.doCheckStorno():156-184` `findLatestRate`, `originalRate`/`currentRate`/`rateDifference`/`rateChanged` | — |
| sztorno | FR-10 | Árfolyam-különbség rögzítése | PARTIAL | `StornoCheckResultDto` visszaadja `rateDifference`-t (`:194`) | a különbség nem perzisztálódik a sztornó-tranzakcióra (reversal mindig eredeti rate-tel mentődik) |
| sztorno | FR-11 | Felhasználó figyelmeztetése árf.-eltérésről + aktuális árfolyamú újraszámítás | PARTIAL | `checkStorno` `rateChanged` flaget ad; `StornoPage.tsx:340` `customRate` input | StornoPage NEM jeleníti meg a `rateChanged`/`currentRate`/`rateDifference` mezőket, és nem számol automatikusan újra — manuális mezőre hagyatkozik |
| sztorno | FR-12 | Eltérő árf.-nál visszatérítés az ÚJ árfolyamon | MISSING | `TransactionReversalService:109-114` explicit: "az executeReversal MINDIG az EREDETI árfolyammal sztornóz"; `customExchangeRate` a request-ben nem érvényesül | a `customExchangeRate`/`useCurrentRate` nincs bekötve a kassza-/összeg-számításba |
| sztorno | FR-13 | Visszatérítés készpénz v. kártya (POS-ban is) | PARTIAL | `StornoPage.tsx:351` paymentMethod select; POS reversal `TransactionReversalService:91-104` | a `paymentMethodDid` a request-ben átmegy, de a reversal a `original.getPaymentMethod()`-ot örökli (`:138`), a kiválasztott mód nem felülír |
| sztorno | FR-14 | POS kártyás visszahívás eredeti adatokkal | IMPLEMENTED | `TransactionReversalService:91-104` `posTerminalService.initiateReversal(originalPosRef, terminalId)` | — |
| sztorno | FR-15 | POS sztornó eredeti v. eltérő árf. szerint | PARTIAL | `executePosStorno`/`executeOtpTerminalStorno` eredeti árf.-on | eltérő-árfolyamú ág hiányzik (lásd FR-12) |
| sztorno | FR-16 | Sztornó bizonylat: eredeti adatok + sztornó idő + alkalmazott árf. (ha eltér) + különbség | PARTIAL | `ReceiptGeneratorService:106-121` sztornó bizonylat; `EscPosReceiptService.generateStornoReceipt():141` | nincs "alkalmazott árfolyam ha eltér" + "árfolyam-különbség" blokk a bizonylaton (mert FR-12 hiányzik) |
| sztorno | FR-17 | Sztornó bizonylat nyomtatás a pontos visszatérítéssel | IMPLEMENTED | `ReceiptGeneratorService:179` `generateStornoReceipt` route; ESC/POS nyomtatás | — |
| sztorno | FR-18 | Sztornó bizonylat sorszám-archiválás | IMPLEMENTED | `receiptSequenceService.generateReversalReceiptNumber():117` az eredeti típus számlálójából | — |

## b2-zaras-ablak.md (23 FR)

| Spec | FR-ID | Követelmény | Státusz | Bizonyíték | Hiány |
|---|---|---|---|---|---|
| zaras-ablak | FR-1 | Korábbi zárások megtekintése | PARTIAL | `MonthlyClosingPage.tsx` havi lista; `DecadeReportPage.tsx` dekád lista | nincs egységes "Zárás Ablak" napi-zárás-történet nézet a wizardból |
| zaras-ablak | FR-2 | Bizonylatok újranyomtatása | MISSING | nincs reprint endpoint/UI (`reprint` grep: 0 találat zárás-bizonylatra) | zárás-bizonylat újranyomtatás funkció |
| zaras-ablak | FR-3 | "Zárás indítása" → típus-rákérdezés (napi/dekád/havi) → OK → wizard | PARTIAL | `CashierMainMenu:41` "Napi zárás" → `/closing/wizard`; `ClosingWizardPage.tsx:142` `start(...,'DAILY',...)` hardcode | nincs típusválasztó dialógus; a wizard mindig DAILY-t indít |
| zaras-ablak | FR-4 | Dekád-rákérdezés a 10. nyitvatartási napon | MISSING | nincs nyitvatartási-nap-számláló/trigger (spec TBD-4 is) | dekád-esedékesség automatikus rákérdezés |
| zaras-ablak | FR-5 | Havi-rákérdezés a hónap utolsó nyitvatartási napján | MISSING | nincs ilyen trigger | havi-esedékesség automatikus rákérdezés |
| zaras-ablak | FR-6 | Wizard 1. képernyő: tájékoztatás + típusválasztó (Napi/POS/Dekád/Havi) | MISSING | `ClosingWizardPage.tsx` egyből futtatja a DAILY lépéseket | típusválasztó képernyő |
| zaras-ablak | FR-7 | Lépés 1: napi tranzakció-összesítés devizanemenként + jóváhagyás | PARTIAL | `ClosingWizardSteps:94` STEP_DAILY_TRANSACTION_SUMMARY (backend); a UI `ClosingWizardPage` címletezés-fókuszú lépéseket mutat | a frontend wizard NEM jeleníti meg a devizanemenkénti összesítést jóváhagyásra |
| zaras-ablak | FR-8 | Lépés 2: nyitó/zárókészlet devizanemenként + véglegesítés | PARTIAL | backend `STEP_CASH_BALANCE_CHECK:99`; `EveningClosingPage.tsx:148` készletblokk | a wizard UI csak HUF-címletezést kér, nincs devizanemenkénti nyitó/záró kézi ellenőrzés |
| zaras-ablak | FR-9 | Lépés 3: kezelési költségek összesítése | PARTIAL | backend `STEP_HANDLING_FEES_SUMMARY:104` | a `ClosingWizardPage` UI-n nincs dedikált kezelésiköltség-összesítő lépés |
| zaras-ablak | FR-10 | Lépés 4: pénztárak közti mozgások összesítése | PARTIAL | backend `STEP_INTER_BRANCH_MOVEMENTS:109` | nincs frontend megjelenítés a wizardban |
| zaras-ablak | FR-11 | Lépés 5: aznap használt árfolyamok megjelenítése | PARTIAL | backend `STEP_DAILY_EXCHANGE_RATE_CHECK:114` | nincs frontend árfolyam-megjelenítő lépés |
| zaras-ablak | FR-12 | Lépés 6 (dekád/havi): dekád tranzakció + készlet összesítés | PARTIAL | `DecadeReportService`/`DecadeReportPage.tsx` külön oldalon | nincs a wizardba integrált dekád/havi lépéssor |
| zaras-ablak | FR-13 | Lépés 7 (dekád/havi): eltérés (többlet/hiány) + magyarázat | PARTIAL | backend `STEP_DECADE_DISCREPANCY_HANDLING:124`; `DecadeReportPage` `forintControlDiff` | nincs eltérés-magyarázat-beviteli UI |
| zaras-ablak | FR-14 | Lépés 8 (dekád/havi): korrekciós bizonylatok megtekintése | PARTIAL | backend `STEP_DECADE_CORRECTION_RECEIPTS:129` | nincs korrekciós-bizonylat megjelenítő UI |
| zaras-ablak | FR-15 | Lépés 9 (POS): kártyás tranzakciók összesítése | PARTIAL | backend `STEP_POS_CARD_TRANSACTION_SUMMARY:134` | nincs POS-zárás frontend wizard-ág |
| zaras-ablak | FR-16 | Lépés 10 (POS): visszatérítések/sztornók összesítése | PARTIAL | backend `STEP_POS_REFUNDS_STORNOS:139` | nincs frontend POS-lépés |
| zaras-ablak | FR-17 | Lépés 11 (POS): kezelési költség + tranzakciós díjak | PARTIAL | backend `STEP_POS_HANDLING_FEES:144` | nincs frontend POS-lépés |
| zaras-ablak | FR-18 | Lépés 12: zárási bizonylatok többpéldányos nyomtatás (választható) | PARTIAL | backend `STEP_PRINT_CLOSING_RECEIPTS:149`; `DailyClosingPdfService` | nincs többpéldányos / bizonylat-választó UI |
| zaras-ablak | FR-19 | Lépés 13: napi forint átadás-átvételi bizonylatok folyamatos sorszámmal | PARTIAL | backend `STEP_PRINT_HUF_TRANSFER_RECEIPTS:154` (FF/UF) | nincs wizard-lépés a forint-átadás bizonylat nyomtatáshoz |
| zaras-ablak | FR-20 | Lépés 14: napi jelentés automatikus küldés beállítása a központba | PARTIAL | backend `STEP_SEND_DAILY_REPORTS:159`; `EveningClosingPage` `send()` | nincs "automatikus küldés beállítása" (toggle/ütemezés), csak manuális küldés |
| zaras-ablak | FR-21 | Lépés 15: dekád/havi jelentés automatikus küldés beállítása | PARTIAL | backend `STEP_SEND_PERIOD_REPORTS_FINALIZE:164` | nincs beállítható auto-küldés |
| zaras-ablak | FR-22 | Lépés 16: véglegesítés "Megerősítés" → lezárás + végleges jelentés | IMPLEMENTED | `ClosingWizardPage.tsx:200` `finalize()`; backend `STEP_SEND_PERIOD_REPORTS_FINALIZE` | — |
| zaras-ablak | FR-23 | Minden lépésen "Tovább"/"Vissza" navigáció | PARTIAL | `closingWizardApi.navigate():703` támogat tetszőleges targetStep-et | a frontend `ClosingWizardPage` lineárisan, automatikusan fut (step1→denom→2-9), nincs kézi Tovább/Vissza |

## b2-zaras-kepernyok-bizonylatok.md (30 FR)

| Spec | FR-ID | Követelmény | Státusz | Bizonyíték | Hiány |
|---|---|---|---|---|---|
| zaras-kepernyok | FR-1 | Címletezés–Zárások menü (5 gomb) | PARTIAL | `ClosingWizardPage` címletezés-lépések; `DenominationPage.tsx` | nincs a forrásképnek megfelelő menü (Különféle/Kinyomtatás/napi/havi/Mégsem) |
| zaras-kepernyok | FR-2 | "Címletezés" almenü 5 típus (esti/kez.díj/WU/ÁFA/e-keresk.) | PARTIAL | `ClosingWizardPage:37-45` step-labelek (Esti/Kez.díj/WU/ÁFA/Foglaló/E-keresk.) | nincs interaktív almenü-választó; csak automatikus step-lánc |
| zaras-kepernyok | FR-3 | "Címletek kinyomtatása" checkbox-választó alap-bejelölésekkel | MISSING | nincs ilyen választó UI | címletnyomtatás-választó dialógus |
| zaras-kepernyok | FR-4 | NAV-os forint fiókérték ≠ címletezés → piros figyelmeztetés + kötelező megjegyzés + "E-mail küldése és mehet tovább" | PARTIAL | `NavClosingDiscrepancyService.validateNavClosingAmount():63` + `approveDiscrepancy():109` (min 20 kar. indok + notification); endpoint `NavClosingController:141,159` | nincs frontend gate-UI a zárás-wizardban (piros figyelmeztetés + megjegyzés + e-mail gomb); a `closing-wizard` nem hívja a NAV-validációt |
| zaras-kepernyok | FR-5 | Dekádzárás dialógus (év/hó/dekád + Nyomtatás/Mégsem) | PARTIAL | `DecadeReportPage.tsx:146-166` év + dekád választó + generálás | nincs hónap-választó, és nincs "Nyomtatás" gomb (csak generál/lezár) |
| zaras-kepernyok | FR-6 | Napi összefoglaló (X) fejléc: dátum + fiók | PARTIAL | `EveningClosingPage:114` branchName+date | nincs dedikált "Napi összefoglaló (X)" képernyő |
| zaras-kepernyok | FR-7 | "Összesen záró készlet F9": Forint/Valuta/Összesen | MISSING | nincs F9-es záró-készlet összesítő (Forint/Valuta/Összesen bontás) | Napi összefoglaló F9 blokk |
| zaras-kepernyok | FR-8 | Pillanatnyi pénztárállás: DNEM/KÉSZLET/VÉTEL/ELADÁS | MISSING | nincs ilyen tábla | pillanatnyi-pénztárállás blokk |
| zaras-kepernyok | FR-9 | Napi forgalom Vétel/Eladás de/du + Összesen | MISSING | `EveningClosingPage` totalBuy/Sell összeg, de nincs de/du bontás | de/du forgalmi bontás |
| zaras-kepernyok | FR-10 | Forint címlet darabszám (20000…5) + euró érme | PARTIAL | `ClosingWizardPage:11` HUF_DENOMINATIONS 20000…5 | nincs euró-érme készlet blokk a napi összefoglalón |
| zaras-kepernyok | FR-11 | Egyedi árfolyamok blokk (Val./Összeg/ÁRF/Bizonylat) | MISSING | nincs egyedi-árfolyam összefoglaló blokk a zárásban | — |
| zaras-kepernyok | FR-12 | KÜLDÖK/KÉREK panelek a zárás képernyőn | MISSING | mozgások külön modulban (transfer), nincs a zárás-összefoglalón | KÜLDÖK/KÉREK panel |
| zaras-kepernyok | FR-13 | WU záró (HUF/USD), ÁFA innova (HUF), Kezelésidíj, E-keresk. | PARTIAL | `DailyClosingArchiveService` snapshot WU_USD/WU_HUF/WU_VAT/HANDLING_FEE/ECOMMERCE (`:284-287,65-69`) | nincs frontend megjelenítés a napi összefoglalón |
| zaras-kepernyok | FR-14 | Jelentés beküldése / "Most nem küldöm be" választás | PARTIAL | `EveningClosingPage` send gomb | nincs "Most nem küldöm be" explicit választó |
| zaras-kepernyok | FR-15 | Délelőtti/délutáni pénztáros (Ptáros de/du) rögzítés | MISSING | nincs de/du pénztáros rögzítés | — |
| zaras-kepernyok | FR-16 | Értéktári zárás-előtti checklist (tételek + dátum + pénztáros) | PARTIAL | `DailyChecklistService:45-84` 19 tétel, de ezek NYITÁSI checklist (pénztárgép-indítás, AML, WU stb.) | hiányzik az ÉRTÉKTÁRI ZÁRÁS-előtti checklist a forrásképnek megfelelő tételekkel |
| zaras-kepernyok | FR-17 | Checklist: "Minden pénztár készlete feltöltve (címletek, fém euró)" | MISSING | a 19 tétel közt nincs (lásd FR-16) | értéktári checklist-tétel |
| zaras-kepernyok | FR-18..25 | Értéktári checklist eseti tételei (átadólap, grafikon, konkurencia, próbaváltás, TRB, ügyfélkártya, hóvégi egyeztetés stb.) | MISSING | nincs ilyen tétel a `DailyChecklistService.DEFAULT_ITEMS`-ben | teljes értéktári checklist tételkészlet |
| zaras-kepernyok | FR-26 | Zárást ellenőrző személy dialógus (NÉV+BEOSZTÁS, "rendben"/"Mégsem", zárószalag aláírás) | MISSING | `reviewer`/`verifyingPerson`/`ellenőrző személy` grep: 0 backend találat | kétszemélyes zárás-kontroll entitás/UI (NFR-2) |
| zaras-kepernyok | FR-27 | Nyomtatott napi zárás bizonylat (teljes blokkstruktúra + nyilatkozat + aláírás) | PARTIAL | `DailyClosingPdfService`; `EscPosReceiptService` napi blokkok | nem ellenőrizve teljes blokk-paritás (forgalom I-II., nyilatkozat-szöveg, penztaros aláírás-mező) |
| zaras-kepernyok | FR-28 | Nyomtatott havi zárás bizonylat (nyitó/növ/csökk/záró, WU, ÁFA, ügyfélforgalom) | PARTIAL | havi closing létezik (`MonthlyClosingPage`/backend) | havi zárás PDF teljes blokk-struktúra nem verifikált |
| zaras-kepernyok | FR-29 | Nyomtatott dekádzárás bizonylat (Sor/Np/Bizony./Ft.átvétel/átadás stb.) | IMPLEMENTED | `EscPosReceiptService.printDekad...():506-521` "HAVI n. DEKÁDZÁRÁS" + "Sor Np Bizony. Ft.átvétel Ft.átadás" + "Dekád forgalom" | — |
| zaras-kepernyok | FR-30 | Nyomtatott értéktári zárás bizonylat (checklista + bankjegy-forgalom I-II. + mozgások + WU) | PARTIAL | `EscPosReceiptService:329-360` `Értéktári zárás` bizonylat + checklista-blokk | a bizonylat checklist-tételeket vár paraméterként, de FR-16 értéktári checklist nincs → forrás üres |

---

## VALÓS GAP-EK (prioritással, implementálható)

### P0 — Üzletileg kritikus hiányok

1. **Sztornó eltérő árfolyamon (FR-12/FR-10/FR-16) — a custom rate nem érvényesül.**
   `TransactionReversalService.java:109-114` explicit kommentben rögzíti:
   *„Az executeReversal mindig az EREDETI árfolyammal sztornóz (biztonságos default).”*
   A `StornoPage.tsx:340` `customRate` inputot és a `StornoRequest.customExchangeRate` mezőt a backend **eldobja** — a reversal a `original.getExchangeRate()`-tel mentődik (`:132`). A spec 3. szakasza viszont aktuális-árfolyamú visszatérítést + különbség-rögzítést + bizonylaton-megjelenítést követel. Gap: a `customExchangeRate`/`useCurrentRate` bekötése a HUF-újraszámításba, a `rateDifference` perzisztálása a tranzakcióra, és a sztornó-bizonylatra (`generateStornoReceipt`).

2. **NAV-fiókérték / címletezés-eltérés gate hiányzik a zárás-wizardból (zaras-kepernyok FR-4, NFR-1).**
   Backend kész: `NavClosingDiscrepancyService.validateNavClosingAmount` + `approveDiscrepancy` (min 20 kar. indok + `notificationService.sendToBranch`), endpoint `NavClosingController:141/159`. De a `ClosingWizardPage.tsx` **sehol nem hívja** ezeket, és nincs frontend piros-figyelmeztetés + kötelező megjegyzés + „E-mail küldése és mehet tovább a zárás” gate. Production-ban a NAV-eltérés így csendben átmegy.

3. **Sztornó engedélykérelem-értesítés (FR-7) hiányzik.**
   `StornoService.requestApproval():202` csak `StornoApproval` rekordot ment + `log.info` — nincs aktív értesítés a pénzügyi vezetőhöz (vö. NAV-flow `notificationService.sendToBranch`-csel, ami megvan). Egyszerű bekötés: `notificationService` hívás a `requestApproval`-ban.

### P1 — Funkcionális hiányosságok

4. **Zárás-típusválasztó hiányzik (zaras-ablak FR-3/FR-6).**
   `ClosingWizardPage.tsx:142` hardcode `start(...,'DAILY',...)`. A backend (`ClosingWizardSteps`) támogatja a DAILY/DECADE/MONTHLY/POS típusokat és típus-feltételes lépéseket, de a frontend nem ad típusválasztót, mindig napit indít. A dekád/havi/POS wizard-ágak frontend-oldalon nincsenek bekötve (FR-12..FR-17 mind PARTIAL backend-only).

5. **Kétszemélyes zárás-kontroll / „zárást ellenőrző személy” (FR-26, NFR-2) teljesen hiányzik.**
   `reviewer`/`verifyingPerson` grep: 0 backend találat. Az értéktári zárás véglegesítéséhez név+beosztás kötelező lenne, ehhez sem entitás, sem UI nincs.

6. **Bizonylat-újranyomtatás (zaras-ablak FR-2) hiányzik.**
   Nincs reprint endpoint/UI zárás-bizonylatra (`ReceiptSearchService` tranzakció-bizonylatra van, zárásra nem).

7. **Értéktári zárás-előtti checklist (FR-16..FR-25) rossz tartalommal.**
   `DailyChecklistService.DEFAULT_ITEMS` 19 tétele NYITÁSI checklist (pénztárgép-indítás, AML-frissítés). A spec az értéktári ZÁRÁS-előtti checklistet kéri (átadólap, grafikon, konkurencia, TRB-tábla, hóvégi egyeztetés…). Az `EscPosReceiptService:329` értéktári-zárás bizonylat checklist-paramétert vár, de nincs hozzá forrás-adat.

### P2 — UI/megjelenítési hiányok (backend kész, frontend nem)

8. **Wizard kézi Tovább/Vissza (FR-23) + lépésenkénti megjelenítés (FR-7..FR-11).** `closingWizardApi.navigate` támogat tetszőleges step-et, de a `ClosingWizardPage` lineárisan, automatikusan fut; a devizanemenkénti összesítés / nyitó-záró / kezelésiköltség / mozgások / árfolyamok lépések nem jelennek meg.
9. **„Napi összefoglaló (X)” képernyő blokkjai (FR-7..FR-13) hiányoznak:** F9 záró-készlet (Forint/Valuta/Összesen), pillanatnyi pénztárállás (DNEM/KÉSZLET/VÉTEL/ELADÁS), de/du forgalmi bontás, egyedi-árfolyam blokk, KÜLDÖK/KÉREK panel, ptáros de/du.
10. **Dekádzárás-dialógus paritás (FR-5):** `DecadeReportPage` év+dekád választ, de hiányzik a hónap-választó és a „Nyomtatás” gomb.

### Korrekt (NEM gap)
- POS kártya-visszahívás (FR-14), napi sztornó-számláló (FR-5/FR-6), sztornó bizonylat sorszám (FR-18), dekádzárás-bizonylat struktúra (FR-29), véglegesítés (FR-22) — IMPLEMENTED.
- A spec TBD-1 (NAV pénztárgép sztornó-protokoll, FR-4) valódi külső függőség, üzleti tisztázást igényel, nem tiszta kód-gap.
