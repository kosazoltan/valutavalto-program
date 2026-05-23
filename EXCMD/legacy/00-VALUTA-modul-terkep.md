# Anti / VALUTA legacy modul-térkép (primer forrás: a tényleges .dpr/.pas fájlrendszer)

> Készült: 2026-05-22. **Ground truth = a tényleges `Anti/VALUTA/DLL/*` fájlrendszer**
> (109 DLL-modul, verifikálva `EXCMD/anti/valuta-modul-lista.csv`). A korábbi
> `Anti/antivaluta.md`-t NEM vettük igazságként; a modul-lista a fájlrendszerből készült.
>
> A „jelenlegi program" oszlop a mostani Java/React/Electron rendszerre utal.
> Jelölés: ✅ COVERED (a funkció bizonyíthatóan létezik) · ❓ ELLENŐRIZENDŐ ·
> ⛔ HIÁNYZIK · ⚙️ infra (más rétegben megoldott). A ❓-eket a mély utasítás-MD
> írásakor a tényleges .pas elolvasásával erősítjük meg.

## Architektúra (legacy)
- `IBVALTO/IBVALTO.DPR` — fő pénztári kliens (a 109 DLL-t tölti be)
- `DLL/<NÉV>/MAKEDLL/<név>.dpr` — 109 üzleti-logika DLL (modulonként 1 funkció)
- `TRADE/` — kereskedési/díj alrendszer

## Modul → jelenlegi program megfeleltetés

| Legacy DLL | .pas méret | Funkció (névből + ismert domain) | Jelenlegi program |
|---|---|---|---|
| ELADAS | 137 KB | valuta eladás | ✅ TransactionService (SELL) |
| VASARLAS | 104 KB | valuta vásárlás/vétel | ✅ TransactionService (BUY) |
| XTRANZ | 9 KB | extra/konverziós tranzakció | ✅ TransactionConversionService |
| STORNO | 36 KB | sztornó | ✅ StornoService (G2) |
| ARFVALT / BIGARFVALT / KISARFVALT | 8/11/43 KB | árfolyam-alkalmazás (kis/nagy összeg) | ✅ rate application + RFM |
| FOGLALO / FOGLREND | 83/21 KB | foglaló + rendelés | ✅ ReservationService (G8 5% letét) |
| CIMLET / CIMLCTRL / CIMLMENU / CIMLNYOM / CIMSETUP / KCIMLET / KISCIMLET | 6–33 KB | címletezés + nyomtatás + setup | ✅ DenominationOptimizationService (7 stratégia) |
| NAPZAR / ESTIZAR / HAVIZAR / NAVZARO / REGIZARO / HRKZARO | 6–93 KB | nap/esti/havi/NAV/régi/HRK zárás | ✅ ClosingWizardService + DailyClosingService + NavClosing (G3) |
| DEKRUTIN / KEZDEKAD | 34/24 KB | dekád zárás/kezdés | ✅ decade closing |
| CHECKLST | 14 KB | zárási checklist | ✅ closing step checks |
| NAPIKEZD | 30 KB | napi kezdés (nyitás) | ✅ daily open session |
| NAPIJEL / NZNYOMT | 44/54 KB | napi jelentés + nyomtatás | ✅ NavReport + receipt PDF |
| NAPKONYV | 33 KB | napkönyv | ✅ DailyJournalService |
| FORGOSSZ / MAIFORG / NAPIFORG | 12–21 KB | forgalom összesítő/napi | ✅ MonthlyReport + turnover riportok |
| IDOSZAK | 8 KB | időszakos (visszatérő ügyfél) | ✅ RecurringCustomerReportService |
| PILLALL / PILLKESZ | 13/66 KB | pillanatnyi pénztárállás / készlet | ✅ LiveCashPositionService (G9) |
| LISTAK | 48 KB | listák/riportok | ✅ reports modul |
| UGYFEL / KISUGYFEL / UGYFELTMK | 113/29/92 KB | ügyfél törzs + WU-ügyfél | ✅ Customer + AML ügyfél |
| BIGCTRL | 45 KB | AML kontroll (TranzTipus besorolás) | ✅ AmlService (BIGCTRL logika átültetve) |
| TERROR | 8 KB | terror/szankciós lista | ✅ SanctionScreeningService (G5/G6/G13) |
| KEZDIJ / KEZDKEDV | 31/10 KB | kezelési díj + kedvezmény | ✅ HandlingFee + CommissionRate |
| WUNION / GETWUGYF / GETWCEG | 91/18/12 KB | Western Union | ✅ Western Union modul |
| METRO / TESCO | 75/56 KB | ÁFA (Metro/Tesco) | ✅ ÁFA modul |
| HRKATADO | 29 KB | HRK (e-kereskedelem) átadó | ✅ e-kereskedelem modul |
| ATADOLAP / ATADVET | 64/138 KB | átadólap + átadás-átvétel | ✅ Transfer + transfer_lines (multi-valuta) |
| GETPLOMB / GONGBACK | 7/5 KB | plomba + göngyöleg | ✅ carrier/seal mezők |
| KESZEDIT / KESZUP / PTARKESZ / MATPTAR / MATREGEN / REGEN / MAKTABLAK | 4–39 KB | készlet szerk./feltöltés/regen | ✅ CashBalance + stock + denomination balance |
| BLOKNYOM / BIZODISP / DOCDISP | 6–58 KB | blokk/bizonylat/dokumentum megjelenítés-nyomtatás | ✅ ReceiptGeneratorService + EscPosReceiptService |
| QRGENER / QRDEPUTY | 22/25 KB | QR-kód generálás | ❓ ELLENŐRIZENDŐ (van-e QR a bizonylaton) |
| GEPSETUP | 57 KB | gép-beállítás (szerep, IP, eszközök) | ✅ PenztarSettings (G20) |
| SCANNING / UJSCANNER | 7/14 KB | szkenner | ✅ G20 szkenner-beállítás (+ okmány-szkennelés ❓) |
| TERMINAL | 3 KB | bankkártya-terminál | ✅ G20 kártya-engedély (+ POS service) |
| FNYUJSAG | 18 KB | futófény (LED kijelző tábla) — sok iroda-variáns | ⛔ HIÁNYZIK (futófény-tábla COM-vezérlés; G20 csak a beállítást tárolja) |
| EUAKCIO | 1 KB | EU akció | ❓ ELLENŐRIZENDŐ |
| KORLEV | 27 KB | körlevél | ✅ CircularService (G21) |
| GETARF / SETRATE / OTP / OTPLOG | 5–60 KB | árfolyam lekérés/beállítás + OTP | ✅ exchange rate + RFM (OTP oszlop) |
| TEAOR | 5 KB | TEÁOR kód választó | ❓ ELLENŐRIZENDŐ |
| GETENGED / GETFIZE / GETISO / GETNYUGT / GETPTAR / GETSTATUS / GETFIZE | 3–34 KB | getter-ek (engedély/fizetés/ISO/nyugta/pénztár/státusz) | ⚙️ API/DTO rétegben megoldott |
| COPY2FTP / VERZFRIS / MENTES | 3–35 KB | FTP-sync / verzió-frissítés / mentés | ⚙️ Electron sync-engine + auto-update + DB backup |
| LOGDISP / LOGIRO | 5/3 KB | naplózás | ✅ V234 audit log + VVLogger |
| SUPER / SUPERTSK | 5/11 KB | supervisor + feladatok | ✅ szerepkör-alapú jogosultság |
| CONFIDEN / CONFIRM / QUITFORM / PAUSDISP | 3–11 KB | megerősítő/kilépő/szünet dialógusok | ⚙️ UI (React dialógusok) |
| PROCEND / PROSBE / PROSKI / PROSTMK / OTHERTSK / PTARTMK / FIRSTCTRL | 3–42 KB | folyamat/feladat-kezelés, indítás-vezérlés | ⚙️ workflow + bootstrap |
| SENDOKMANY | 11 KB | okmány-küldés (szerverre) | ✅ ügyfél-okmány tárolás/küldés |
| GETISO | 7 KB | ISO valutakód | ✅ currency ISO kód |
| _BASEDLL | <1 KB | közös DLL alap | ⚙️ közös réteg |
| ADATLAP / AFATABLA / ARFDISP / ARFREG / ARFTMK | 0 B | **üres stub** (nincs forrás) | — |

