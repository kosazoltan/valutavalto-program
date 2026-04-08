---
type: analysis
scope: workspace-shared
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Valutavalto Delphi Teljes Forras Elemzes (2026-04-04)"
load: on-demand
---

# Valutavalto Delphi Teljes Forras Elemzes (2026-04-04)

> **Elemzo:** Eszter (Controller Chief)
> **Scope:** `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\` — SZERVER + ERTEKTAR + VALUTA + VALUTA\TRADE
> **Delphi verzio:** Delphi 7 (Borland), Object Pascal
> **Adatbazis:** Firebird (InterBase komponensek: TIBDatabase, TIBQuery, TIBTable, TIBTransaction)
> **Karakter kodolas:** WIN1250 (magyar)

---


---

## S1 OSSZEFOGLALO

A Valutavalto program teljes Delphi forrasbazisa 4 fo rendszert tartalmaz, osszesen ~645.000 Pascal sor:

| Rendszer | Fo alkalmazas | DLL-ek | Fejlesztesi modulok | Leiras |
|----------|--------------|--------|---------------------|--------|
| **SZERVER** | server.exe (37 form) | 36 ujdll | ~96 fejleszt modul | Kozponti admin, MNB jelentes, arfolyam, jutalek, booking |
| **ERTEKTAR** | (DLL-alapu) | ~60 etdll | 3 fejleszt | Ertektar kezeles: plomba, cimlet, napzar, penztar |
| **VALUTA** | ibvalto.exe | ~90+ DLL | - | Penztari kliens (vetel/eladas/WU/bizonylat) |
| **TRADE** | trade.exe | - | 3 fejleszt | Tozsdei funkcio |

**Architektura:** Klasszikus Delphi 7 fat-client → Firebird adatbazis. A DLL-ek `stdcall` exportokkal rendelkeznek, amiket a fo alkalmazasok `LoadLibrary`/`external` deklaracioval toltenek be. Minden DLL kulon `.dpr` projektfajl, altalaban 1-2 unit (unit1=form, unit2=logic). Az adatbazis-kapcsolat Firebird `.fdb` fajlokra mutat (pl. `c:\receptor\database\receptor.fdb`, `C:\RECEPTOR\DATABASE\V{irodaszam}.FDB`).

**Kritikus felismeres:** A rendszer rendkivul modularis — a fo `server.exe` 37 formbol all, es ~36 kulon DLL-t hiv meg a kulonbozo admin funkciokhoz. Ez a 2000-es evek Delphi architekturajara jellemzo pattern (DLL = plugin).

---


---

## S2 1_SZERVER_KOZPONTI_ADMIN

### 1.1 server.exe (fo alkalmazas — 37 form)

A fo `server.dpr` projekt 37 Delphi formothoz letre (`Application.CreateForm`). Ez a kozponti admin alkalmazas, amely a valutavalto halozat osszes irodajat kezeli.

| Unit | Form nev | Funkcio |
|------|----------|---------|
| Unit1 | Form1 | **Fo ablak** — MNB adatbazis kapcsolat, MNB tabla olvasas (VALUTANEM, IRODASZAM, ZARO, SZAMITOTTZARO, MEGJEGYZES), irodak vegigolvasasa |
| Unit2 | GETDATADISP | Adat lekerdezes megjelenito |
| Unit3 | RENDSZERADATOK | Rendszer konfiguracio megjelenites |
| Unit4 | ATTEKINTES | Attekinto nezet (osszegzo dashboard) |
| Unit6 | MNBLISTAK | MNB listak — SQL: `SELECT * FROM MNB`, MNB adatok exportja Excel CSV-be |
| Unit7 | HIBAKDISPLAY | Hibak megjelenitest (MNB elteresjegentes) |
| Unit8 | CIMLETEZO | Cimlet kezelese — CREATE TABLE dinamikus tabla letrehozas |
| Unit9 | IDOSZAKBEFORM | Idoszak bekerese (datum-intervallum) |
| Unit10 | FOMENUFORM | Fomenu form — navigacio |
| Unit11 | HIANYZOZARASOKFORM | Hianyzo zarasok megjelenites |
| Unit12 | USERFORM | Felhasznalo kezeles |
| Unit13 | KEZIADATPOTLASFORM | Kezi adat potlas (manualis adatbevitel) |
| Unit14 | MNBLEGYUJTO | **MNB legyujto** — MNB tabla uritese + ujratoltese: irodankent vegigolvas, cimletek + zarokeszletek → MNB tabla INSERT. MNB adatbazis: MNBDBASE, MNBTABLA, MNBTRANZ + MNBTEMPTABLA |
| Unit15 | UGYFELFORGALOMPOTLO | Ugyfel forgalom potlo |
| Unit16 | IRODATMK | **Iroda karbantarto** — CREATE TABLE: napi arfolyamok, havi zaras, elszamolas, napi forgalom. Firebird `receptor.fdb` + iroda-specifikus `V{irodaszam}.FDB`. Tablak: DAYB*, ELOHAVI, ELONAPI, JOGISZEMELY, UGYFELEK, MAINCURR |
| Unit17 | MNBLISTADISPLAY | MNB lista megjelenitese — `SELECT SUM(VETELDARAB),SUM(ELADASDARAB) FROM MNB` |
| Unit18 | GETUZLETSZAM | Uzlet szam bekerese |
| Unit19 | CIMLETLISTA | Cimlet lista |
| Unit20 | KELLTEGNAP | Tegnapi adatok ellenorzese |
| Unit21 | ARFOLYAMTMK | **Arfolyam karbantarto** — arfolyam modositas, elteres kezeles |
| Unit22 | STORNODISP | Storno megjelenites |
| Unit23 | FORGALOMDISPLAY | Forgalom megjelenites |
| Unit24 | KESZLETDISPLAY | Keszlet megjelenites |
| Unit25 | WUNIDISPLAY | **Western Union megjelenites** |
| Unit26 | BANKFORGALOMDISPLAY | Bank forgalom megjelenites |
| Unit27 | PENZTARKOZOTTIDISPLAY | Penztarkozotti (inter-penztar) megjelenites |
| Unit28 | ADATMENU | Adat menu |
| Unit29 | ADATLEGYUJTES | **Adat legyujtes** — Western Union osszesites felirat, havi western-zaras |
| Unit30 | TRBDISPLAY | TRB (tranzakcio bejegyzes) megjelenites |
| Unit31 | JUTSZAM | Jutalek szamitas |
| Unit32 | JUTALEKSZAZALEK | Jutalek szazalek beallitas |
| Unit33 | ATLAGARFOLYAM | Atlag arfolyam szamitas |
| Unit34 | ARFOLYAMELTERITES | Arfolyam elterites (specialis arfolyam beallitas) |
| Unit35 | KEDVEZMENYLISTA | Kedvezmeny lista |
| Unit36 | ATLAGDISPLAY | Atlag megjelenites |
| Unit37 | WUNIWAFACONTROL | **WU/WAFA control** — Western Union + WAFA nyitokeszlet/zarokeszlet INSERT/UPDATE |

### 1.2 Fejlesztesi modulok (~96 db) — tablazat + kulcs modulok reszletezese

A `SZERVER\fejleszt\` konyvtar a kulonallo segdprogramokat es eszkozoket tartalmazza, melyek a szerver admin funkcioihoz tartoznak:

| Modul | Tipus | Leiras |
|-------|-------|--------|
| **archival** | EXE | Archivalas — regi adatok archivalasa |
| **arfolyam** (4 verzio: v20-v22 + old) | EXE | **Arfolyam szamito** — penztar-csoport szintu arfolyam karbantartas, fuggveny-alapu arfolyam szamitas (EgyFuggvenyKiszamitasa, CsoportLapAtszamolo, SummaTagok). Iroda- es csoport-szintu arfolyam ujraszamitas. |
| **banklist** | EXE | Bank lista — bizonylat kereses 2018-2019 evekre, bizonylatsz am szerinti szures |
| **beszam** | EXE | **Beszamolo keszito** — ertektar osszefoglalo elemzes Excel-be: ugyfelsz am, arfolyam, bizonylatolasi modszerek, proba valtas. Western Union tablo generalas. |
| **booking** (7 almodul) | DLL+EXE | **Konyveles** — AdatlegyujtoProgram, BookingControl, Konyveles, MakeFdb, MakeTranzTabla, MakeAdvetTabla, ExcelOpen, PenztarBeolvasas. Teljes konyvviteli rendszer: adatvet Excel, forgalom Excel, keszlet Excel. |
| **confident** | EXE | Titkos/bizalmas adatok kezelese |
| **etrade** | EXE | Elektronikus kereskedes |
| **everseny** | EXE | Verseny (arfolyam-verseny iranytablak) |
| **evitranz** | EXE | Eves tranzakcio osszesites |
| **evnyito** | EXE | **Evnyito** — uj ev inditas: FOGLALO tabla torlese (`DELETE FROM FOGLALO`) + uj ev inicializalasa |
| **expadvet** | EXE | Expressz akszerhaz es Minibank Western Union penzsz allitasai — Excel kimenet |
| **expevnyito** | EXE | Exportalas evnyito |
| **expgbakall** | EXE | Export GBK allapot |
| **fdbtomorito** | EXE | FDB tomorito — Firebird adatbazis karbantartas |
| **fdbtorlo** | EXE | FDB torlo — regi adatbazisok torlese |
| **foglalo** | EXE | **Foglalo** — 5 foglalo kezeles irodankent (1..150 penztar, 0..4 foglalo), FTP-n keresztul letoltes, Excel export korzetenkent |
| **forgdisp** | EXE | Forgalom megjelenites |
| **frissdat** | EXE | Adat frissites |
| **gbakall** | EXE | GBK allapot kezeles |
| **haszon** | EXE | **Haszon szamitas** — profit kalkulator |
| **havitablo** | EXE | Havi tablo generalas |
| **havitrad** | EXE | Havi trade osszesites |
| **helga** (10 almodul) | DLL+EXE | **HELGA rendszer** — helyi szerver. Lasd reszletes elemzes lentebb. |
| **hrkvetel** | EXE | HRK (hitelkartya) vetel kezeles |
| **idbeiro** | EXE | ID beiro |
| **jelenlet** | EXE | Jelenleti iv / dolgozo nyilvantartas |
| **jogiszemely** | EXE | **Jogi szemely** — jogi szemely ugyfelek kezelese (BIZONYLATSZAM szerinti kereses) |
| **jutmend** | EXE | Jutalek modositas |
| **kdchange** | EXE | Kezdokeszlet valtozas |
| **kereso** | EXE | Altalanos kereso |
| **kezdij** | EXE | Kezdodij beallitas, cegbetoltes |
| **korlevel** (3 almodul) | EXE | **Korlevel** — korlevel keszites es evnyito korlevel. Zsuzsa almodul: indito + evnyito. |
| **lemento** | EXE | **Lemento** — bizonylatok mentese binaris fajlba, bizonylat + blokk tetelek kiolvasasa |
| **listopenoffices** | DLL | Nyitott irodak listazo DLL |
| **litenews** | EXE | Hirek megjelenites |
| **makeszlt** | EXE | Szamlalevl keszites + Excel |
| **makiroda** | EXE | Iroda letrehozas |
| **mendjogi** | EXE | Jogi szemely modositas |
| **mentes** | EXE | Mentes — adatbazis mentes |
| **monegram** | EXE | **MoneyGram** integracio — MoneyGram penzkuldesi rendszer |
| **napiment** | EXE | Napi mentes |
| **nevseek** | EXE | Nev kereso |
| **newrate** | EXE | Uj arfolyam beallitas |
| **newyear** | EXE | Uj ev inicializalasa |
| **okmctrl** | EXE | **Okmany control** — okmany (szemely/igazolvany) ellenorzes es kezeles |
| **orsoseek** | EXE | Orso kereso |
| **palyadij** | EXE | Palyadij szamitas |
| **permit** | EXE | Jogosultsag kezeles |
| **personal** (3 almodul) | EXE | Szemelyzeti kezeles — kereso, tolto |
| **police** (4 almodul) | EXE | **Rendorsegi megkereses** — rendorsegi adatlekerdezesek + kereso, tobb verzio |
| **postterm** | EXE | POS terminal integracio |
| **ptforg** | EXE | Penztar forgalom kontrol |
| **pttrfee** | EXE | Penztar tranzakcio dij |
| **recguard** | EXE | Receptor guard — receptor biztonsagi modul |
| **recptor** (6 almodul) | EXE+DLL | **Receptor** — fo receptor alkalmazas, kedvezmeny, tabla makro, getlett |
| **remaltib** | EXE | Altalanos IB (InterBase) muveletek |
| **server** | EXE | **Fo server alkalmazas** — lasd 1.1 |
| **setrade** | EXE | Set trade |
| **statiszt** (2 almodul) | EXE | Statisztika + CartCash statisztika |
| **summa** | EXE | Summa — osszegzo |
| **sumrate** | EXE | Osszesitett arfolyam |
| **sumtablo** | EXE | Osszesito tablo |
| **sumtrade** | EXE | Osszesitett trade (elektronikus kereskedes) |
| **tablomak** | EXE | Tabla makro |
| **terror** | EXE | **Terrorlista** — ENSZ Biztonsagi Tanacs szankcios listarol (un.org) XML letoltes, parseolas, UNOLIST Firebird tablaba mentes. Lasd reszletes elemzes. |
| **tiltcopy** | EXE | Masolasvedelem |
| **tranzacs** | EXE | Tranzakcio kezeles |
| **tranzdb** | EXE | Tranzakcio adatbazis |
| **tranzdij** | EXE | Tranzakcio dij szamitas |
| **trnzstat** | EXE | Tranzakcio statisztika |
| **uctrl** (8 almodul) | EXE | **Ugyfel kontrol** — adatpotlo, atvitel, butitott ugyfctrl, hibakereso, mend, regeneral, svisor, u2text, ugyfcreat (ugyf2fdb), ugyfreg |
| **ufill18** | EXE | Ugyfel feltoltes 2018 |
| **ufill19** | EXE | Ugyfel feltoltes 2019 |
| **uforg** | EXE | Ugyfel forgalom |
| **ugyfelcontrol** (13 almodul) | DLL+EXE | **Ugyfel kontrol rendszer** — Lasd reszletes elemzes. |
| **ugyfseek** | EXE | Ugyfel kereso |
| **verseny** | EXE | Verseny — arfolyam verseny |
| **verseny_mend** | EXE | Verseny modositas |
| **vevo** | EXE | Vevok kezelese |
| **vevoszam** (3 verzio) | EXE | Vevo szam nyilvantartas |
| **western** | EXE | **Western Union** — Ertektar WU adatok, Excel tablo generalas. Lasd reszletes elemzes. |
| **westuni** | EXE | Western Union masodik verzio |
| **wucontrol** | EXE | WU kontrol |
| **wuniforg** | EXE | WU forgalom |
| **_arfteszt** | EXE | Arfolyam teszt |
| **_napiforg** | EXE | Napi forgalom |

#### Kulcs modulok reszletes elemzese

**terror (Terrorlista kezelo):**
- URL: `https://www.un.org/securitycouncil/content/un-sc-consolidated-list`
- TWebBrowser-rel letolti az ENSZ szankcios listat XML formatumban
- Parseoli az XML-t: `FIRST_NAME`, `SECOND_NAME`, `THIRD_NAME` mezokbol nev osszeallitas
- `DELETE FROM UNOLIST` → `INSERT INTO UNOLIST (TERROR_NAME)` — frissites teljes ujratoltessel
- FDB host: `185.43.207.99` (tavoli szerver)
- Betukiemelo function: nevek nagybetus formazasa

