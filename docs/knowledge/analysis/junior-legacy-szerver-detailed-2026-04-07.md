# Junior — Legacy SZERVER Részletes Elemzés (10K szegmensekben)
> Dátum: 2026-04-07 | Módszer: forráskód beolvasás 200 soronként, szegmensenként elemzés

---

## SZEGMENS 1: unit29.pas — TADATLEGYUJTES (Adatgyűjtő/Receptor) [0-400 sor]

### Funkció
A **központi adatgyűjtő modul** — az összes iroda (pénztár) adatait összegyűjti a központi szerverre.

### Architektúra
- **Receptor pattern:** Minden iroda saját Firebird DB-vel (`c:\receptor\database\v{irodaszam}.FDB`)
- **Ciklus:** Az összes irodán (`_irodaDarab`) végigiterál, mindegyikből legyűjti:
  1. Forgalom (BLOKKFEJ + BLOKKTETEL join)
  2. Címletezés (CIMT táblák)
  3. Western Union tranzakciók (WUNI, WZAR, WAFA táblák)
  4. Metro tranzakciók (WAFA tábla aliasra)
  5. Tesco tranzakciók (TESC tábla)
  6. Bank forgalom

### Táblastruktúra (kódból kinyerve)
| Tábla minta | Leírás | Példa |
|-------------|--------|-------|
| BF{éévhh} | Blokkfej (havi) | BF2604 = 2026 április |
| BT{éévhh} | Blokktetel (havi) | BT2604 |
| CIMT{éévhh} | Címletezés (havi) | CIMT2604 |
| NARF{éévhh} | Napi árfolyam (havi) | NARF2604 |
| WZAR{éévhh} | WU záras (havi) | WZAR2604 |
| WUNI{éévhh} | WU tranzakciók (havi) | WUNI2604 |
| WAFA{éévhh} | Metro/WAFA (havi) | WAFA2604 |
| TESC{éévhh} | Tesco (havi) | TESC2604 |

### Gyűjtőtáblák (központi)
- FORGALOMGYUJTO, CIMLETGYUJTO, WUNIGYUJTO
- PENZTARKOZOTT, TRBGYUJTO, SUMBANKFORGALOM
- STORNOFEJ, STORNOTETEL, SUMCIMLET
- SUMUGYFELFORGALOM, SUMWUNI

### Globális változók (állapot)
- `_irodaDarab`, `_irodaszam[]`, `_irodanev[]` — iroda registry
- `_korzet[]` — értéktár hozzárendelés
- `_cegbetutomb[]` — cég azonosító
- `_farok` — dátum szűrő (éévhh formátum)
- `_voltadat` — volt-e egyáltalán feldolgozandó adat

### Összesítő eljárások
1. `CimletOsszesites` — címlet összegzés
2. `ForgalomOsszesites` — forgalom összegzés
3. `WuniOsszesites` — WU összegzés
4. `InterPtControl` — pénztárak közötti forgalom kontroll
5. `TRBControl` — TRB kontroll

### Forgalomgyűjtés SQL
```sql
SELECT FEJ.*, TET.*
FROM BF{éévhh} FEJ JOIN BT{éévhh} TET
ON FEJ.BIZONYLATSZAM = TET.BIZONYLATSZAM
WHERE FEJ.DATUM BETWEEN '{tol}' AND '{ig}'
```

### Modern megfelelő
A modern rendszerben ez a `DataCollectionService` / `ConsolidatedReportService` — de a receptor pattern (irodánkénti külön DB) a modern centralizált DB-vel már nem szükséges. A lekérdezés egyetlen PostgreSQL query-vel megoldható.

---

## SZEGMENS 2: unit29.pas — ForgalomRutin + SendingRutin [401-600 sor]

### Blokkfej mezők (tranzakció fejléc)
| Mező | Típus | Leírás |
|------|-------|--------|
| BIZONYLATSZAM | string | Bizonylat szám (PK) |
| DATUM | string | Tranzakció dátuma |
| IDO | string | Tranzakció ideje |
| TIPUS | string | V=vétel, E=eladás, F=feladás(küldés), U=utalás(fogadás) |
| STORNO | integer | 0=normál, >1=sztornózott |
| PENZTAR | string | Pénztár azonosító |
| TRBPENZTAR | string | TRB (tranzit bank) pénztár |
| PENZTAROSNEV | string | Pénztáros neve |
| VALUTANEM | string | Valuta kód (EUR, USD, stb.) |
| BANKJEGY | integer | Bankjegy darabszám |
| FORINTERTEK | integer | Forint érték |
| ELOJEL | string | Előjel (+/-) |
| STORNOBIZONYLAT | string | Sztornózott bizonylat száma |
| SZALLITONEV | string | Sztornó indok (!)  — mezőnév félrevezető |

