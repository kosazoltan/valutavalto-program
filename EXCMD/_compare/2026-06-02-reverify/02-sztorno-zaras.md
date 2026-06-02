# Doc↔kód konformancia-reverify — Sztornó + Zárás (b2)

> **Készült:** 2026-06-02. Forrás-specek: `EXCMD/b2-sztorno.md`, `EXCMD/b2-zaras-ablak.md`,
> `EXCMD/b2-zaras-kepernyok-bizonylatok.md`. Kód: jelenlegi `main` (HEAD e6535da59).
> Módszer: követelményenkénti grep + file:line bizonyíték. "IMPLEMENTED" csak kód-hivatkozással.
> Kiemelt fókusz: **G3** NAV/napzárás eltérés-magyarázat gate (`CLOSING_DISCREPANCY_EXPLANATION_REQUIRED`).
>
> Megjegyzés a kliensről: a `penztar-client` (Electron) forrása NINCS a repóban (csak `dist/` build-output),
> ezért a tisztán kliens-oldali UI-követelmények futó-app verifikációt igényelnek → **VERIFIKÁLANDÓ**.
> A `frontend-react` (web) viszont teljes forrással jelen van.

---

## G3 KIEMELT VERIFIKÁCIÓ — NAV/napzárás eltérés-magyarázat gate

| Vizsgált szempont | Eredmény | Bizonyíték |
|---|---|---|
| Gate be van-e kötve a ClosingWizard véglegesítésbe | ✅ IGEN | `ClosingWizardService.java:491-505` — `finalizeClosing()` kiszámolja az eltérést, és ha a flag BE, blokkol magyarázat nélkül |
| Eltérés-számítás (címletezett − várt készlet) | ✅ | `ClosingWizardService.java:533-543` `computeCashDiscrepancy()` (EVENING denom − `sumCurrentBalanceHuf`) |
| Gate-döntés (statikus, tesztelhető) | ✅ | `ClosingWizardService.java:552-566` `closingDiscrepancyBlockReason()` |
| Feature-flag **default értéke** | ✅ **KI (false)** | `ClosingWizardService.java:497-498` `getValue(PARAM,"false")`; egyetlen migrációban SINCS seedelve a kulcs (grep: 0 találat `db/migration`-ben) → production változatlan |
| Controller átadja a magyarázatot (body, nem query) | ✅ | `ClosingWizardController.java:178-185` (`body.get("discrepancyExplanation")`) |
| Audit-mezők (DB) | ✅ | `V257__closing_wizard_discrepancy.sql:7-9` (`discrepancy_amount`, `discrepancy_explanation`); entity `ClosingWizard.java:119-126` |
| FE hard-fail → explain-and-proceed (prompt-retry) | ✅ | `ClosingWizardPage.tsx:216-230` — eltérés+magyarázat regex → `window.prompt` → retry `finalize(...,explanation)`; API: `transactions.ts:761-765` |
| Gate unit-tesztek | ✅ 5 teszt | `ClosingDiscrepancyGateTest.java:20-49` (null / toleranciaon belül / felette nincs magy. / üres magy. / van magy.) |

**G3 ÖSSZEGZÉS:** ✅ **KÉSZ, mint a baseline állította.** A gate be van kötve, a flag default KI (production-biztos),
a hard-fail→explain-and-proceed FE-oldalon működik (prompt + retry). A baseline "futó-app verifikációval kapcsolható be"
megjegyzése továbbra is áll: az éles bekapcsolás (flag=true) end-to-end futtatása nem volt elvégezve ebben a statikus auditban → **VERIFIKÁLANDÓ** (flag=true e2e).