**western (Western Union elemzo):**
- Tobb adatbazis-kapcsolat: RECQUERY/RECDBASE (receptor), VQUERY/VDBASE (valuta), ARTQUERY/ARTDBASE (arfolyam)
- Excel kimenet: irodankenti WU forgalom
- Kulcs procedurak: ErtektarWuData, MakeExcel, HaviWesternTablo, PenztarWuData, EgyNapiAdatFeltoltes, Korzetbesorolas
- Adatellenorzes + hibakiras

**ugyfelcontrol (Ugyfel kontrol rendszer):**
- Fo alkalmazas: `ugyfctrl.exe` — fomenu 5 gombbal: Idoszak kereso, Ugyfel kereso, Evi max, Terror naplo, Uj import
- 13 DLL-t tolt be kulon funkciokhoz:
  - `terrnaplo.dll` — terror naplo
  - `evimax.dll` — evi maximum tranzakciok (300.000+ Ft kotelezz ugyfelkezelest)
  - `kereso.dll` — kereso + tiltasok
  - `lista.dll` — adat lista
  - `ujimport.dll` — uj import
  - `adatgyujto.dll` — adatgyujto
  - `idoszak.dll` / `idoszakos.dll` — idoszak kezeles
  - `import.dll` — import
  - `letilt.dll` — letiltas (ugyfel/tranzakcio tiltas)
  - `makeexcel.dll` — Excel export
  - `okmdisp.dll` — okmany megjelenites
  - `tiltasok.dll` — tiltasok kezelese