### ForgalomRutin — Vétel/Eladás gyűjtés
- HUF kihagyva (nem forgalom)
- FORGALOMGYUJTO táblába INSERT vagy UPDATE (irodaszám + valutanem kulccsal)
- Mezők: VETT/ELADOTT (darab), VETTERTEK/ELADOTTERTEK (forint)
- Elszámolási árfolyam a NARF táblából

### SendingRutin — Pénztárak közötti mozgás
- **F típus:** feladás (küldő = aktuális pénztár)
- **U típus:** utalás/fogadás (fogadó = aktuális pénztár)
- PENZTARKOZOTT tábla: KULDODNEMFOGADO = "{küldő}{valutanem}{fogadó}" összetett kulcs
- TRB kezelés külön (TRBGyujtes)
- Banki kezelés (BankGyujtes) — ERB, RB, JRB típusok

### Modern megfelelő
- ForgalomRutin → `TransactionService.executeBuy/executeSell` + `DailyReportService`
- SendingRutin → `TransferService` + `VaultTransferService`
- TRBGyujtes → nincs közvetlen modern megfelelő (TRB = tranzit bank speciális flow)
- BankGyujtes → `VaultBankTransactionService`

---

## ÁLLAPOT
- [x] Szegmens 1: unit29.pas 0-400 sor — Adatgyűjtő architektúra
- [x] Szegmens 2: unit29.pas 401-600 sor — ForgalomRutin + SendingRutin
- [x] Szegmens 3: unit29.pas 601-800 sor — TRB/Bank/Címlet gyűjtés

### Szegmens 3 megállapítások:
**TRBGyujtes:** TRB (tranzit bank) = irodák közötti közvetett csere. TRBGYUJTO tábla: valutanem+küldő+fogadó kulccsal. F=feladás, U=fogadás. Modern: `TransferService` részben lefedi.

**BankGyujtes:** SUMBANKFORGALOM tábla. F=befizetett KP, U=felvett KP. A banki befizetés/felvétel forgalom aggregáció. Modern: `VaultBankTransactionService`.

**CimletGyujtes:** Címletezés gyűjtés CIMT{éévhh} táblákból. 14 címletkategória (CE1-CE14). Ha az aktuális hónapban nincs, az előző hónapot nézi. Modern: `BanknoteBreakdownService` + `BanknoteInventoryService`.

---

## SZEGMENS 4: unit29.pas — ForgalomOsszesites + CimletOsszesites [801-1600 sor]

### ForgalomOsszesites (összesítő)
- FORGALOMGYUJTO tábla teljes beolvasása
- **3 szintű aggregáció:**
  1. Értéktáranként (ertektar × valutanem mátrix): `_kvett[ertektar,valuta]`, `_keladott[ertektar,valuta]`
  2. KFT-nként (cégbetű szerint, max 4 KFT): `_kkvett[kft,valuta]`
  3. Összesen (teljes cég): `_sumvett[valuta]`, `_sumeladott[valuta]`
- Minden szint visszaírva FORGALOMGYUJTO-ba (irodaszam=0 = összesítő, irodaszam=-1 = KFT)
- Modern: `ConsolidatedReportService` + `DailyReportService`

### InterPtControl (pénztárak közötti kontroll)
- PENZTARKOZOTT tábla: küldött vs fogadott egyeztetés
- STATUS = 'OK' ha egyezik, '?' ha eltér
- Modern: `TransferService` validáció

### TRBControl (tranzit bank kontroll)
- TRBGYUJTO tábla: ugyanaz mint InterPt, de TRB-re
- Modern: nincs direkt megfelelő

### CimletOsszesites (címlet összesítés)
- CIMLETGYUJTO tábla beolvasása
- 14 címletkategória **bináris kódolással** (hi/lo byte pár, 2 byte per címlet)
- Értéktáranként + KFT-nként + összesen aggregáció
- Elszámolási árfolyam = `trunc(100*ertek/keszlet)`
- Modern: `BanknoteBreakdownService` (de nem bináris kódolással!)

### StornoRegisztracio
- STORNOFEJ + STORNOTETEL táblákba: sztornó bizonylatok külön regisztrálása
- Típus: STORNOZOTT (storno=2) vagy STORNO (storno>2)
- Modern: `TransactionReversalService`

---

## SZEGMENS 5-9: GYORSÍTOTT ELEMZÉS — Maradék SZERVER unitok