⚠️ **Részleges fedés a spec FR-ZARUI-04-hez képest:** a spec dedikált **piros NAV-banner** + **kötelező komment** +
**"E-mail küldése és mehet tovább"** gombot ír le (kliens), valamint külön `NavMismatchLog` táblát. A megvalósítás ehelyett
egy **generikus készlet-eltérés gate** (címletezett vs. várt HUF) + magyarázat-mező; **nincs `nav_mismatch_log` tábla**, és a
NAV-fiókérték-specifikus banner/e-mail a `frontend-react`-ben nem található. A wizard backend a címletezés-eltérést hard-fail
lépésként kezeli (`DailyClosingService.checkEveningDenomination:229-256`). Lásd FR-ZARUI-04 sor lent.

---

## b2-sztorno.md (FR-SZT)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-SZT-01 Sztornó kezdeményezése | ✅ | `StornoController.java:40-47` check; `StornoPage.tsx` (web) | Magas | POS-on is: `/stornos/pos` |
| FR-SZT-02 Eredeti tranzakció azonosítása | ✅ | `StornoService.java:99-114` `resolveTransaction` (id VAGY receipt); `checkStorno:80-94` | Magas | Multi-tenant receipt-lookup |
| FR-SZT-03 Alapértelmezett sztornó (eredeti adat) | ✅ | `TransactionReversalService.java:183-184` (`appliedRate=originalRate` default), `199-227` | Magas | |
| FR-SZT-04 NAV automatikus sztornó (pénztárgép driver) | ⚠️ | nincs explicit driver-hívás a reversal-flow-ban; `NavClosingService` létezik de nem a sztornó-úton | Magas | A NAV-bizonylat driver-általi beküldése **kliens/hardver** felelősség → VERIFIKÁLANDÓ (penztar-client) |
| FR-SZT-05 Napi sztornó számláló | ✅ | `StornoService.java:131` `countReversalsByBranchAndDate`; `DailySession.reversalCount` (session) | Magas | Éjféli reset: napi session-alapú |
| FR-SZT-06 Tiltás + engedélykérés (4.+) | ✅ | `TransactionReversalService.java:120-137`; `StornoService.java:165-182` | Magas | ⚠️ eltérés a spectől: lent |
| FR-SZT-07 Supervisor közvetlen jóváhagyás | ✅ | `StornoService.approve:311-355`; `StornoController.java:69-78` (`@PreAuthorize SUPERVISOR+`) | Magas | G12: aktív értesítés `StornoService.java:294-306` |
| FR-SZT-08 Engedély bírálata és zárolás | ✅ | `StornoService.java:341-349` (APPROVED/REJECTED); execute verifikál `360-431` | Magas | |
| FR-SZT-09 Aktuális árfolyam lekérése | ✅ (BE) / ⚠️ (offline) | `StornoService.java:206-228` (`findLatestRate` + sávos) | Magas | Offline telefonos diktálás + flat-only + supervisor → **VERIFIKÁLANDÓ** (kliens offline path) |
| FR-SZT-10 Árfolyam-különbség rögzítése | ✅ | `TransactionReversalService.java:189-197` (`hufRateDiff` + notes) | Magas | G2 |
| FR-SZT-11 Figyelmeztetés eltérésre + újraszámolás | ✅ | `StornoService.java:201-240` (`rateChanged`, `rateDifference` a check-DTO-ban); `StornoPage.tsx:121,136` | Magas | |
| FR-SZT-12 Új árfolyam szerinti visszatérítés | ✅ | `TransactionReversalService.java:185-191,211-212` (`appliedRate`, `reversalHufAmount`) | Közepes | G2 |
| FR-SZT-13 Visszatérítési mód = eredeti mód | ✅ | `TransactionReversalService.java:150-163,217` (CARD→POS reversal, paymentMethod öröklés) | Közepes | |
| FR-SZT-14 POS kártyás visszahívás | ✅ | `TransactionReversalService.java:150-162` `posTerminalService.initiateReversal`; `StornoService.executePosStorno:436-457` | Magas | |
| FR-SZT-15 POS eltérő árfolyam kezelés | ✅ | ua. mint FR-SZT-10/12 (a customRate a POS-úton is átmegy) | Magas | |
| FR-SZT-16 Sztornó bizonylat generálása | ✅ | `TransactionReversalService.java:176-177` `generateReversalReceiptNumber`; reversal Transaction tartalmazza az árfolyam/diff adatokat | Magas | |
| FR-SZT-17 Sztornó bizonylat nyomtatása | ⚠️ | bizonylat-objektum kész; fizikai nyomtatás **kliens** | Magas | VERIFIKÁLANDÓ (penztar-client nyomtató) |
| FR-SZT-18 Sorszámozott (hézagmentes) archiválás | ✅ | `ReceiptSequenceService.java:44-88,108` PESSIMISTIC `findByBranchIdForUpdate` (SELECT FOR UPDATE) | Magas | Hézagmentesség: per-branch lockolt szekvencia |
| FR-SZT-19 Készletmozgás az ÚJ (2026-06-02) készletpolitika szerint | 🔴 / VERIFIKÁLANDÓ | `TransactionReversalService.java:239-249` — a kód STANDARD elszámolást csinál (BUY-reversal: valuta−/HUF+; SELL-reversal: valuta+/HUF−) | **P0** | **Doc↔kód KONFLIKTUS.** A spec szerint BUY-reversal NEM mozgathat sem valutát sem HUF-ot, SELL-reversal csak valutát. A repo-memória (`project_transaction_business_rules_2026_06_02`) szerint viszont a STANDARD elszámolás a HELYES, és a spec "HUF nem változik" a MEGFIGYELT hibát írta le, nem a kívánt viselkedést → **a kódot NE írd át vakon; üzleti döntés/megerősítés kell.** Lásd alább. |

