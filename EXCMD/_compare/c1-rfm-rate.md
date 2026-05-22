# C1 — RFM (Árfolyamkészítő) spec ↔ kód összevetés

Forrás-spec-ek: `b1-arfolyamkeszito-kovetelmenylista.md`, `b1-arfolyamkeszito-kepernyok.md`, `b3-bank-api.md`, `b3-arfolyam-karbantarto-hibalista.md`.
Kód: `frontend-react/src/pages/rates/` + `pages/ratemanagement/` (shared a 3 Electron klienssel), `backend/.../service/Rate*`, `Mnb*`, `Raiffeisen*`.
Módszer: trust-but-verify, minden FR konkrét kód-bizonyítékkal.

## b1 — Követelménylista (FR-RFM)

| spec | FR-ID | követelmény (rövid) | státusz | kód-bizonyíték | hiány |
|---|---|---|---|---|---|
| b1-köv | FR-RFM-01 | Munkalapok közti egyszerű átjárás | IMPLEMENTED | `MainRateSheetPage.tsx:888` CSOPORTOK gomb→`/rates/creation`; `RateCreationPage.tsx:419` FŐLAP gomb→`/rates/main` | — |
| b1-köv | FR-RFM-02 | A oszlop kézzel állítható, fő valuták kézi | IMPLEMENTED | `MainRateSheetPage.tsx:996-1002` settlement input mindig editable; legend `:1046` 4 főváluta kézi | — |
| b1-köv | FR-RFM-03 | A=OTP auto-másolás 10 valutánál | PARTIAL | `MainRateSheetPage.tsx:586-677` szerver-merge officialRate→A; B (otp) kézi `:1004` | Nincs automatikus B(OTP)→A másolás a 10 felsorolt valutára; A vagy szerverről jön vagy kézi/kereszt. A spec szerinti "OTP-ből A-ba" auto-copy hiányzik |
| b1-köv | FR-RFM-04 | EUR-bázis kereszt A számítás | IMPLEMENTED | `mainSheetRules.ts:23-32` computeCrossSettlement EUR; `MainRateSheetPage.tsx:73-81` crossBase:'EUR' CZK/PLN/RON/RSD/TRY/BAM | — |
| b1-köv | FR-RFM-05 | USD-bázis kereszt A számítás | PARTIAL | `mainSheetRules.ts:29` USD ág; `:77-87` ILS/UAH/RUB/CNY/THB/BRL/MXN/NZD crossBase:'USD' | RCH hiányzik (törölve v2.5.61); a többi USD-bázisú megvan |
| b1-köv | FR-RFM-06 | B (OTP) kézzel szerkeszthető 16 valutánál | PARTIAL | `MainRateSheetPage.tsx:1004` otp input minden soron editable | Nincs valutánkénti megszorítás a 16 felsorolt listára (mindenhol szerkeszthető — funkcionálisan elég, listakötés hiányzik) |
| b1-köv | FR-RFM-07 | C (segéd) szorzók | PARTIAL | `:1008` helper input editable + HyperFormula képlet (`:135`) | Cella szerkeszthető + képletezhető; "szorzók beállítása" dedikált logika nincs, általános képlet-motor fedi |
| b1-köv | FR-RFM-08 | D oszlop 28 valuta sorrend | PARTIAL | `MainRateSheetPage.tsx:65-88` DEFAULT_CURRENCIES | Csak **22** valuta (6 törölve: DKK,NOK,SEK,HRK,BGN,RCH `:61-64,92`). A spec 28-at ír. Üzleti döntés v2.5.61, de spec-eltérés |
| b1-köv | FR-RFM-09 | EUA: max 20% eltérés, képzés=gyenge EUR eladás×1.2, figyelmeztetés | MISSING | `:80` EUA sor létezik (crossBase:null), de **semmilyen 20%/×1.2 logika/warning** nincs sehol (grep EUA/0.2/1.2 → 0 találat) | A teljes EUA üzleti szabály (×1.2 képzés + >20% eltérés figyelmeztetés ügyfélnek) hiányzik |
| b1-köv | FR-RFM-10 | Új valuta felvétel/törlés + megerősítés/supervisor jelszó | PARTIAL | `CurrencyManagerModal.tsx` create/setActive + megerősítő-panel `:277`; backend `currency_audit_log` (V238) | Megerősítés van; **supervisori jelszó NINCS** (csak role-gate `MainRateSheetPage.tsx:166`). Törlés = inaktiválás (helyes Pmt.) |
| b1-köv | FR-RFM-11 | Gyenge multis E/F + E képletezhető | IMPLEMENTED | `:1016-1022` weakMultiBuy/Sell input; `FORMULA_COLUMNS :135` E,F képletezhető (HyperFormula) | — |
| b1-köv | FR-RFM-12 | Raiffeisen ±10% sáv, szabadon állítható | MISSING | Spread-gate létezik (`RateSpreadGate.java:21` MAX 5%, **nem** 10% és NEM állítható), kötve a publish-validációhoz nem a Főlap E/F számításhoz | A 10%-os Raiffeisen-sáv (középtől max 10% vétel/eladás) nincs; a meglévő gate fix 5%, hard-coded, más célú |
| b1-köv | FR-RFM-13 | 10% sáv elszámolóból VAGY OTP-ből, mód váltható | MISSING | nincs | Nincs forrás-mód-választó (elszámoló vs OTP) a sáv-számításhoz |
| b1-köv | FR-RFM-14 | Kereszt G/H oszlop 17 valutánál | PARTIAL | `:957-958` G/H fejléc; `:1024-1032` G számolt + H forrás input crossBase soroknál | G/H megvan a kereszt-valutákra, de EUA-ra/RCH-ra nincs (EUA crossBase:null, RCH törölve) |
| b1-köv | FR-RFM-15 | Csoportlap J/K oszlop | IMPLEMENTED | `RateCreationPage.tsx` RateGrid (J=officialRate, K=currency); backend `RateCreationService` overview | — |
| b1-köv | FR-RFM-16 | Alsó kedvezményhatár L/M | IMPLEMENTED | `RateCreationPage.tsx:98-103` limit1Buy/SellRate; `:519-534` Alsó határ input | — |
| b1-köv | FR-RFM-17 | Középső kedvezményhatár N/O | IMPLEMENTED | `:100-103` limit2; `:521` Középső | — |
| b1-köv | FR-RFM-18 | Felső kedvezményhatár P/Q | IMPLEMENTED | `:102-103` limit3; `:522` Felső | — |
| b1-köv | FR-RFM-19 | R/S saját hatáskör = P+kedvezmény (képlet) | MISSING | nincs R/S oszlop a RateGrid-ben; csak 3 limit-sáv (L–Q). Pénztáros custom-rate kvóta más mechanizmus | A csoportlap R/S "saját hatáskörű vét.max/elad.min" képletes (P+0,25) oszlop hiányzik |
| b1-köv | FR-RFM-20 | Pénztáros napi 5 kedvezmény limit | IMPLEMENTED | `TransactionService.java:1056-1064` getCashierCustomRateQuota limit default 5; `:1099` validateAndNormalizeCashierCustomRateQuota; `:238,426` enforce buy+sell | — |
| b1-köv | FR-RFM-21 | Csoporthoz tartozó irodák listája | IMPLEMENTED | `RateCreationPage.tsx:497-511` selectedWg.branches lista + remove/add | — |
| b1-köv | FR-RFM-22 | "Aktuális függvény" megjelenítés | MISSING | nincs aktuális-függvény (#01M) mező a csoportlapon | A #01M-szerű aktuális-függvény-kód kijelző hiányzik |
| b1-köv | FR-RFM-23 | Kitöltési segítség (függvény-kezelés) | PARTIAL | `MainRateSheetPage.tsx:1057-1089` Segítség modal (A–I, J–Q, !Axxx, #CCA, adatmásolás) | Help-szöveg megvan a Főlapon; a tényleges függvény-referencia-szintaxis (!Axxx, #CCA, adatlehúzás) **NEM implementált** (Phase 2 jelölés `:1076-1077`) |
| b1-köv | FR-RFM-24 | 54 csoport egyedi kedvezményhatár | PARTIAL | `RateCreationPage.tsx:463-475` workgroup gombok dinamikus; limit per-wg `:172` updateWorkgroupLimits | Per-csoport határ-tárolás megvan; a fix "54 csoport" nem garantált (dinamikus lista) — funkcionálisan OK |
| b1-köv | FR-RFM-25 | Validáció: eladási≥elszámoló, vételi≤elszámoló kiküldés előtt | PARTIAL | `RateCreationPage.tsx:286-293` buy<sell ellenőrzés; `:383` buy>official×1.1 warn; `RateSpreadGate` 5% | A spec **pontos** szabálya (sell ≥ official ÉS buy ≤ official) NINCS; csak buy<sell + buy≤official×1.1 közelítés. Az "eladási ≥ elszámoló" oldal teljesen hiányzik |

## b1 — Képernyők (FR-RFMUI)

| spec | FR-ID | követelmény (rövid) | státusz | kód-bizonyíték | hiány |
|---|---|---|---|---|---|
| b1-kép | FR-RFMUI-01 | Felső menü 4 pont | PARTIAL | `MainRateSheetPage.tsx:887-925` CSOPORTOK + SZÉTKÜLDÉS + INTERNET CÍMEK (disabled `:909-915`) + KILÉPÉS | INTERNET CÍMEK gomb **disabled** ("Hamarosan") — nem funkcionál |
| b1-kép | FR-RFMUI-02 | 0-s lap A–I + INTERNET fejlécek | PARTIAL | `:952-959` A–I fejlécek | **INTERNET oszlop hiányzik** a táblából (csak a fejléc-blokk A–I) |
| b1-kép | FR-RFMUI-03 | 28 valuta sorrend D | PARTIAL | `:65-88` | Csak 22 (lásd FR-RFM-08) |
| b1-kép | FR-RFMUI-04 | Kézi cellák vizuális kiemelés | IMPLEMENTED | `:998-1001` kézi=red bg, auto-kereszt=amber italic `:967` | — |
| b1-kép | FR-RFMUI-05 | G/H csak nem-fő valutáknál, fő valuták 0 | IMPLEMENTED | `:1024-1031` crossBase ? érték : '—' | — |
| b1-kép | FR-RFMUI-06 | INTERNET oszlop forrás-címkék + URL | MISSING | nincs INTERNET oszlop/forrás-címke | Teljes INTERNET forrásmegjelölés-oszlop (OTP/Feco/Realtime FX stb.) hiányzik |
| b1-kép | FR-RFMUI-07 | 54 számozott iroda-csempe rács | MISSING | `WorkgroupManager.tsx` lista-szerű CRUD; `RateCreationPage.tsx:463` apró számgombok (nem csempe-rács iroda-névvel) | A 54-es csempe-rács iroda-nevekkel (1 ÁRKÁD, 2 PÉCS FERENCSEK…) nincs |
| b1-kép | FR-RFMUI-08 | "Jelölt csoportokat ellenőrzi" 1–54 checklista | MISSING | nincs | Ellenőrző-checklista panel hiányzik |
| b1-kép | FR-RFMUI-09 | Csoport-karbantartó 5 művelet almenü | PARTIAL | `RateCreationPage.tsx` add/remove branch (`:489,501`), limit-mentés | Nincs "Munkacsoport átnevezése"/"Pénztár áthelyezése másik csoportba" külön művelet; átnevezés a `WorkgroupManager.tsx`-ben részben |
| b1-kép | FR-RFMUI-10 | "MŰVELET=KARBANTARTÁS" sárga panel | MISSING | nincs | — |
| b1-kép | FR-RFMUI-11 | Üres-csoport "NINCS IRODA ITT" | IMPLEMENTED | `RateCreationPage.tsx:510` "nincsIrodaHozzarendelve" üres-állapot | — (szöveg eltér) |
| b1-kép | FR-RFMUI-12 | Iroda-csempe státusz-szín (piros) | MISSING | nincs csempe → nincs státusz-szín | — |
| b1-kép | FR-RFMUI-13 | Csoportlap fej: csoportszám+név+irodalista | IMPLEMENTED | `:477-479` wg név; `:497-511` iroda-lista | — |
| b1-kép | FR-RFMUI-14 | J–S oszlopfejlécek sávhatárokkal | PARTIAL | RateGrid J/K + L–Q sávok; sávcímkék `:519-522` Alsó/Középső/Felső | R/S oszlop hiányzik (lásd FR-RFM-19); konkrét összeg-fejléc (0-50.000…) nem fix |
| b1-kép | FR-RFMUI-15 | "AKTUÁLIS FÜGGVÉNY" #01M mező | MISSING | nincs | (lásd FR-RFM-22) |
| b1-kép | FR-RFMUI-16 | "KEDVEZMÉNY HATÁROK" 3 mező | IMPLEMENTED | `:516-535` Alsó/Középső/Felső input + mentés | — |
| b1-kép | FR-RFMUI-17 | "KITÖLTÉSI SEGÍTSÉG" szekció | PARTIAL | Főlap Segítség modal `:1057` | A csoportlapon dedikált kitöltési-segítség szekció nincs |
| b1-kép | FR-RFMUI-18 | Csoportlap a 0-s lapról töltődik | PARTIAL | `MainRateSheetPage.tsx:38-41` A→J örökítés dokumentált; `RateCreationService` overview officialRate | A reaktív 0-s→csoport adatfolyam Phase 2 (`:1053` "Phase 2: reaktív adatfolyam"); jelenleg backend overview tölt, nem a Főlap localStorage |
| b1-kép | FR-RFMUI-19 | Szétküldés lépés-sorrendű log | MISSING | `RateCreationPage.tsx:310` publish→toast; `RatePublishHistory.tsx` history-lista | Lépéssoros művelet-log (ARFDATA.DAT→saját gép→irodák→…) nincs; csak summary toast + history |
| b1-kép | FR-RFMUI-20 | "Saját gépemre sikeresen lementettem" visszajelzés | PARTIAL | `MainRateSheetPage.tsx:572` "Főlap helyileg mentve (localStorage)" toast | Lokális mentés visszajelzés van, de nem a lépés-log részeként |
| b1-kép | FR-RFMUI-21 | Békéscsabai szerver backup + hiba-üzenet | PARTIAL | `MainRateSheetPage.tsx:808-829` publish success/részleges/sikertelen toast; offline indikátor `:861` | Szerver-publish + hibakezelés van, de NINCS dedikált "BIZTONSÁGI MENTÉS SIKERTELEN" backup-szerver (békéscsabai) lépés |

## b3 — Bank API

| spec | FR-ID | követelmény (rövid) | státusz | kód-bizonyíték | hiány |
|---|---|---|---|---|---|
| b3-bank | FR-1 | MNB árfolyam-webservice integráció | IMPLEMENTED | `MnbExchangeRateService.java:47-160` SOAP GetExchangeRates + cache; `MnbDailyReportScheduler` | A spec szerint a felhasználás (rate-maker auto-betöltés) TBD — jelen kód csak havi záráshoz használja (`:40` "Kizárólag a havi záráshoz"), NEM a Főlap A-oszlop auto-töltéshez |
| b3-bank | FR-2 | Raiffeisen Bank API integráció | PARTIAL | `RaiffeisenRateService.java:34-51` HTML-scraping (NEM az api.rbinternational.com API!); `RaiffeisenRateScheduler` | A spec az `api.rbinternational.com` hivatalos API-t kéri; a kód weboldal-scraping. Funkcionálisan árfolyamot ad, de nem a megnevezett API |

## b3 — Árfolyam-karbantartó hibalista (FR)

| spec | FR-ID | követelmény (rövid) | státusz | kód-bizonyíték | hiány |
|---|---|---|---|---|---|
| b3-hiba | FR-1 | Sor másolás lapreferencia ($LapT01 ne váltson) | MISSING | A jelenlegi HyperFormula-motor cella-szintű (`MainRateSheetPage.tsx:147` `${rowIdx}.${col}`), NINCS sor-másolás/multi-lap lapreferencia | Nincs sor-copy/paste lapreferencia-megőrzés (a régi Delphi `$LapT01!C9` modell nem implementált) |
| b3-hiba | FR-2 | Lapreferencia-fix általános (LapZ01 is) | MISSING | nincs (lásd FR-1) | — |
| b3-hiba | FR-3 | Működő Ctrl+Z | PARTIAL | `RateCreationPage.tsx:118-149` undo/redo Ctrl+Z/Y a csoportlapon | A **Főlapon** (MainRateSheetPage) NINCS undo/redo |
| b3-hiba | FR-4 | 0-s lapon csak aktív valuták | PARTIAL | `MainRateSheetPage.tsx:65-88` statikus 22 lista, NEM aktív-flag szűrt; CurrencyManager inaktivál de Főlap nem frissül (`:1099` "következő app-indítás után") | A Főlap nem szűr dinamikusan az aktív valutákra; inaktiválás nem tünteti el a sort élőben |
| b3-hiba | FR-5 | Minden munkalap + pénztár csak aktív valuták | PARTIAL | backend `currencyApi.getActive` (`exchange-rates.ts:106`) létezik; pénztár ezt használja | A Főlap statikus listája miatt a "minden munkalap" nem garantált; pénztár-oldal aktív-szűrés OK |
| b3-hiba | FR-6 | Valuta inaktiválható | IMPLEMENTED | `CurrencyManagerModal.tsx:84-108` setActive(false) + V238 audit | — |
| b3-hiba | FR-7 | Cellák másolhatók | MISSING | Help-szöveg említi (`:1075` CTRL+klikk adatmásolás) de **Phase 2** jelölés, nincs impl | Cella-másolás (CTRL+klikk terület) nincs implementálva |
| b3-hiba | FR-8 | Kerekítés matematikai szabály | PARTIAL | `RatePublishService.java:306` setScale(4, HALF_UP); `formatCell :835` toFixed | HALF_UP a publish/rounding-ban OK; a Főlap cella-szintű kerekítés-megjelenítés egységessége nem garantált |
| b3-hiba | FR-9 | Ellenőrzés → új oszlop hibalista | MISSING | `RateCreationPage.tsx:366-389` validationErrors per-sor (inline jelzés), de NINCS dedikált "hibalista oszlop" | A spec szerinti külön hibalista-oszlop az ellenőrzés outputjaként hiányzik |
| b3-hiba | FR-10 | Ellenőrzés/Mentés/Szétküldés szétválasztása | MISSING | Egyetlen "ÁRFOLYAMOK SZÉTKÜLDÉSE" gomb publish+validate egyben (`:545`, `MainRateSheetPage.tsx:902`) | Nincs külön Ellenőrzés gomb; mentés+szétküldés nincs külön lépésben |
| b3-hiba | FR-11 | Log pénztáranként (név, dátum) | PARTIAL | `RatePublication.publishedBy` + publishedAt (`RatePublishService.java:101`); `RatePublishHistory.tsx` | Publikálás-szintű napló van; "pénztáranként (név+dátum)" granularitás nincs külön |
| b3-hiba | FR-12 | Billentyűzet nyíl-navigáció | IMPLEMENTED | `sheetNavigation.ts:47` nextEditableCell; `MainRateSheetPage.tsx:518-522` arrow handler | — |
| b3-hiba | FR-13 | Enter-aktiválás cella, egér nélkül | IMPLEMENTED | `MainRateSheetPage.tsx:523-526` Enter/F2 startEdit; `:501-508` Enter commit+lefelé | — |
| b3-hiba | FR-14 | Új munkacsoport auto-feltöltés (elszámoló+valutanevek) | MISSING | `RateWorkgroupService.java:46-57` create() csak alap mezők, **semmilyen auto-rate/currency feltöltés** | Új munkacsoport NEM tölti be automatikusan az elszámoló árfolyamokat és valutaneveket |
| b3-hiba | FR-15 | Currency HUF egész szám | PARTIAL | `RateCreationPage.tsx:172-176` limit parseInt (egész); rate-cellák toFixed(2) | A HUF "Currency mező egész" külön nincs explicit kikényszerítve a valuta-rácsban |

---

## VALÓS GAP-EK (PARTIAL/MISSING, implementálható) — prioritással

### P0 — üzleti/compliance kritikus
1. **FR-RFM-25 — Validáció iránya hibás (kiküldés előtt).** Spec: eladási ≥ elszámoló ÉS vételi ≤ elszámoló. Kód csak `buy < sell` (`RateCreationPage.tsx:286-293`) + `buy > official×1.1` warn (`:383`). Az "eladási ≥ elszámoló" ellenőrzés **teljesen hiányzik** → félreárazott árfolyam kiküldhető.
2. **FR-RFM-09 — EUA üzleti szabály MISSING.** EUA sor létezik (`MainRateSheetPage.tsx:80`), de a ×1.2 képzés és a >20% eltérés-figyelmeztetés sehol (grep: 0 találat). Implementálható: pure rule `mainSheetRules.ts`-be + warning a publish előtt.
3. **FR-RFM-19 — Csoportlap R/S "saját hatáskörű" oszlop MISSING.** A pénztáros-kedvezmény P+0,25 képletes oszlopa nincs a RateGrid-ben; csak a kvóta-számláló (`TransactionService.java:1056`) létezik backend-en. A csoportlapon a megjeleníthető R/S határ hiányzik.

### P1 — funkcionális hiány
4. **FR-RFM-12/13 — Raiffeisen ±10% sáv MISSING.** A `RateSpreadGate` fix 5% és más célú (`RateSpreadGate.java:21`). A spec a középtől max 10%, **szabadon állítható**, kétféle forrásmódból (elszámoló/OTP). Új konfig + számítás kell.
5. **FR-RFMUI-07/08 — 54 iroda-csempe rács + 1–54 ellenőrző checklista MISSING.** Jelenleg lista-CRUD (`WorkgroupManager.tsx`) + apró számgombok. A spec vizuális csempe-rácsát (iroda-nevekkel, státusz-színnel FR-RFMUI-12) érdemes különálló képernyőként megépíteni.
6. **FR-RFMUI-06 + FR-RFMUI-02 — INTERNET oszlop + forrás-címkék MISSING.** A Főlapról hiányzik a valutánkénti forrás-megjelölés oszlop és a felső forrás-URL.
7. **b3-hiba FR-14 — Új munkacsoport auto-feltöltés MISSING.** `RateWorkgroupService.create()` (`:46`) nem tölti be az elszámoló árfolyamokat + valutaneveket. Implementálható a create-be.
8. **b3-hiba FR-10 + FR-RFMUI-19 — Ellenőrzés/Mentés/Szétküldés szétválasztás + lépés-log MISSING.** Jelenleg 1 gomb mindent csinál; nincs külön Ellenőrzés gomb és lépéssoros művelet-log.

### P2 — kisebb / spec-konformitás
9. **FR-RFM-08/03 — D oszlop 22 vs 28 valuta + A=OTP auto-copy.** 6 valuta törölve (üzleti döntés, de spec-eltérés); az OTP→A automatikus másolás a 10 valutára hiányzik.
10. **b3-hiba FR-3 — Ctrl+Z a Főlapon hiányzik** (csak a csoportlapon van).
11. **b3-hiba FR-4/FR-5 — Főlap dinamikus aktív-valuta szűrés.** Inaktiválás nem frissül élőben a Főlapon (`:1099` "következő app-indítás után").
12. **b3-hiba FR-7 — cella-másolás (CTRL+klikk terület)** csak help-szövegben, Phase 2.
13. **b3-hiba FR-9 — dedikált "hibalista oszlop"** az ellenőrzés outputjaként (jelenleg inline per-sor jelzés).
14. **FR-RFM-22 / FR-RFMUI-15 — "Aktuális függvény" (#01M) mező** a csoportlapon hiányzik.
15. **FR-RFM-10 — supervisori jelszó** az új valuta felvételhez/törléshez (jelenleg csak role-gate + megerősítő-panel).
16. **b3-bank FR-2 — Raiffeisen hivatalos API** (`api.rbinternational.com`) helyett HTML-scraping; **FR-1 MNB** csak havi záráshoz, nem a Főlap auto-betöltéshez.
17. **b3-hiba FR-1/FR-2 — sor-másolás lapreferencia-megőrzés** ($LapT01) — a régi Delphi multi-lap képletmodell nincs (a HyperFormula cella-szintű, egylapos).