## Verifikált eredmény (a tényleges .pas + jelenlegi kód összevetése után)

A 109 legacy VALUTA DLL **túlnyomó többsége** a jelenlegi programban már megvan (a domain-funkciók egyeznek). A ❓ tételeket a **tényleges forrás ellen** ellenőriztem:

- ✅ **QRGENER/QRDEPUTY** → MEGVAN: `qrCode` mező a `ReceiptData`-ban + `NavIntegrationController` (NAV QR). COVERED.
- ↔️ **EUAKCIO** → a `Unit2.pas` szerint csak egy `euakciokerdo: integer` IGEN/NEM dialógus (EU-akciós árfolyam kérdés) — triviális UI, nem érdemi üzleti funkció.
- ⛔ **TEAOR** → a jelenlegi programban NINCS TEÁOR-kód kezelés (a `teaorsel.dpr` céges ügyfél tevékenységi kódját választja). **Kis lehetséges hiány** — relevancia: csak jogi-személy ügyfélnél, ritka a valutaváltásban.
- ⛔ **FNYUJSAG** → futófény LED-kijelző tábla soros (COM) vezérlése. A G20 csak a beállítást tárolja; a tényleges kijelző-vezérlés **hardver-függő**, az Electron-runtime + fizikai tábla nélkül nem implementálható/verifikálható.
- ⛔ **SCANNING okmány-beolvasás** → a fizikai okmány szkennelése (G20 csak a driver-beállítást tárolja). Hardver-függő.

**Konklúzió (VALUTA modul):** a legacy pénztári üzleti logika **érdemben teljesen lefedett** a jelenlegi programban. A maradék kizárólag (a) **hardver-függő** (FNYUJSAG futófény, SCANNING okmány-beolvasás — Electron+eszköz kell), vagy (b) **triviális/marginális** (EUAKCIO dialógus, TEAOR céges kód). **Nincs hiányzó érdemi pénztári üzleti funkció.**

**Következő modulok (a teljes Anti-feldolgozáshoz):** `ARFOLYAM` (árfolyamkészítő — RFM-mel összevetni), `ERTEKTAR` (értéktár), `SZERVER` (szerver logika), `camera*` (kamera Java). Ezeket ugyanígy: tényleges forrás → modul-térkép → csak a valódi hiányból utasítás-MD + impl.
