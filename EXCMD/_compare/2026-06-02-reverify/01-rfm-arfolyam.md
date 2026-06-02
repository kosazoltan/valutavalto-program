# RFM / Árfolyamkészítő — Doc↔Kód konformancia-audit (2026-06-02 reverify)

Forrás-specek: `b1-arfolyamkeszito-kepernyok.md`, `b1-arfolyamkeszito-kovetelmenylista.md`,
`FK02-B_csoport_arfolyamlap_javitasok_findingok.md`, `b3-arfolyam-karbantarto-hibalista.md`,
`b3b-erb-egyedi-kotas.md`, `b8-atlagarfolyam.md`.

Kód-helyek: `frontend-react/src/pages/rates/**`, `backend/.../service|controller|repository`.
Megjegyzés: a B-csoportos lap kódjában az „N–S sáv" valójában a `limit1/2/3` (1–3. kedvezménysáv)
vétel/eladás mezők; a spec K=ISO, J=elszámoló elnevezés a fejléccel egyezik.

| Követelmény (forrás FR) | Státusz | Bizonyíték (file:line v. keresve) | Prio | Megjegyzés |
|---|---|---|---|---|
| **FR-RFMUI-01** Felső fő menüsor (4 pont) | ✅IMPL | `MainRateSheetPage.tsx:964-1033` (CSOPORTOK KARBANTARTÁSA / SZÉTKÜLDÉS / INTERNET CÍMEK / KILÉPÉS) | P2 | Mind a 4 menüpont megvan |
| **FR-RFMUI-02** 0-s lap A–I oszlopfejlécek | ✅IMPL | `MainRateSheetPage.tsx:1040-1049` (A–I + thead) | P2 | INTERNET külön gombsoron, nem oszlopként |
| **FR-RFMUI-03** 0-s lap 28-elemű valutasorrend | 🔴WRONG | `MainRateSheetPage.tsx:75-98` — csak 22 valuta (DKK, NOK, SEK, HRK, BGN, RCH tudatosan törölve v2.5.61) | P3 | A spec FR-RFMUI-03 28 valutát ír elő; a kód 22-t ad. By-design eltérés (user-direktíva 2026-05-19), de a spec-szám nem frissült → dokumentáció-kód ellentmondás |
| **FR-RFMUI-04** Kézi cellák vizuális kiemelése | ⚠️PARTIAL | `MainRateSheetPage.tsx:1096-1099` (kereszt-auto amber vs kézi piros), `RateGrid.tsx:271-275` (modified=sárga) | P3 | Van szín-megkülönböztetés (auto/kézi/módosított), de a spec szerinti „AUD piros keret / B-C zöld háttér" konkrét legacy mintázat nincs |
| **FR-RFMUI-05** Kereszt-árfolyam csak nem-fő valutáknál | ✅IMPL | `MainRateSheetPage.tsx:1121-1130` (G/H csak `crossBase` sorban, fő valutánál `—`) | P2 | |
| **FR-RFMUI-06** INTERNET oszlop forráscímkék + URL | ⚠️PARTIAL | `MainRateSheetPage.tsx:987-1004,1221-1270` (internet-link karbantartó, dinamikus gombok); `arfolyamInternetLinkApi` | P3 | Van konfigurálható internet-link kezelő, de NEM valutánkénti forráscímke-oszlop és nincs a specifikus `exchange-rates.org/...` default URL beégetve |
| **FR-RFMUI-07** Csoport-karbantartó 54 számozott iroda-csempe | 🔴WRONG | `RateCreationPage.tsx:1309-1392` — csempés grid a MUNKACSOPORTOKból (dinamikus N db), NEM 54 iroda-csempe | P2 | A csempék = munkacsoportok, nem az 1–54 iroda. A legacy „54 iroda-csempe rács irodanevekkel" nem létezik így |
| **FR-RFMUI-08** „A JELÖLT CSOPORTOKAT ELLENŐRZI" 1–54 checklista panel | ❌MISSING | keresve: `RateCreationPage.tsx`, `RateGrid.tsx` — nincs 1–54 ellenőrző checklista panel | P3 | Helyette per-csoport „VÉDELEM" checkbox a csempén (`RateCreationPage.tsx:1321-1345`) |
| **FR-RFMUI-09** Csoport-karbantartó almenü 5 művelettel | ⚠️PARTIAL | `RateCreationPage.tsx:1264-1290` (Új munkacsoport), `:1369-1388` (Szerk./Törlés), `workgroupMaintenance.tsx` | P3 | Van create/rename/delete + iroda-hozzárendelés, de NEM a legacy 5 konkrét menüpont szövegével („PÉNZTÁR ÁTHELYEZÉSE MÁSIK CSOPORTBA" stb.); az áthelyezést a move-strategy backend implicit kezeli |
| **FR-RFMUI-10** „MŰVELET = KARBANTARTÁS" sárga panel | ❌MISSING | keresve: "MŰVELET", "KARBANTARTÁS" panel — nincs | P3 | A legacy sárga művelet-panel nincs reprodukálva (modern modal-alapú UI) |
| **FR-RFMUI-11** Üres csoport „NINCS IRODA ITT" | ⚠️PARTIAL | `RateCreationPage.tsx:1067` (`rates.nincsIrodaHozzarendelve`), `:1360-1364` (0 iroda kijelzés) | P3 | Üres-állapot kezelve, de nem a pontos „NINCS IRODA ITT" szöveggel |
| **FR-RFMUI-12** Iroda-csempe státusz-szín (piros aktív) | ⚠️PARTIAL | `workgroupMaintenance.tsx:29-47` (10 tile-szín paletta), `tileClasses()` | P3 | Konfigurálható csempeszínek vannak, de a legacy `clRed=aktív kijelölt` / `clLime=zöldrutin` szemantika nincs |
| **FR-RFMUI-13** Csoport árfolyamlap fejléc (szám+név+irodalista) | ✅IMPL | `RateCreationPage.tsx:932-939` (sorszám+név+kód), `:1039-1069` (iroda-lista panel) | P2 | |
| **FR-RFMUI-14** Csoport árfolyamlap J–S oszlopfejlécek + sávhatárok | ✅IMPL | `RateGrid.tsx:234-264` (J–S, sávhatárok a limit1/2/3-ból) | P1 | Fix oszlopkiosztás + dinamikus sávhatár-fejléc |
| **FR-RFMUI-15 / FR-RFM-22(fv)** AKTUÁLIS FÜGGVÉNY + képlet-szemantika | ✅IMPL | `RateCreationPage.tsx:1016-1024` (currentFunctionCode), képlet-motor `workgroupSheetCompute.ts`, `workgroupSheetFormula.ts`; súgó `FormulaSyntaxHelp.tsx` | P1 | A-C/E-J/L-S + `!<oszl><CUR>` + `#NN<oszl>` támogatott |
| **FR-RFMUI-16** KEDVEZMÉNY HATÁROK panel (3 mező) | ✅IMPL | `RateCreationPage.tsx:1072-1098` (Alsó/Középső/Felső) | P2 | |
| **FR-RFMUI-17** KITÖLTÉSI SEGÍTSÉG szekció | ✅IMPL | `RateCreationPage.tsx:1029-1037` | P3 | |
| **FR-RFMUI-18** Csoportlap J–S 0-s lapról töltődik, kézzel nem írható | 🔴WRONG | `RateGrid.tsx:309-352` (L–S mezők SZERKESZTHETŐK inputok); `RateCreationPage.tsx:476-545` (commitWorkgroupCell ír) | P2 | A spec szerint a J–S cellák szerkesztése „letiltott"; a kód viszont a modern docx-spec (FK-04) szerint képlettel/kézzel SZERKESZTHETŐ. Tudatos újraértelmezés — spec-kód ütközés |
| **FR-RFMUI-19** Szétküldés ARFDATA.DAT + FTP log | 🔴WRONG | keresve `ARFDATA\|FtpPutFile\|185.43.207.99` az arfolyam-keszito frontendben: nincs. Szétküldés = `exchangeRateMasterApi.create/approve/publish` (`MainRateSheetPage.tsx:864-868`) | P2 | Modern REST publish-elosztás, NEM ARFDATA.DAT/FTP. A backend FtpSyncService a napzárás-szinkronhoz van, nem az árfolyam-ARFDATA-hoz |
| **FR-RFMUI-20** „A saját gépemre sikeresen lementettem" log | ⚠️PARTIAL | `MainRateSheetPage.tsx:579` ("Főlap helyileg mentve (localStorage)") | P3 | Van lokális-mentés visszajelzés, de nem a pontos legacy szöveg + nincs külön szétküldés-műveletlog panel |
| **FR-RFMUI-21** Szerver biztonsági mentés log + fallback hiba | ⚠️PARTIAL | `MainRateSheetPage.tsx:887-908` (siker/részleges/hiba toast) | P3 | Van publish hiba-visszajelzés + 3-régiós failover a sync-engine-ben, de NEM a Békéscsaba→Pécs FTP fallback és nincs a konkrét hibaszöveg |
| **FR-RFMUI-22 / FR-RFM-26 / FR-HL-16** B-csoport valutasorrend = Főlap | ✅IMPL | `RateCreationPage.tsx:61-77,384` (`MAIN_SHEET_CURRENCY_ORDER` + `sortByMainSheetOrder`) | P1 | FK02-B 1.1 javítva |
| **FR-RFMUI-23 / FR-RFM-28 / FR-HL-18** Drag-kijelölés + lebegő toolbar | ✅IMPL | `RateGrid.tsx:85-198,372-405` (drag/Shift selection, Lehúzás mind/Ürítés/Sávok törlése toolbar) | P1 | FK02-B 1.3 javítva; BAND_COL_INDICES=limit1-3 |
| **FR-RFMUI-24 / FR-RFM-30** Irodaválasztó szűrés PENZTAR-ra (FK02-C) | ✅IMPL | `BranchRepository.java:181-184` (`findRateCreationAssignableCashierBranches`), `RateCreationService.java:684,737-742` (POST validáció) | P1 | Backend lista + mentés-validáció is szűr |
| **FR-RFM-01** Munkalapok összeköttetése (gyors átjárás) | ✅IMPL | `MainRateSheetPage.tsx:966-979` ↔ `RateCreationPage.tsx:923-929` (FŐLAP↔CSOPORTOK navigáció) | P3 | |
| **FR-RFM-02** Elszámoló (A) kézi módosíthatóság | ✅IMPL | `MainRateSheetPage.tsx:1094-1100`, `computeCellCommit:347-424` | P2 | |
| **FR-RFM-03** Auto-OTP másolás (10 valutánál B→A) | ❌MISSING | keresve: nincs OTP(B)→settlement(A) auto-copy logika a 10 valutára; A=kézi v. G-kereszt (`mainSheetRules.ts resolveSettlement`) | P2 | Az A oszlop fő valutánál kézi, kereszt-valutánál G-ből; az OTP-alapú auto-másolás a megadott 10 valutára nincs implementálva |
| **FR-RFM-04** EUR-alapú kereszt (A=EUR/kereszt) | ✅IMPL | `mainSheetRules.ts` computeCrossSettlement; `MainRateSheetPage.tsx:83-93` (crossBase='EUR') | P2 | |
| **FR-RFM-05** USD-alapú kereszt | ✅IMPL | `MainRateSheetPage.tsx:87-97` (crossBase='USD'), computeCrossSettlement | P2 | |
| **FR-RFM-06** OTP (B) szerkeszthetőség | ✅IMPL | `MainRateSheetPage.tsx:1102-1104` (otp input) | P3 | |
| **FR-RFM-07** Segédoszlop (C) | ✅IMPL | `MainRateSheetPage.tsx:1106-1108` (helper input, képletezhető) | P3 | |
| **FR-RFM-08** Valutanemek (D) sorrendje (28) | 🔴WRONG | `MainRateSheetPage.tsx:75-98` — 22 valuta | P3 | lásd FR-RFMUI-03 (by-design 22, spec 28) |
| **FR-RFM-09** EUA = F×1.2, max 20% eltérés | ✅IMPL | `rfmRules.ts:20-33` (computeEuaRate/euaDeviationExceeds), `MainRateSheetPage.tsx:822-829` (kiküldés-figyelmeztetés) | P2 | |
| **FR-RFM-10** Valuta felvétel/törlés jelszó/megerősítés | ✅IMPL | `CurrencyManagerModal.tsx:84-145,277-313` (add + aktivál/inaktivál megerősítéssel + audit) | P2 | „törlés" helyett inaktiválás (Pmt. megőrzés) — helyes |
| **FR-RFM-11** Gyenge multis vétel(E)/eladás(F), E képletezhető | ✅IMPL | `MainRateSheetPage.tsx:1113-1120` (E/F input), `FORMULA_COLUMNS:146` (weakMultiBuy/Sell) | P2 | |
| **FR-RFM-12** Raiffeisen ±10% sáv, állítható | ⚠️PARTIAL | `rfmRules.ts:45-52` (`raiffeisenBand`, állítható %) — pure fv. létezik | P2 | A számító-fv. létezik és tesztelt, de NINCS bekötve a UI cella-validációba / publish-gátba (nem találtam hívót a RateCreationPage/MainRateSheetPage validációban) |
| **FR-RFM-13** ±10% sáv bázis (Elszámoló v. OTP) választható | ❌MISSING | keresve: `raiffeisenBand` hívó bázis-kapcsolóval — nincs UI-beállítás | P3 | A fv. paramétere létezik, de nincs felhasználói bázis-választó |
| **FR-RFM-14** Keresztárfolyam G/H 18 valutánál | ⚠️PARTIAL | `MainRateSheetPage.tsx:83-97` (kereszt 14 valuta: CZK,PLN,RON,RSD,ILS,UAH,RUB,TRY,CNY,BAM,THB,BRL,MXN,NZD) | P3 | HRK/BGN/RCH inaktív (törölt), EUA crossBase=null → 14 a 18-ból; a többi a 22-es lista miatt nincs |
| **FR-RFM-15** Csoportlap J (elszámoló) + K (valuta) | ✅IMPL | `RateGrid.tsx:252-254,279-307` | P2 | |
| **FR-RFM-16** Alsó sáv L/M | ✅IMPL | `RateGrid.tsx:255-256` (L=vét, M=elad → buyRate/sellRate) | P2 | |
| **FR-RFM-17** Középső sáv N/O | ✅IMPL | `RateGrid.tsx:257-258` (limit1Buy/Sell) | P2 | |
| **FR-RFM-18** Felső sáv P/Q | ✅IMPL | `RateGrid.tsx:259-260` (limit2Buy/Sell) | P2 | |
| **FR-RFM-19** Saját hatáskör R/S = P±kedvezmény (képletezve) | ✅IMPL | `rfmRules.ts:58-62` (computeRsRate), `RateGrid.tsx:261-262` (R/S=limit3), képletezhető a formula-motorral | P2 | R=P+d, S=Q−d a felhasználói képlettel (`!`/`#`/oszlopbetű) megvalósítható |
| **FR-RFM-20** Pénztáros saját kedvezmény napi limit max 5/nap | ❌MISSING | keresve `ownDiscretion\|dailyOwn\|5 darab\|R/S limit` a backendben: nincs. `DiscountApprovalService` = %-alapú approval-mátrix (más mechanizmus); `TransactionValidationService:36` MAX_REVERSAL_COUNT=5 = sztornó, nem R/S | P1 | A napi 5 db saját-hatáskörű (R/S sáv) tranzakció-limit a penztar-client/backend tranzakcióban nincs implementálva |
| **FR-RFM-21** Csoportba tartozó irodák listája | ✅IMPL | `RateCreationPage.tsx:1039-1069` | P2 | |
| **FR-RFM-22** AKTUÁLIS FÜGGVÉNY kód kijelzés | ✅IMPL | `RateCreationPage.tsx:1016-1024` (currentFunctionCode) | P3 | |
| **FR-RFM-23** Kitöltési segítség + Zöldrutin (lehúzás villogó zöld) | ⚠️PARTIAL | `RateGrid.tsx:173-198` (Lehúzás mind = fill-down) | P3 | Fill-down megvan, de a `clLime` villogó-zöld animáció + a 4 hivatkozási mód explicit picker hiányzik |
| **FR-RFM-24** Csoportonként egyedi kedvezményhatár | ✅IMPL | `RateCreationPage.tsx:603-628` (updateWorkgroupLimits per WG), `WorkgroupEditor:134-153` | P2 | |
| **FR-RFM-25 / FR-RFMUI-21(validáció)** Kiküldés-előtti szigorú ellenőrzés (Vegcontrol) | ✅IMPL | frontend `workgroupProtection.ts:82-117` + `RateCreationPage.tsx:739-764`; 0-s lap `rateDirectionRules.ts` + `MainRateSheetPage.tsx:810-843`; backend `RatePublishService.validateRateProtection` (workgroupProtection JavaDoc-ref) | P1 | Vétel≤J / eladás≥J minden sávra; 0-s lapon E≤A/F≥A. Backend+frontend kettős |
| **FR-RFM-27 / FR-HL-17** 10%-eltérés megerősítő modal (előző mentett értékhez) | ✅IMPL | `deviationCheck.ts:19-22`, `RateCreationPage.tsx:529-543` (baselineRatesRef-hez mér, modal, revert) | P1 | FK02-B 1.2 javítva — a perzisztált baseline-hoz mér |
| **FR-RFM-29 / FR-HL-19** Helyi SQLite perzisztencia onBlur (group_rates) | 🔴WRONG | `workgroupSheetStorage.ts:73-99` (`saveGroupRateValues`) = **localStorage**, NEM SQLite; keresve `lf:save-group-rates` IPC: nincs az `arfolyam-keszito-client/electron`-ban | P1 | A FK02-B 1.4 javítási útmutató kifejezetten SQLite `group_rates` táblát + `lf:save-group-rates` IPC-t ír elő. A megvalósítás localStorage-alapú (lapváltás-megőrzés OK), de NEM az előírt SQLite-réteg → spec-kód ellentmondás |
| **FR-HL-01** Sor másolás $LapT01 lapreferencia megőrzés | ❌MISSING | keresve `$Lap\|LapT01\|copyRow\|pasteRow`: nincs Excel-stílusú lapreferenciás sor-másolás | P3 | Az architektúra nem `$LapT01!C9` képletmodellt használ (hanem `!FEUR`/`#01M`), így a legacy bug-fix tárgytalan; a sor-másolás funkció maga nincs |
| **FR-HL-02** Lapreferencia-javítás általánossága | ❌MISSING | ld. FR-HL-01 | P3 | Tárgytalan a más képletmodell miatt |
| **FR-HL-03** Visszavonás (Ctrl+Z), max 50 | ✅IMPL | `RateCreationPage.tsx:419-458` (undo/redo stack, `>50` shift, Ctrl+Z/Y) | P2 | |
| **FR-HL-04** 0-ás lap csak aktív valuták | ⚠️PARTIAL | `MainRateSheetPage.tsx:75-102` (statikus 22 aktív lista + REMOVED szűrés) | P2 | Statikus listával „aktív" valuták jelennek meg, de NEM dinamikus `is_active` DB-flag alapján — inaktiválás a CurrencyManagerből nem tükröződik élőben (kód-komment: csak app-újraindításkor, és akkor is statikus lista) |
| **FR-HL-05** Minden munkalap + penztar-client csak aktív valuták | ⚠️PARTIAL | backend `currencyApi.getActive():106`; penztar-client keresve `is_active currency`: nem egyértelmű szűrés | P2 | Backend `/active` szűr; a penztar-client kliens-oldali aktív-valuta szűrése VERIFIKÁLANDÓ (sync-engine `active?` mező a szerver-kindra vonatkozik) |
| **FR-HL-06** Valuta inaktiválása UI-ból | ✅IMPL | `CurrencyManagerModal.tsx:84-108,358-377`, backend `AdminCurrencyService` + `currency_audit_log` (V238) | P2 | |
| **FR-HL-07** Cella egyedi másolhatóság (clipboard) | ❌MISSING | keresve `navigator.clipboard\|copyToClipboard` a rates-ben: nincs | P3 | Nincs explicit cella→vágólap másolás (a böngésző natív input-select működik, de nem cella-másoló funkció) |
| **FR-HL-08** Matematikai kerekítés | ⚠️PARTIAL | `MainRateSheetPage.tsx:313-314,377-378` (`toFixed(dec)` JPY=3, egyéb=2); backend `RoundingMode.HALF_UP` (AverageRate) | P2 | Van kerekítés, de a `toFixed` banker's-nem, és nincs devizánként paraméterezhető tizedespontosság a kerekítő-szabályban (spec: „devizanemenként paraméterezhető") |
| **FR-HL-09** Ellenőrző hibalista oszlop | ✅IMPL | `RateGrid.tsx:248,353-364` ("Ellenőrzés"/"Hiba" oszlop, per-sor hibák) | P2 | |
| **FR-HL-10** Ellenőrzés/Mentés/Szétküldés szétválasztás | ⚠️PARTIAL | `MainRateSheetPage.tsx:954-985` (Mentés + SZÉTKÜLDÉS külön); ellenőrzés a publish-be ágyazva | P3 | Mentés és Szétküldés külön gomb; az „Ellenőrzés" NINCS önálló gombként (a publish belsőleg validál) |
| **FR-HL-11** Pénztárankénti audit log (név, dátum) árfolyam-módosításhoz | ❌MISSING | keresve `CashierAuditLog\|ARFLOG\|HRKNAPLO\|rate audit branch`: csak `currency_audit_log` (valuta CRUD, nem ráta+branch+user) | P1 | Az árfolyam-módosítás pénztárankénti (branch_id+user_name+action_details) audit-naplója nincs implementálva |
| **FR-HL-12** Nyíl-billentyűs navigáció | ✅IMPL | `sheetNavigation.ts:47-68` (nextEditableCell), `MainRateSheetPage.tsx:518-526`; csoportlap `useGridNavigation` (`RateGrid.tsx:69`) | P2 | |
| **FR-HL-13** Enter cellaaktiválás (szerkesztésbe lépés) | ✅IMPL | `MainRateSheetPage.tsx:501-526` (Enter/F2 startEdit, Enter commit+lefelé) | P2 | |
| **FR-HL-14** Munkacsoport auto-feltöltés (valuták + elszámoló) | ⚠️PARTIAL | `RateCreationPage.tsx:367-384` (overview.currencies → editableRates J=officialRate); create: `rateWorkgroupApi.create` | P2 | A csoport-lap betöltéskor a valuták + J elszámoló a 0-s lapról/overview-ból jön; de hogy ÚJ csoport LÉTREHOZÁSAKOR azonnal előtöltődik-e, az a betöltés-flow-tól függ — VERIFIKÁLANDÓ end-to-end |
| **FR-HL-15** HUF mező egész szám (tizedes nélkül) | ❌MISSING | keresve `HUF egész\|isHuf\|forint egész` a rates-ben: nincs HUF-specifikus egész-kényszer | P2 | A kedvezményhatárok (`parseInt`) egészek, de a „Currency mező HUF egész" cella-szintű kényszer nincs külön kezelve |
| **FR-1..3 (b8 Átlagárfolyam)** Súlyozott átlag riport + időszak-aggregáció | ✅IMPL | `AverageRateReportService.java:54-151` (`SUM(huf)/SUM(currency)`, HALF_UP 4 tizedes, financialEffective=TRUE, companyId, from/to, branch/currency/type szűrő), `AverageRateReportController` | P1 | Teljesen lefedi a b8 FR-1/2/3-at és NFR-1/2/3-at |
| **FR-ERB-01..04 (b3b ERB egyedi kötés)** | ❌MISSING | keresve `ERB\|EgyediKotes\|egyedi.kot` (.ts/.tsx/.java): csak `bankPartners` (irreleváns) | P3 | Az ERB Raiffeisen bankkártyás egyedi kötés képernyő (penztar-client) nincs implementálva. Spec maga is „Alacsony" prio + TBD-protokoll |

---

## Összegzés

- A B-csoportos lap FK02-B javításai (valutasorrend, 10%-modal, drag+toolbar, FK02-C iroda-szűrés) és a
  kiküldés-előtti árfolyamvédelem (FR-RFM-25) + a b8 átlagárfolyam riport **késznek** tekinthetők.
- A legacy-screenshot-eredetű FR-RFMUI tételek nagy része **tudatosan újraértelmezett** modern UI-ban
  (54 csempe → munkacsoport-csempe, ARFDATA.DAT/FTP → REST publish, SQLite → localStorage), ezért
  több tétel 🔴WRONG/⚠️PARTIAL nem hibás kód, hanem **spec↔implementáció architektúra-eltérés**.
- Valódi funkcionális hiányok (P1): **FR-RFM-20** (napi 5 R/S limit), **FR-HL-11** (pénztárankénti
  ráta-audit log), **FR-RFM-29/FR-HL-19** (előírt SQLite réteg helyett localStorage),
  **FR-RFM-12** (Raiffeisen-sáv fv. nincs bekötve), **FR-RFM-03** (auto-OTP másolás).