- Tavoli DLL utvonal: `c:\uctrl\bin\` — on-site telepites

**booking (Konyveles):**
- Teljes konyvelesi modul: adatgyujtes, bizonylat kezeles, forgalom, keszlet
- Excel output: adatvet Excel, forgalom Excel, keszlet Excel
- BookingControl, Konyveles procedurak: automatikus konyvelesi tetel generalas
- Bizonylatsz am kezeles: uj bizonylatsz amnal fizetendo kerekitessel modositas

**arfolyam (Arfolyam szamito — 4 verzio):**
- Fuggveny-alapu arfolyam szamitas: `EgyFuggvenyKiszamitasa`, `Fuggvenybontas`, `FvenybolNum`
- Iroda-csoport szintu arfolyam: `CsoportLapAtszamolo`, `CsoportTagSzamito`
- Summa-tagok szamitas: osszetett arfolyam keplet kiertekeles
- ErtekControl: arfolyam-validalas
- 4 verzio (v20, v21, v22 + old): evolucio a szamitasi logikaban

**helga (HELGA — helyi szerver rendszer):**
- `locserver.exe` — helyi admin szerver, 9 kulso DLL-t tolt be:
  - `arftmk.dll` — arfolyam karbantarto
  - `beerk.dll` — beerkezett adatok
  - `mnbhibak.dll` — MNB hibak listazo
  - `jszorzo.dll` — jutalek szorzo
  - `import.dll` — import feliro
  - `zarasctrl.dll` — zaras beerkezesek
  - `irtmk.dll` — iroda karbantarto
  - `westforg.dll` — Western forgalom
  - `dolgjutalek.dll` — dolgozo jutalek szamito
- 10 almodulban DLL-ek: arftmk, beerk, dolgozok, import, irtmk, mnbhibak, tranzdij, westforg, zarasok

### 1.3 Uj DLL-ek (36 db) — tablazat

A `SZERVER\ujdll\` konyvtar a szerver alkalmazas altal hasznalt uj generacios DLL-eket tartalmazza:

| DLL modul | Makedll nev | Funkcio | Kulcs SQL muvelet |
|-----------|-------------|---------|-------------------|
| adatgyujto | legyujto.dll | Adat legyujto — 11 tabla uritese es ujratoltese | `DELETE FROM {tabla}` (11x) |
| arftmk | arftmk.dll | Arfolyam karbantarto — arfolyam modositas | `DELETE FROM ARFOLYAM` |
| atlagarf | atlagarf.dll | Atlag arfolyam szamitas | `DELETE FROM ATLAGARFOLYAM` |
| bankforg | bankdisp.dll | Bank forgalom megjelenites | - |
| beerkctrl | missctrl.dll | Beerkezes kontrol — hianyzo adatok | - |
| beerkezes | beerk.dll | Beerkezett adatok feldolgozasa | `DELETE FROM ADATATADO` |
| bejelentes | - | Bejelentes kezelese | - |
| datadisp | datadisp.dll | Adat megjelenites | - |
| dbookctrl | dbctrl.dll | **DayBook kontrol** — napi konyvelo tabla kezeles | `CREATE TABLE` (4x: tranz, eng, pterm tablak) |
| dolgozok | dolgozok.dll | Dolgozo kezeles | `DELETE FROM PENZTAROSOK WHERE SORSZAM=...` |
| forgalomdisp | forgdisp.dll | Forgalom megjelenites | - |
| getdisp | getdisp.dll | Adat lekerdezes megjelenites | - |
| getuzlet | getegyseg.dll | Uzlet/egyseg lekerdezes | `DELETE FROM ADATATADO` |
| hovalasz | hovalasz.dll | Honap valaszto | `DELETE FROM IDOSZAK` (2x) |
| hrkserver | hrk.dll | HRK szerver — hitelkartya tabla kezeles | `DELETE FROM {hrkTablaNev}` |
| idoszak | idoszak.dll | Idoszak kezeles | `DELETE FROM IDOSZAK` |
| import | import.dll | Import — adat importalas | `DELETE FROM SUMALLOMANY`, `SUMBANKFORGALOM`, `SUMUGYFELFORGALOM` |
| irtmk | irtmk.dll | **Iroda karbantarto** | `CREATE TABLE MAINCURR`, `ELOHAVI`, `ELONAPI` |
| jutszamito | dolgjutalek.dll | **Jutalek szamito** — penztaros jutalek kalkulator | `DELETE FROM PENZTAROSFORGALOM`, `DELETE FROM JUTALEK` |
| jutszazalek | jutszaz.dll | Jutalek szazalek beallitas | - |
| keszletdisp | keszdisp.dll | Keszlet megjelenites | - |
| kezdij | kezdij.dll | Kezdodij beallitas | `DELETE FROM {tabla}`, `CREATE TABLE {tabla}` |
| kezdtranzdisp | kdtrdisp.dll | Kezdo tranzakcio megjelenites | - |
| mnbgyujto | gyujto.dll | **MNB gyujto** — MNB adat gyujtes es feldolgozas | `DELETE FROM MNB` |
| mnbhibak | mnbhibak.dll | MNB hibak megjelenites | - |
| ptarkozott | ptkdisp.dll | Penztarkozotti megjelenites | - |
| stornodisp | stornodisp.dll | Storno megjelenites | - |
| sumwuafa | sumwuafa.dll | **WU + WAFA osszesites** | - |
| tranzakc | tranzdij.dll | **Tranzakcio dij** — havi tranzakcio tabla kezeles, elszamolas tabla | `DELETE FROM {haviTranzTablaNev}`, `CREATE TABLE {haviTranzTablaNev}`, `CREATE TABLE {haviElszamTablanev}` |
| trbdisp | trbdisp.dll | TRB megjelenites | - |
| unpacker | unpacker.dll | **Unpacker** — adatcsomag kicsomagolasa | `DELETE FROM FOGLALO`, `DELETE FROM VTEMP`, `DELETE FROM {tabla}` (tobbszor) |
| userbelep | userin.dll | **Felhasznalo belepes** — user autentikacio | `DELETE FROM USERS` |
| western | westforg.dll | **Western Union forgalom** | - |
| wuafatranz | wuwaadvet.dll | **WU + WAFA tranzakciok** | `DELETE FROM WAFATRANZ`, `DELETE FROM WUNITRANZ` |
| wunidisp | wudisp.dll | WU megjelenites | - |
| zarasctrl | zarasctrl.dll | **Zaras kontrol** — napzar/havizar ellenorzes | - |

---


---

## S3 2_ERTEKTAR_ERTEKTAR

### 2.1 Fo struktura

Az ERTEKTAR rendszer az ertektar (safe/vault) kezeleset vegzi — penztar-szintu fizikai keszlet, cimlet, plomba, napizar, havizar. Harom fo resze:
- `database/` — Firebird adatbazis fajlok + mentes
- `etdll/` — ~60 DLL modul (ertektar-specifikus)
- `fejleszt/` — 3 fejlesztoi modul

### 2.2 etdll modulok (~60 db) — tablazat + kulcs modulok

| DLL modul | Makedll nev | Funkcio | Kulcs SQL |
|-----------|-------------|---------|-----------|
| arftmk | arftmk.dll | Arfolyam karbantarto | `DELETE FROM ARFOLYAM` |
| atadolap | atadolap.dll | Atadasi adatlap — ertektar atadas dokumentum | - |
| atadvet | atadvet.dll | **Atadasi veto** — VTEMP, BLOKKFEJ, BLOKKTETEL, CIMLETPISZKOZAT torlese es ujraepites | `DELETE FROM VTEMP`, `BLOKKFEJ`, `BLOKKTETEL`, `CIMLETPISZKOZAT` |
| bizodisp | bizodisp.dll | Bizonylat megjelenites | `DELETE FROM VTEMP` |
| bloknyom | bloknyom.dll | Blokk nyomtatas — bizonylat blokk nyomtatasa | - |
| checklst | checklst.dll | Ellenorzo lista — napi tevekenysegek checklistja | - |
| cimlctrl | cimlctrl.dll | **Cimlet kontrol** — cimlet ellenorzes | - |
| cimlet | cimlet.dll | Cimlet kezeles | `DELETE FROM CIMLETEK` |
| cimlmenu | cimlmenu.dll | Cimlet menu | - |
| cimlnyom | cimlnyom.dll | Cimlet nyomtatas | - |
| cimsetup | cimsetup.dll | Cimlet beallitas | - |
| estizar | estizar.dll | Esti zaras — nap vegi zaras inditasa | - |
| getarf | getarf.dll | Arfolyam lekerdezes | - |
| getellen | getellen.dll | Ellenorzes lekerdezes | - |
| getplomb | getplomb.dll | **Plomba lekerdezes** — plomba (pecsét) szam lekerdezes | - |
| getptar | getptar.dll | Penztar lekerdezes | - |
| havizar | havizar.dll | **Havi zaras** — havi zarasi tabla letrehozas es feltoltes | `DELETE FROM {hzTablanev}`, `CREATE TABLE {hzTablaNev}` |
| hrkatvevo | hrkget.dll | HRK atvevo — hitelkartya atvetel | - |
| hrkcimlet | hrkcim.dll | HRK cimlet | - |
| idoszak | idoszak.dll | Idoszak kezeles | `DELETE FROM IDOSZAK` |
| irarfoly | irarfoly.dll | Iranyado arfolyam beallitas | - |
| kcimlet | kcimlet.dll | Keszpenz cimlet | - |
| keszedit | keszedit.dll | Keszlet szerkesztes | `DELETE FROM CIMLETPISZKOZAT` |
| keszup | keszup.dll | Keszlet frissites | - |
| kezdij | kezdij.dll | Kezdodij | `DELETE FROM VTEMP` |
| korlev | korlev.dll | **Korlevel** — iktatoszam kezeles | `DELETE FROM IKTATO` |
| listak | listak.dll | **Listak** — penztarforgalom listak | `DELETE FROM VTEMP`, `DELETE FROM PENZTARFORGALOM` |
| logdisp | logdisp.dll | Log megjelenites | - |
| logiro | logiro.dll | Log iras — esemenynaplozas | - |
| maktablak | maktabla.dll | **Tabla letrehozo makro** — 10+ tabla: fejfile, tetfile, ctfile, narffile, kezdij, kdat, eker, edat, wufile, wzfile | `CREATE TABLE` (10+ tabla) |
| matptar | matptar.dll | Masolat penztar | `DELETE FROM VTEMP` |
| mentes | mentes.dll | Mentes — adatbazis biztonsagi mentes | - |
| napijel | napijel.dll | **Napi jelentes** — napi zarasi jelentes | `DELETE FROM VTEMP`, `DELETE FROM NAPIZAR` |
| napikezd | napikezd.dll | Napi kezdes — napi nyitas | `DELETE FROM NAPIKEZD WHERE DATUM=...` |
| napkonyv | napkonyv.dll | **Napi konyv** — napi konyvelesi naplo | `DELETE FROM NAPLO WHERE DATUM=...`, `DELETE FROM NAPIKONYV WHERE DATUM=...` |
| napzar | napzar.dll | **Napi zaras** — nap vegi zarasi procedura | - |
| nifval | nifval.dll | NIF validalas | - |
| nznyomt | nznyomt.dll | Napzar nyomtatas | - |
| penztarak | ptarak.dll | Penztarak kezelese | - |
| pictload | pictload.dll | Kep betoltes — okmany kep betoltese | - |
| pillall | pillall.dll | Pillanatnyi allapot — aktualis keszlet nezet | - |
| pillkesz | pillkesz.dll | Pillanatnyi keszlet + grafikon | - |
| prosbe | prosbe.dll | Provizio bekereso | - |
| prostmk | prostmk.dll | Provizio karbantarto | - |
| ptarkesz | aktkesz.dll | Penztar keszlet — aktualis keszlet | - |
| ptartmk | ptartmk.dll | Penztar karbantarto | - |
| quitform | quitform.dll | Kilepo form | - |
| ratectrl | ratectrl.dll | **Rate kontrol** — arfolyam kontrol es validalas | - |
| rateperm | rateperm.dll | Rate permission — arfolyam engedelyezes | - |
| regen | regen.dll | Regeneralas | - |
| regizaro | regizaro.dll | Regi zaras | - |
| storno | storno.dll | **Storno** — tranzakcio stornozas | - |
| super | super.dll | **Super** — supervisor mod (emelt jogosultsag) | - |
| supertsk | supertsk.dll | Supervisor task | - |
| terminal | terminal.dll | Terminal kezeles | - |
| wunion | wunion.dll | **Western Union** — WU tranzakcio kezeles ertektar szinten | - |

### 2.3 Fejlesztesi modulok

| Modul | Leiras |
|-------|--------|
| frissito | Adatbazis frissito |
| newyear | Uj ev inicializalasa |
| permit | Engedelyezesi rendszer |

---


---

## S4 3_VALUTA_DELTA_19_UJ_PAS_MODOSITAS

A VALUTA rendszer (penztari kliens) nem a fo fok usz ebben a korben, de az uj/modositott elemek:

| Terulet | Fontos modulok |
|---------|----------------|
| **QRDEPUTY** | QR kod generalas — QRGENER.DPR (deputy + zarotest) |
| **QRGENER** | QR kod generalo fo modul — napzar QR kod |
| **NAVZARO** | **NAV zaras** — NAV (adohatosag) fele zarasi jelentes |
| **SENDOKMANY** | Okmany kuldes — szkennelt okmanyok tovabbitasa |
| **UJSCANNER** | Uj szkenner modul — okmany beolvaso |
| **BIGCTRL** | Nagy kontrol — 300.000+ Ft feletti tranzakciok kezelese |
| **BIGARFVALT** | Nagy arfolyamvaltas — nagy osszegu arfolyam muveletek |
| **KISARFVALT** | Kis arfolyamvaltas |
| **EUAKCIO** | EU akcio — EUR specialis akciok |
| **METRO** | Metro lokacio specifikus |
| **TESCO** | Tesco lokacio specifikus |
| **TEAOR** | TEAOR (gazdasagi tevekenyseg) valaszto |
| **OTP** / **OTPLOG** | OTP bank integracio + log |
| **FOGLALO** / **FOGLREND** | Foglalasi rendszer |
| **TERROR** | Terror lista DLL verzio (penztari kliens oldal) |

---


---

## S5 4_KRITIKUS_UZLETI_SZABALYOK

A forrasbol azonositott legfontosabb uzleti szabalyok:

### 4.1 MNB Jelentes (Magyar Nemzeti Bank)
- **Napi MNB legyujtes:** Minden irodabol beerkezett adatok (VALUTANEM, VETELDARAB, ELADASDARAB, ZARO, SZAMITOTTZARO) legyujtese a kozponti MNB tablaba
- **MNB listaz k:** Elteres kimutatasa a szamitott es tenyleges zarokeszlet kozott (MEGJEGYZES mezo)
- **MNB tabla:** `SELECT * FROM MNB`, `SELECT SUM(VETELDARAB), SUM(ELADASDARAB) FROM MNB`

### 4.2 Arfolyam rendszer
- **Fuggveny-alapu arfolyam szamitas:** Nem egyszeruz statikus arfolyam, hanem osszetetett fuggvenyekkel szamolt (`EgyFuggvenyKiszamitasa`, `Fuggvenybontas`, `SubFvbontas`)
- **Csoport-szintu arfolyam:** Irodak csoportokba szervezve, csoport szinten kulon arfolyam
- **Arfolyam elterites:** Specialis arfolyam beallitas egyes irodakhoz/ugyfelekhz
- **Kedvezmeny lista:** Kedvezmenyes arfolyam jogosultak nyilvantartasa
- **Atlag arfolyam szamitas:** Tenylegesen alkalmazott atlag arfolyam kimutatasa

### 4.3 Ugyfel azonositas es compliance
- **300.000 Ft feletti tranzakciok:** BIGCTRL modul — kotelezoz ugyfel azonositas (Pmt. torveny)
- **Evi maximum:** `evimax.dll` — eves osszeg-korlatokat figyeli
- **Letiltas:** `letilt.dll` + `tiltasok.dll` — ugyfel/tranzakcio tiltas lehetosege
- **Terror naplo:** `terrnaplo.dll` — ENSZ szankcios listara valo egyezes naplozasa
- **Okmany kezeles:** `okmdisp.dll`, SENDOKMANY, UJSCANNER — szemelyi igazolvany/utlevel szkenneles es tarolasa

### 4.4 Terror lista egyeztetes
- ENSZ Biztonsagi Tanacs konszolidalt szankcios lista automatikus letoltese
- XML parseolas → nevek kinyerese (FIRST_NAME, SECOND_NAME, THIRD_NAME)
- UNOLIST Firebird tabla teljes csereje (DELETE FROM → INSERT INTO)
- Tavoli szerveren is tárolt (`185.43.207.99`)

### 4.5 Western Union / WAFA
- WU tranzakciok kulon tarolasa: WUNITRANZ, WAFATRANZ tablak
- Havi WU tablo: irodankenti WU forgalom Excel export
- WU + WAFA nyitokeszlet / zarokeszlet kezeles (Unit37 — WUNIWAFACONTROL)
- Expressz penzsz allitasok nyilvantartasa

### 4.6 Konyveles (Booking)
- Teljes konyvelesi modul: napikonyv, havi kimutatások
- DayBook tabla: `DAYB{farok}` — dinamikusan generalt tabla nevek
- Bizonylat kezeles: bizonylatsz am generalas, kerekites
- Excel export: adatvet, forgalom, keszlet tablak

### 4.7 Napzar / Havizar folyamat
- **Napi zaras:** napzar.dll → cimlet osszegyujtes → napikonyv → napijel (napi jelentes)
- **Havi zaras:** havizar.dll → CREATE TABLE + feltoltes → havi osszesites
- **Esti zaras:** estizar.dll — automatikus nap vegi zaras
- **Zaras kontrol:** zarasctrl.dll — hianyzo zarasok figyelese

---


---

## S6 5_KULSO_INTEGRACIOK

| Integracio | Modul | Protokoll | Megjegyzes |
|------------|-------|-----------|------------|
| **MNB (Magyar Nemzeti Bank)** | mnbgyujto, mnbhibak, Unit6, Unit14, Unit17 | Firebird DB lekerdezess | Napi/havi MNB jelentes generalas |
| **Western Union** | western, westuni, wuniforg, westforg DLL, wunion (etdll) | Firebird + Excel | WU tranzakcio feldolgozas, penzsz allitas |
| **MoneyGram** | monegram | - | Penzkuldesi rendszer |
| **ENSZ Terror lista** | terror (maketerrlist) | HTTP (TWebBrowser) → XML | un.org szankcios lista automatikus letoltes |
| **NAV (adohatosag)** | NAVZARO (VALUTA) | - | Zarasi jelentes az adohatosag fele |
| **Rendorseg** | police (4 almodul) | - | Rendorsegi adatlekerdezesek |
| **OTP Bank** | OTP, OTPLOG (VALUTA) | - | Bank integracio + log |
| **Excel (COM)** | booking, western, beszam, foglalo, expadvet, makeszlt | OLE Automation (ComObj) | Automatikus Excel export minden kimutatáshoz |
| **FTP** | foglalo, korlevel, frissdat | WinInet API | Adat szinkronizalas FTP-n keresztul |
| **POS Terminal** | postterm | - | Kartyaterm inal kezelese |
| **QR kod** | QRGENER, QRDEPUTY | - | Napzar QR kod generalas |

---


---

## S7 6_ADATBAZIS_SEMA_FIREBIRD_TABLAK

A forrasbol azonositott Firebird tablak:

### 6.1 Fo adatbazisok
- `c:\receptor\database\receptor.fdb` — kozponti receptor adatbazis
- `C:\RECEPTOR\DATABASE\V{irodaszam}.FDB` — irodankenti adatbazis (pl. V101.FDB, V102.FDB)
- Tavoli szerver: `185.43.207.99` (terror lista)

### 6.2 Azonositott tablak

| Tabla nev | Tartalom | Modul(ok) |
|-----------|----------|-----------|
| **MNB** | MNB jelentes tablazat: VALUTANEM, IRODASZAM, VETELDARAB, ELADASDARAB, ZARO, SZAMITOTTZARO, MEGJEGYZES | server Unit6, Unit14, Unit17, mnbgyujto |
| **ARFOLYAM** | Arfolyamok: VALUTANEM, ARFOLYAM, UJARFOLYAM, ELSZAMARFOLYAM | arftmk, Unit16 |
| **ATLAGARFOLYAM** | Atlag arfolyamok | atlagarf |
| **BLOKKFEJ** | Bizonylat fejlec | atadvet |
| **BLOKKTETEL** | Bizonylat tetelek | atadvet |
| **CIMLETEK** | Cimlet kezeles | cimlet |
| **CIMLETPISZKOZAT** | Cimlet piszkozat | atadvet, keszedit |
| **DAYB{honap}** | Napi konyveles (dinamikus tabla) | dbookctrl, Unit16 |
| **ELOHAVI** | Elozo havi adatok | irtmk, Unit16 |
| **ELONAPI** | Elozo napi adatok | irtmk, Unit16 |
| **FOGLALO** | Foglalasi osszegek (150 penztar x 5 foglalo) | unpacker, evnyito, foglalo |
| **IDOSZAK** | Idoszak definiciok | hovalasz, idoszak |
| **IKTATO** | Korlevel iktatoszamok | korlev |
| **JOGISZEMELY** | Jogi szemely ugyfelek | jogiszemely, Unit16 |
| **JUTALEK** | Jutalek szamitas eredmenye | jutszamito |
| **MAINCURR** | Fo devizak | irtmk, Unit16 |
| **NAPIKEZD** | Napi kezdes adatok | napikezd |
| **NAPIKONYV** | Napi konyveles | napkonyv |
| **NAPIZAR** | Napi zaras | napijel |
| **NAPLO** | Napi naplo | napkonyv |
| **PENZTAROSOK** | Penztarosok (dolgozok) | dolgozok |
| **PENZTAROSFORGALOM** | Penztaros forgalom (jutalekhoz) | jutszamito |
| **PENZTARFORGALOM** | Penztar forgalom | listak |
| **SUMALLOMANY** | Osszesitett allomany | import |
| **SUMBANKFORGALOM** | Osszesitett bank forgalom | import |
| **SUMUGYFELFORGALOM** | Osszesitett ugyfel forgalom | import |
| **ADATATADO** | Adat atadas | beerkezes, getuzlet |
| **UGYFELEK** | Ugyfel toerzsadat | Unit16 |
| **UNOLIST** | ENSZ terror lista nevek: TERROR_NAME | terror |
| **USERS** | Felhasznalok (belepes) | userbelep |
| **VTEMP** | Temporary tabla (munkatabla) | unpacker, atadvet, bizodisp, listak, stb |
| **WAFATRANZ** | WAFA tranzakciok | wuafatranz |
| **WUNITRANZ** | Western Union tranzakciok | wuafatranz |
| Havi tranzakcio tablak | Dinamikus nevek | tranzakc |
| Havi elszamolas tablak | Dinamikus nevek | tranzakc |
| HRK tabla | Hitelkartya | hrkserver |

### 6.3 Tabla sema mintak (Unit16 alapjan)

**Arfolyam tabla semat (tipikus):**
```sql
CREATE TABLE {tabla} (
  VALUTANEM CHAR(3) CHARACTER SET WIN1250 COLLATE WIN1250,
  ARFOLYAM DOUBLE PRECISION,
  UJARFOLYAM DOUBLE PRECISION,
  ELSZAMARFOLYAM DOUBLE PRECISION,
  ...
)
CREATE INDEX IDX_{tabla} ON {tabla} (VALUTANEM)
```

**Tranzakcio tabla (dbookctrl):**
- DayBook tablak: fejlec + tetel + terminál + engedely tablak
- Dinamikus tabla nevek: `DAYB{honap}`, `{engnev}`, `{ptermnev}`

**Karakter kodolas:** WIN1250 — magyar lokalizacio

---


---

## S8 7_JAVASLATOK

### 7.1 Migracios prioritasok (Delphi → Java/React)

1. **KRITIKUS — Azonnal migralando:**
   - **Terror lista egyeztetes** → REST API-val az ENSZ XML forrast direktben olvasni (a TWebBrowser hack elavult)
   - **MNB jelentes** → Strukturalt API szolgaltatas, nem Firebird-kozott tabla torles-ujratoltés
   - **Arfolyam szamitas** → A fuggveny-alapu szamitas logikajat tesztekkel le kell fedni, mert ez a legkockázatosabb uzleti logika
   - **NAV zaras** → Szabalyozoi kotelezettség, nem halaszhato

2. **MAGAS — Kozvetlen uzleti ertek:**
   - **Western Union / MoneyGram integracio** → Modern API-k hasznalata
   - **Booking (konyveles)** → A bizonylatsz am + kerekites logika kritikus
   - **Ugyfel azonositas (300.000 Ft+)** → Compliance szabaly, meg kell orizni
   - **Foglalasi rendszer** → FTP-alapu szinkronizacio elavult

3. **KOZEPES — Modszertan javitas:**
   - **DLL architektura → Mikro-service vagy modul** → A 36 DLL kulon deploy-ja microservice-re vagy Spring modulokra fordithato
   - **Excel COM automation → Server-side export** → Apache POI vagy hasonlo
   - **Firebird → PostgreSQL** → Az adatbazis migralasi terv mar letezik

4. **ALACSONY — Technikai adag:**
   - Lokacio-specifikus modulok (Metro, Tesco) → Konfiguracio-alapu megoldas
   - FNYUJSAG (15+ lokacio-specifikus valtozat!) → Egyetlen parameterezheto modul

### 7.2 Kockazatok

| Kockazat | Szint | Megjegyzes |
|----------|-------|------------|
| Hardcoded IP-k/utvonalak | KRITIKUS | `185.43.207.99`, `c:\receptor\`, `c:\uctrl\`, `c:\locserver\` — mindenhol hardcoded |
| SQL injection | MAGAS | String concatenacioval epitett SQL — `chr(39)` escape, de nem parametrizalt |
| Nincs tranzakcio-vedelem | MAGAS | Sok `DELETE FROM` → `INSERT` minta rollback vedelem nelkul |
| WIN1250 kodolas | KOZEPES | UTF-8 migracio szukseges |
| COM/OLE Excel fuggseg | KOZEPES | Szerver oldalon Excel nem skalaz |
| FTP szinkronizalas | KOZEPES | Titkositatlan protokoll |
| Bizonylatsz am logika | MAGAS | Kerekites + generalas egyedi logika — pontos port szukseges |
| Fuggveny-alapu arfolyam | MAGAS | Nem trivialis matematikai logika — teszteles nelkul nem szabad portolni |

### 7.3 Architekturalis meglatasok

1. **A rendszer rendkivul modularis** — a DLL-alapu architektura termeszetes modon kepezhető mikro-service-ekre
2. **Az adatbazis-minta konzisztens** — DELETE FROM → ujratoltese mindenhol, ami azt jelenti, hogy az adat mindig "friss szamolt" es nem inkrementalis
3. **Excel COM automation mindenhol** — ez a legnagyobb technikai adag a szerver oldalon
4. **A bizonylat-logika jogszabalyokbol fakad** — nem szabad egyszerusiteni, pontosan at kell vinni
5. **Tobb verzio letezik fontos modulokbol** (arfolyam v20-v22, booking save/nem-save) — a legujabb verziok az aktiv verzok

---


---

## S9 FUGGELEK_STATISZTIKAK

| Metrika | Ertek |
|---------|-------|
| Osszes .dpr fajl | ~280+ |
| SZERVER fejleszt modulok | ~96 |
| SZERVER ujdll-ek | 36 |
| ERTEKTAR etdll-ek | ~60 |
| VALUTA DLL-ek | ~90+ |
| Fo alkalmazasok | 4 (server.exe, ibvalto.exe, trade.exe, helga/locserver.exe) |
| Firebird tablak azonositva | 30+ |
| Kulso integraciok | 10 (MNB, WU, MoneyGram, ENSZ, NAV, rendorseg, OTP, Excel, FTP, POS) |
| Kodolas | WIN1250 → UTF-8 migracio szukseges |
| Arfolyam verziok | 4 (v20, v21, v22, old) |
| Booking valtozatok | 2 (save + current) |
| FNYUJSAG lokacio valtozatok | 15+ |