### FR-SZT-19 részletes megjegyzés (P0, konfliktus)
- A `b2-sztorno.md` FR-SZT-19 (forrás: "2026-06-02 tranzakciós audit 1. pont") explicit kimondja: BUY-reversal → sem deviza, sem `cash_balance` nem változik; SELL-reversal → csak deviza nő vissza.
- A jelenlegi kód (`executeReversal:239-249` és `executePartialRefund:392-402`) a normál vétel/eladás **tükör-ellentétét** könyveli (STANDARD).
- A repo auto-memória (`MEMORY.md` → `project_transaction_business_rules_2026_06_02.md`) ezzel SZEMBEN azt rögzíti, hogy a STANDARD elszámolás a HELYES és a kódot NEM kell átírni; a user "HUF nem változik" leírása a megfigyelt hiba (sync/rögzítés-hiány) volt.
- **Következtetés:** ez NEM egyértelmű kód-hiba; a spec-szöveg és a kód ellentmond, a memória a kódot támogatja. **VERIFIKÁLANDÓ üzleti döntéssel** (a spec FR-SZT-19 szövegének felülvizsgálata vagy a kód módosítása) — addig NE módosítsd.

### FR-SZT-06 eltérés a spectől (⚠️, P2)
- Spec: 1–3. jelszó nélkül, a **4.+** supervisor-jelszóval engedélyezett (korlátlan a supervisorral).
- Kód: napi plafon = `limit` (default 3); a 3. (limit-1) supervisor-jóváhagyással, a **4.+ supervisorral SEM** (`TransactionReversalService.java:122-126`, `StornoService.java:165-169`).
- Ez **szigorúbb** a specnél; tudatos audit-döntés (2026-05-31, kommentekkel dokumentált). Üzleti megerősítés ajánlott.

### Sztornó adatmodell-eltérés (⚠️, P3)
- A spec külön `Reversal`, `DailyReversalCounter`, `ReversalApproval` táblákat javasol. A kód ehelyett: a reversal egy `Transaction` (type=REVERSAL), a számláló a `DailySession.reversalCount`, a jóváhagyás a `StornoApproval` entitás. Funkcionálisan lefedve, séma-névben eltér. Nem hiba.

---