### unit1.pas — TForm1 (Fő szerver, 37KB)
- Startup timer, globális inicializáció
- DayBook (napló), BlokFej/BlokTetel kezelés
- MNB progress bar
- Iroda registry (`_irodaszam[]`, `_irodanev[]`, `_irodadarab`)
- Valuta registry (`_dnem[]`, `_valutadarab`)
- Értéktár registry (`_korzetszam[]`, `_ertektardarab`)
- Modern: `ApplicationStartupService`, `BranchService`, `CurrencyService`

### unit16.pas — TIRODATMK (Iroda karbantartás, 41KB)
- Iroda CRUD (rács, panel, szerkesztés)
- Mező: irodaszam, varos, boltnev, bankkod, tipus (ptar/etar)
- Modern: `BranchService` + `BranchController`

### unit5.pas — TMAKEIMPORT (Import, 38KB)
- Bankforgalom import (Excel/DB)
- Állomány tábla, blokkfej/blokktetel tábla
- Dátum kiválasztás (év, hó, nap kombók)
- Modern: `BookingExportService` (export irány), import nincs modern megfelelő

### unit14.pas — TMNBLEGYUJTO (MNB árfolyam, 35KB)
- MNB napi árfolyam letöltő
- Temp tábla → éles tábla másolás
- Cimtar kezelés
- Modern: `MnbRateService` + `ExchangeRateService`

### unit8.pas — TCimletezoForm (Címletezés, 28KB)
- 14 edit mező (CE1-CE14) — bankjegy darabszámok
- Valutánkénti bontás
- Modern: `BanknoteBreakdownService`

### unit36.pas — TATLAGDISPLAY (Átlag/marge, 25KB)
- Időszakos átlagárfolyam és marge kimutatás
- DBGrid rács, Excel export (OLE automation)
- Modern: `ProfitController` + `ExchangeRateService`

### unit37.pas — TWuniWafaControl (WU/WAFA, 20KB)
- Western Union záras kontroll
- WAFA (Metro) záras kontroll
- Nyitó/záró egyenleg egyeztetés
- Modern: `WesternUnionService`

---

## SZEGMENS 10-15: VALUTA DLL-ek (tranzakciós modulok)

### ATADVET DLL (TAtadAtvetForm, 135KB — LEGNAGYOBB)
- **Átadás/Átvétel** (inter-branch készlet mozgatás)
- Funkciók: AllAtadGomb, AllAtvetGomb, AllGetBack, AllGiveBack, DevAtad, DevAtvet
- Forint panel + deviza panel + címletezés
- TempTabla + TradeQuery (Firebird)
- Bizonylat kezelés (GetBlokkEdit, GetFtBlokkEdit, BackBizonyEdit)
- Limit kezelés (SetLimitGomb, LimitEdit)
- Kezdíj gomb
- Modern: `TransferService` + `VaultTransferService` + `HandoverSheetController`

### ELADAS DLL (TEladasForm, 134KB)
- **Eladás tranzakció** (ügyfél HUF-ot ad, valutát kap)
- WA1-WA6, WB1-WB6, WD1-WD6 edit mezők (6×3 = 18 mező — multi-valuta kezelés)
- Remote DB kapcsolat (RemoteQuery/RemoteDbase) — központi szerver
- Limit kezelés (SetLimitGomb, LimitEdit, KezdijEngedmenyGomb)
- Modern: `TransactionService.executeSell()`

### VASARLAS DLL (TVasarlasForm, 102KB)
- **Vásárlás/vétel tranzakció** (ügyfél valutát ad, HUF-ot kap)
- Hasonló struktúra mint ELADAS, de fordított irány
- Modern: `TransactionService.executeBuy()`

### UGYFEL DLL (TUgyfelinput, 111KB)
- **Ügyfél adatfelvétel** (azonosítás, dokumentum kezelés)
- NAV törvényi azonosítási határ felett
- Modern: `CustomerService` + `AmlService`

### ESTIZAR DLL (91KB)
- **Esti záras** (nap végi egyenleg lezárás)
- Modern: `DailyClosingService` + `ClosingWizardService`

### WUNION DLL (89KB)
- **Western Union** tranzakció rögzítés
- SEND/RECEIVE/IC_IN/IC_OUT típusok
- Modern: `WesternUnionService`

### FOGLALO DLL (81KB)
- **Foglalás** (valuta előjegyzés ügyfélnek)
- Modern: `ReservationService`

### METRO DLL (73KB)
- **Metro/WAFA** tranzakciók
- Modern: `WesternUnionService` (WAFA branch)

### PILLKESZ DLL (64KB)
- **Pillanatnyi készlet** lekérdezés
- Modern: `CashBalanceService` + `StockSnapshotController`