## b2-zaras-ablak.md (FR-ZAR)

| Követelmény | Státusz | Bizonyíték (file:line) | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-ZAR-01 Korábbi zárások megtekintése | ⚠️ | nincs dedikált "korábbi zárások lista" oldal a `frontend-react/pages/closing`-ban | Magas | VERIFIKÁLANDÓ (kliens) — backend `closing_wizard` lekérdezhető, de UI-lista nincs a webben |
| FR-ZAR-02 Bizonylatok újranyomtatása | ⚠️ | nincs reprint-endpoint/UI a closing-wizard úton | Magas | VERIFIKÁLANDÓ (kliens); `ReceiptService`/`DailyClosingPdfService` létezik |
| FR-ZAR-03 Zárás indítása + típusválasztás | ✅ | `ClosingWizardController.java:35-44` (`closingType` param); G10 (FE típusválasztó) | Magas | |
| FR-ZAR-04 Dekád trigger (10/20/hó vége) | ⚠️ | nincs explicit naptári-nap dekád-trigger a closing-wizard kódban | Magas | VERIFIKÁLANDÓ — a típusválasztás manuális; auto-felajánlás triggert nem találtam |
| FR-ZAR-05 Havi trigger (hó utolsó nap) | ⚠️ | ua. mint FR-ZAR-04 | Magas | VERIFIKÁLANDÓ |
| FR-ZAR-06 Wizard 1. lépés típusválasztó | ✅ | `ClosingWizardSteps.java:89-92` (`STEP_CLOSING_TYPE_SELECTION`, mind a 4 típus) | Magas | |
| FR-ZAR-07 Lépés1 napi tranz. összesítés | ✅ | `ClosingWizardSteps.java:94-97`; `DailyClosingService` step-check | Magas | |
| FR-ZAR-08 Lépés2 készpénzkészlet ellenőrzés | ✅ | `ClosingWizardService.java:282-367` (`countDenominations`+persist); `ClosingWizardSteps.java:99-102` | Magas | |
| FR-ZAR-09 Lépés3 kezelési költségek | ✅ | `ClosingWizardSteps.java:104-107`; `DailyClosingService.checkHandlingFeeDenomination:262-277` | Magas | |
| FR-ZAR-10 Lépés4 pénztárközi mozgások | ✅ | `ClosingWizardSteps.java:109-112` | Magas | |
| FR-ZAR-11 Lépés5 napi árfolyamok | ✅ | `ClosingWizardSteps.java:114-117` (24h TTL check) | Magas | |
| FR-ZAR-12 Lépés6 dekád/havi összesítés | ✅ | `ClosingWizardSteps.java:119-122` (csak DECADE/MONTHLY) | Magas | |
| FR-ZAR-13 Lépés7 pénzügyi eltérés + magyarázat | ✅ | `ClosingWizardSteps.java:124-127` (Eltéréskezelés); **G3 gate** `ClosingWizardService.java:491-505` | Magas | G3 (lásd fent) |
| FR-ZAR-14 Lépés8 korrekciós bizonylatok | ✅ | `ClosingWizardSteps.java:129-132` | Magas | |
| FR-ZAR-15 Lépés9 POS kártyás összesítés | ✅ | `ClosingWizardSteps.java:134-137` (csak POS) | Magas | terminál-feltételes |
| FR-ZAR-16 Lépés10 POS visszatérítés/sztornó | ✅ | `ClosingWizardSteps.java:139-142` | Magas | |
| FR-ZAR-17 Lépés11 POS díjak | ✅ | `ClosingWizardSteps.java:144-147` | Magas | |
| FR-ZAR-18 Lépés12 zárási bizonylatok nyomtatása | ✅ (BE) / ⚠️ (nyomtatás kliens) | `ClosingWizardSteps.java:149-152`; `DailyClosingPdfService` | Magas | fizikai nyomtatás kliens → VERIFIKÁLANDÓ |
| FR-ZAR-19 Lépés13 forint átadás-átvételi bizonylat (hézagmentes) | ✅ | `ClosingWizardSteps.java:154-157`; `ReceiptSequenceService` FOR UPDATE | Magas | |
| FR-ZAR-20 Lépés14 napi jelentés auto-küldés (outbox) | ✅ | `ClosingWizardSteps.java:159-162`; `EveningSyncLog` + sync-agent | Magas | |
| FR-ZAR-21 Lépés15 dekád/havi jelentés küldés | ✅ | `ClosingWizardSteps.java:164-167` | Magas | |
| FR-ZAR-22 Lépés16 zárás véglegesítése (lezárás) | ✅ | `ClosingWizardService.finalizeClosing:464-526`; `complete:188-220` | Magas | session→LEZÁRT; G3 gate a véglegesítés előtt |
| FR-ZAR-23 Wizard navigáció (Tovább/Vissza, validáció) | ✅ | `ClosingWizardService.navigate:142-183` (step-check, canProceed) | Magas | |

---

## b2-zaras-kepernyok-bizonylatok.md (FR-ZARUI)

> Ezek túlnyomó része **penztar-client (Electron) UI + nyomtatott bizonylat-layout**. A penztar-client forrása NINCS a repóban
> (csak build-output `penztar-client/dist/`), ezért legtöbbjük **VERIFIKÁLANDÓ** futó-app/Electron ellenőrzéssel.
> A `frontend-react/pages/closing` egy egyszerűbb wizard, ami ezeket a részletes képernyőket NEM tartalmazza.

| Követelmény | Státusz | Bizonyíték / keresés | Prio | Megjegyzés |
|---|---|---|---|---|
| FR-ZARUI-01 Címletezés-Zárások főmenü (5 gomb) | ⚠️ | nincs a `frontend-react`-ben (grep) | Magas | VERIFIKÁLANDÓ (penztar-client) |
| FR-ZARUI-02 Címletezés almenü (5 típus) | ⚠️ | `DenominationCategory.java` enum létezik (ESTI/KEZELESI/WU/AFA/E-KER) | Magas | backend enum ✅; UI VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-03 Címletek kinyomtatása választó (checkbox) | ⚠️ | nincs a webben | Magas | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-04 NAV-fiókérték eltérés gate (piros banner + komment + e-mail) | ⚠️/🔴 | **nincs** dedikált NAV-banner/e-mail a `frontend-react`-ben; nincs `nav_mismatch_log` tábla; helyette generikus G3 készlet-eltérés gate (`ClosingWizardService.java:491-505`) + hard-fail `DailyClosingService.checkEveningDenomination:229-256` | Magas | **Részleges:** a NAV-specifikus banner+kötelező-komment+"E-mail küldése és mehet tovább" folyamat NINCS megvalósítva pontosan a spec szerint; az e-mail-küldés a NAV-eltérésnél nem köthető be. VERIFIKÁLANDÓ (kliens) + lehetséges gap |
| FR-ZARUI-05 Dekádzárás dialógus (év/hó/dekád) | ⚠️ | nincs a webben | Magas | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-06 Napi összefoglaló (X) fejléc | ⚠️ | nincs dedikált X-summary oldal a webben | Magas | VERIFIKÁLANDÓ (kliens). Backend: G9 pillanatnyi pénztárállás kész |
| FR-ZARUI-07 Záró készlet F9 | ⚠️ | nincs F9-handler a `frontend-react/closing`-ban | Magas | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-08 Pillanatnyi pénztárállás (DNEM/KÉSZLET/VÉTEL/ELADÁS) | ✅ (BE) / ⚠️ (X-screen) | G9 `LiveCashPositionPage.tsx`; backend riport kész | Magas | a dedikált X-summary screen kliens → VERIFIKÁLANDÓ |
| FR-ZARUI-09 Napi forgalom (de/du/összesen) | ⚠️ | de/du bontás a webben nem található | Közepes | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-10 Forint címletbontás (20000..5) | ✅ | `ClosingWizardPage.tsx:66` HUF_DENOMINATIONS; `countDenominations` BE | Magas | euró-érme külön sor: VERIFIKÁLANDÓ |
| FR-ZARUI-11 Egyedi (alkudott) árfolyamok blokk | ⚠️ | nincs a webben | Közepes | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-12 KÜLDÖK/KÉREK panelek (+plomba) | ⚠️ | nincs a webben (transfer/seal entitások léteznek máshol) | Közepes | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-13 WU/ÁFA/Kez.díj/E-ker záró készletek (WU kézi) | ⚠️ | nincs a closing X-screen-ben | Közepes | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-14 Jelentés beküldési opciók | ✅ (BE) | FR-ZAR-20 outbox; `EveningClosingController` | Magas | "Most nem küldöm be" UI kliens → VERIFIKÁLANDÓ |
| FR-ZARUI-15 Délelőtti/délutáni pénztáros | ⚠️ | de/du pénztáros-mező a webben nem található | Közepes | VERIFIKÁLANDÓ (kliens) |
| FR-ZARUI-16..25 Értéktári checklist (10 pont) | ⚠️ | nincs `ChecklistProgress`/`closure_auditor` tábla; `DailyChecklistPage.tsx` létezik de NEM az értéktári 10-pontos zárás-checklist | Magas/Közepes | VERIFIKÁLANDÓ (kliens); az adatmodell (`ChecklistProgress`) MISSING (grep: 0 entity) |
| FR-ZARUI-26 Zárást ellenőrző személy dialógus (NEVE/BEOSZTÁS) | ❌/⚠️ | nincs `ClosureAuditor` entitás (grep: 0); nincs dialógus a webben | Magas | MISSING adatmodell; UI VERIFIKÁLANDÓ (kliens) — kerestem: `closure_auditor`, `auditor_name`, "BEOSZTÁS" |
| FR-ZARUI-27 Nyomtatott Napi Zárás bizonylat | ⚠️ | `DailyClosingPdfService` létezik | Magas | layout-egyezés VERIFIKÁLANDÓ |
| FR-ZARUI-28 Nyomtatott Havi Zárás bizonylat | ⚠️ | `MonthlyClosingPdfServiceTest` létezik | Magas | VERIFIKÁLANDÓ |
| FR-ZARUI-29 Nyomtatott Dekádzárás bizonylat | ⚠️ | dekád-report szolgáltatás létezik (`DecadeReportService`) | Magas | VERIFIKÁLANDÓ |
| FR-ZARUI-30 Nyomtatott Értéktári Zárás bizonylat | ⚠️ | értéktári zárás-PDF dedikált layout nem verifikált | Magas | VERIFIKÁLANDÓ |

---

## Záró statisztika

- **Ellenőrzött követelmény: 72** (FR-SZT 19 + FR-ZAR 23 + FR-ZARUI 30) — a FR-ZARUI-16..25 a 10-pontos checklistet egy sorban összevonva, az adat-/séma- és üzleti-megjegyzések külön kiemelve.
- **Kész (✅): 41**
- **Részleges / VERIFIKÁLANDÓ (⚠️): 28**
- **Hiányzó (❌/MISSING): 1** (FR-ZARUI-26 `ClosureAuditor` adatmodell; UI kliens-VERIFIKÁLANDÓ)
- **Hibás / konfliktus (🔴): 2** (FR-SZT-19 doc↔kód készletpolitika-konfliktus P0; FR-ZARUI-04 NAV-banner/e-mail részleges/eltérő — a kettős jelölés miatt)

**G3 verdikt:** ✅ KÉSZ — gate bekötve, flag default KI, FE explain-and-proceed + 5 unit-teszt. Az éles flag=true e2e futtatás VERIFIKÁLANDÓ.