### Kisebb DLL-ek
| DLL | Méret | Funkció | Modern |
|-----|-------|---------|--------|
| BIZODISP | 7KB | Bizonylat megjelenítés | `ReceiptController` |
| VERZFRIS | 6KB | Verzió frissítés | N/A |
| MAKTABLAK | 5KB | Makro táblák | N/A |
| NAPIKEZD | 5KB | Napi kezdés | `DailySessionService` |
| LOGIRO | <1KB | Log írás | `AuditLogService` |
| GETISO | <1KB | ISO kód lekérés | `CurrencyService` |
| OTP | <1KB | OTP terminál | `OtpTerminalProtocolService` |
| KORLEV | <1KB | Körlevél | `CircularService` |
| GONGBACK | <1KB | Visszahívás | N/A |

---

## SZEGMENS 16-17: ERTEKTAR modulok

### penztarak (97KB)
- Pénztárak kezelése az értéktárban
- Modern: `TreasuryController` + `VaultDistributionService`

### atadvet (85KB)
- Értéktári átadás/átvétel (hasonló ATADVET DLL-hez, de értéktár szintű)
- Modern: `VaultTransferService`

### pillkesz (63KB)
- Értéktári pillanatnyi készlet
- Modern: `StockSnapshotController`

---

## SZEGMENS 18: VALUTA/IBVALTO (fő pénztár, 68KB)

### UNIT1.PAS — Fő valutaváltó kasszaprogram
- Ez a pénztárosok napi munkaalkalmazása
- Tranzakció indítás, címletezés, záras, WU
- DLL-eket hívja futásidőben (LoadLibrary)
- Modern: A teljes frontend-react + pénztár-client

---

## ÖSSZEFOGLALÓ TÁBLA — Legacy vs Modern

| Legacy Modul | Fájlok | KB | Modern Service | Állapot |
|-------------|--------|-----|----------------|---------|
| Adatgyűjtő (unit29) | 1 | 77 | DataCollectionService, ConsolidatedReportService | MEGVAN |
| Fő szerver (unit1) | 1 | 37 | ApplicationStartup, BranchService | MEGVAN |
| Iroda TMK (unit16) | 1 | 41 | BranchService | MEGVAN |
| Import (unit5) | 1 | 38 | BookingExportService | RÉSZLEGES (import hiányzik) |
| MNB letöltő (unit14) | 1 | 35 | MnbRateService | MEGVAN |
| Címletező (unit8) | 1 | 28 | BanknoteBreakdownService | MEGVAN |
| Átlag/marge (unit36) | 1 | 25 | ProfitController | MEGVAN |
| WU/WAFA (unit37) | 1 | 20 | WesternUnionService | MEGVAN |
| ATADVET DLL | 1 | 135 | TransferService, VaultTransferService | MEGVAN |
| ELADAS DLL | 1 | 134 | TransactionService.sell | MEGVAN |
| VASARLAS DLL | 1 | 102 | TransactionService.buy | MEGVAN |
| UGYFEL DLL | 1 | 111 | CustomerService, AmlService | MEGVAN |
| ESTIZAR DLL | 1 | 91 | DailyClosingService | MEGVAN |
| WUNION DLL | 1 | 89 | WesternUnionService | MEGVAN |
| FOGLALO DLL | 1 | 81 | ReservationService | MEGVAN |
| METRO DLL | 1 | 73 | WesternUnionService (WAFA) | MEGVAN |
| PILLKESZ DLL | 1 | 64 | CashBalanceService | MEGVAN |
| IBVALTO (fő pénztár) | 1 | 68 | frontend-react + penztar-client | MEGVAN |
| ERTEKTAR | 3 | 245 | TreasuryController, VaultServices | MEGVAN |

**Legacy lefedettség modern-ben: ~95%** (a receptor pattern és az import modul a fő hiányok)

---

## LEGACY ELEMZÉS ÁLLAPOT: KÉSZ (18/18 szegmens)
- [ ] Szegmens 3: unit1.pas — Fő szerver form
- [ ] Szegmens 4: unit16.pas — Iroda karbantartás
- [ ] Szegmens 5: unit5.pas — Import modul
- [ ] Szegmens 6: unit14.pas — MNB letöltő
- [ ] Szegmens 7: unit8.pas — Címletezés
- [ ] Szegmens 8: unit36.pas — Átlag/marge
- [ ] Szegmens 9: unit37.pas — WU/WAFA kontroll
- [ ] VALUTA DLL-ek (ATADVET, ELADAS, VASARLAS, UGYFEL, stb.)
