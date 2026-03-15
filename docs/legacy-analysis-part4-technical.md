# Legacy Drive technikai elemzes - Part 4: Delphi forrasko, adatbazis sema es konfiguracio

## 1. Fajl statisztikak osszesites

| Fajltipus | Darab | Megjegyzes |
|-----------|-------|------------|
| `.pas` (Delphi Pascal) | 1 102 | Teljes uzleti logika forraskodja |
| `.dpr` (Delphi Project) | 661 | DLL projekt fajlok |
| `.dfm` (Delphi Form) | 1 099 | UI layout definiciok |
| `.dcu` (Compiled) | ~600+ | Leforditott egysegek |
| `.cfg` (Config) | ~150+ | Delphi forditasi konfiguraciok |
| `.sql` | 163 | Adatbazis migraciok (Zalog EXZ01 rendszer) |
| `.fdb` (Firebird DB) | 9 | Elo adatbazis fajlok |
| `.gdb` (InterBase DB) | 3 | Regebbi InterBase adatbazisok |
| `.html` (Figdoc) | ~900 | v2.0 tervezesi dokumentumok |
| `.csv` | ~6 | Banki import/jelentes mintak |
| `.txt` | ~45 | Konfiguraciok, jelentesek, protokollok |
| `.bin` (atnevezett) | 4 | 2 db EU szankcios lista (UTF-8), 1 PNG, 1 Excel |
| `.xlsx` | 1 | Delphi licenc arak |

## 2. Delphi forrasko architektura (Regi-Valuta-program)

### 2.1 Rendszer felepites

A legacy rendszer harom fo reszbol all:

```
Regi-Valuta-program/
  ERTEKTAR/          # Penztari kliens (penztar gepen fut)
    database/        # Lokalis Firebird adatbazisok
    etdll/           # ~55 DLL modul (uzleti logika)
  SZERVER/           # Szerver oldali alkalmazasok
    fejleszt/        # ~80+ szerver modul
    ujdll/           # ~35 ujabb szerver DLL
    newdll/          # Legujabb szerver DLL-ek
  VALUTA/            # Valutalvas-specifikus modulok
    DLL/             # Altalanos DLL-ek
    IBVALTO/         # InterBase valto modul
    TRADE/           # E-kereskedelem (AAK matrica, mobil feltoltes, PaySafeCard)
```

### 2.2 Penztari kliens DLL modulok (ERTEKTAR/etdll/)

| DLL neve | Funkció | Uzleti jelentes |
|----------|---------|-----------------|
| `arftmk` | Arfolyam karbantarto | Arfolyamok beolvasasa FTP szerverrol, megjelenitese |
| `atadolap` | Atadolap | Penztarok kozti keszlet atadas dokumentuma |
| `atadvet` | Atadas-avetel | Penztarkozt keszlet transzfer |
| `bizodisp` | Bizonylat megjelenito | Tranzakcio bizonylatok megjelenitese |
| `bloknyom` | Blokk nyomtatas | Penztargep blokk nyomtatas |
| `checklst` | Ellenorzo lista | Napzaras elotti validacio |
| `cimlctrl` | Cimlet kontroll | Cimletezes ellenorzes |
| `cimlet` | Cimletezes | Bankjegy cimletszamlalas (14 cimlet/valutanem) |
| `cimlmenu` | Cimlet menu | Cimletezes tipusvalaszto |
| `cimlnyom` | Cimlet nyomtatas | Cimletezes bizonylat nyomtatasa |
| `cimsetup` | Cimlet beallitas | Cimlet konfiguracio |
| `estizar` | Esti zaras | Nap vegi zaras elokeszites |
| `getarf` | Arfolyam lekerdezes | Aktualis arfolyamok lekerese |
| `getellen` | Ellenor lekerdezes | Ellenorzo szemely azonositasa |
| `getplomb` | Plomba lekerdezes | Plombaszam kezeles |
| `getptar` | Penztar lekerdezes | Penztar adatok lekerese |
| `havizar` | Havi zaras | Havi osszesito zaras es jelentes |
| `hrkatvevo` | HRK atvevo | Horvat kuna specialis kezeles |
| `hrkcimlet` | HRK cimletezes | Horvat kuna cimletezes |
| `idoszak` | Idoszak | Idoszakos lekerdezesek |
| `irarfoly` | Iroda arfolyam | Irodankenti arfolyam beallitas |
| `kcimlet` | Keszlet cimlet | Keszlet-cimlet osszevetes |
| `keszedit` | Keszlet szerkesztes | Keszlet modositas |
| `keszup` | Keszlet frissites | Keszlet update |
| `kezdij` | Kezelesi dij | Tranzakcios kezelesi dij szamitas |
| `korlev` | Korlevel | Hatosagi korlevel kezeles |
| `listak` | Listak | Kulonbozo listak megjelenitese |
| `logdisp` | Log megjelenito | Muveleti naplo megjelenitese |
| `logiro` | Log iro | Muveleti naplo rogzitese |
| `maktablak` | Makro tablazat | Makro-szintu tablazatok |
| `matptar` | Matrica penztar | AAK matrica ertekesites |
| `mentes` | Mentes | Adatmentes funkciok |
| `napijel` | Napi jelentes | Napi forgalmi jelentes generalasa |
| `napikezd` | Napi kezdes | Nap nyitasi folyamat |
| `napkonyv` | Napkonyv | Napi bizonylatkonyv |
| `napzar` | Napzaras | **KRITIKUS**: Teljes nap vegi zaras folyamat |
| `nifval` | NIF validalas | Valamilyen validacios modul |
| `nznyomt` | Napzar nyomtatas | Napzarasi jelentes nyomtatasa |
| `penztarak` | Penztarak | Tobb penztaros kezeles |
| `pillall` | Pillanatkep osszes | Osszes penztar pillanatkep |
| `pillkesz` | Pillanatkep keszlet | Keszlet pillanatkep |
| `prosbe` | Penztaros beleptetes | Penztaros bejelentkezes |
| `prostmk` | Penztaros karbantartas | Penztaros adatok karbantartasa |
| `ptarkesz` | Penztar keszlet | Penztar keszlet nyilvantartas |
| `ptartmk` | Penztar karbantartas | Penztar alap adatok karbantartasa |
| `quitform` | Kilepes | Kilepes megerosites |
| `ratectrl` | Rate kontroll | Arfolyam ellenorzes |
| `rateperm` | Rate permission | Arfolyam jogosultsag kezeles |
| `regen` | Regeneralas | Keszlet ujraszamolas a tranzakciokbol |
| `regizaro` | Regi zaras | Korabbi napok zaras potlasa |
| `storno` | Sztorno | **KRITIKUS**: Tranzakcio sztornirozasa |
| `super` | Supervisor | Supervisor jelszo ellenorzes |
| `supertsk` | Supervisor feladat | Supervisor specialis muveletek |
| `terminal` | Terminal | Terminal kezeles |
| `wunion` | Western Union | Western Union integraciok |

### 2.3 Szerver modulok (SZERVER/fejleszt/ - valogatott)

| Modul | Funkció |
|-------|---------|
| `arfolyam` | Arfolyam szerver - kozponti arfolyam kezeles |
| `archival` | Archivalas - regi adatok archiválása |
| `banklist` | Bank lista - banki osszekapcsolas |
| `beszam` | Beszamolo - hatosagi beszamolok generálása |
| `booking` | Foglalás - deviza elofoglalas |
| `confident` | Bizalmas - biztonsagi modul |
| `everseny` | E-verseny - versenyarfolyam figyelés |
| `forgdisp` | Forgalom megjelenito - forgalmi adatok |
| `gbakall` | GBak all - teljes adatbazis backup |
| `haszon` | Haszon - profitszamitas |
| `havitablo` | Havi tabla - havi osszesitok |
| `import` | Import - adatimport |
| `jelenlet` | Jelenlet - dolgozoi jelenleti iv |
| `jogi` | Jogi - jogi szemelyek kezelese |
| `kereso` | Kereso - tranzakcio kereso |
| `korlevel` | Korlevel - hatosagi korlevel |
| `monegram` | MoneyGram - MoneyGram integraciok |
| `napiment` | Napi mentes - napi backup |
| `newrate` | Uj arfolyam - arfolyam frissites |
| `permit` | Engedelyek - engedely kezeles |
| `police` | Rendorsegi jelentes - rendorsegi adatszolgaltatas |
| `postterm` | POS terminal - kartyaterminal integraciok |
| `terror` | Terrorlista - AML szankcios lista ellenorzes |
| `tranzacs` | Tranzakciok - tranzakcio kezeles |
| `tranzdb` | Tranzakcio DB - tranzakcio adatbazis |
| `tranzdij` | Tranzakcios dij - dijszamitas |
| `ufill18/19` | Ugyfel kitoltes - hatosagi adatlap kitoltes |
| `ugyfseek` | Ugyfel kereses - ugyfel nevalapú keresese |
| `western/westuni` | Western Union - WU integraciok |

## 3. Delphi uzleti logika reszletes elemzes

### 3.1 Sztorno folyamat (storno/makedll/unit2.pas)

**Adatbazis tablak:**
- `BLOKKFEJ` - Bizonylat fejlec (bizonylatszam, tipus, datum, ido, forintertek, tetel, storno)
- `BLOKKTETEL` - Bizonylat tetel (bizonylatszam, valutanem, arfolyam, bankjegy, forintertek, elojel)
- `VTEMP` - Ideiglenes tabla (munka tabla)
- `UTOLSOBLOKKOK` - Utolso bizonylat szamok nyilvantartasa
- `PENZTAR` - Penztar alap adatok (penztarkod)
- `HARDWARE` - Penztargep allapot (megnyitottnap, napistorno)

**Tranzakciotipusok:**
- `U` = Devizavetel (Ugyfel ad devizat, kapja a HUF-ot)
- `F` = Deviza eladas (Ugyfel kap devizat, fizet HUF-ot)
- `UF` = Deviza-deviza atvaltas vetel iranyba
- `FF` = Deviza-deviza atvaltas eladas iranyba

**Sztorno logika:**
1. Eredeti bizonylat `STORNO` mezojet 1-rol 2-re allitja (BLOKKFEJ es BLOKKTETEL)
2. Uj sztorno bizonylat keszul `STORNO=3` mezoertekkel
3. Osszes osszeg negativ elojellel kerul be: `bankjegy*(-1)`, `forintertek*(-1)`
4. Uj bizonylat szamot general az `UTOLSOBLOKKOK` tablabol
5. Blokk nyomtatas tortenik (1 vagy 2 peldany)
6. Napi sztorno szamlalo novekszik (`HARDWARE.NAPISTORNO`)
7. Regeneralas (keszlet ujraszamolas)

**Bizonylat szam formatum:**
- `U` + penztarkod(3 jegy) + sorszam(6 jegy) - pl. `U001000123`
- `UF` + penztarkod(3 jegy) + sorszam(5 jegy) - pl. `UF00112345`
- `F` + penztarkod(3 jegy) + sorszam(6 jegy)
- `FF` + penztarkod(3 jegy) + sorszam(5 jegy)

**Supervisor jogosultsag:**
- Ha napistorno > 2, supervisor jelszo szukseges (super.dll)
- Sztorno indokolasi kotelezettseg (STORNOINDOK mezo)

### 3.2 Napzaras folyamat (napzar/makedll/unit2.pas)

**Tamogatott valutak (27 db, fixhuzalozva):**
```
AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF, ILS,
JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD
```
(HUF index = 13)

**Napzaras elofeltetel ellenorzesek (NapzarControl):**
1. Esti penztar cimletezes egyezes (errorcode=1)
2. Kezelesi dij cimletezes egyezes (errorcode=2)
3. Western Union cimletezes egyezes (errorcode=3)
4. AFA penztar cimletezes egyezes (errorcode=4)
5. E-kereskedelem cimletezes egyezes (errorcode=5)

**Napzaras lepesek:**
1. `regeneralorutin` - keszlet ujraszamolas
2. Cimletezesek ellenorzese (5 kulonbozo penztar-tipusra)
3. Ellenor (szupervisor) bejelentkezes (`getellenorrutin`)
4. Teljes napi adat ellenorzes (`checkcontrol`)
5. HRK (horvat kuna) cimletezes, ha volt HRK forgalom
6. **Havi gyujtokbe masolas** - az alabbi adatok mozgatasa:
   - `BF[HHNN]` = Blokkfejek havi gyujtoje
   - `BT[HHNN]` = Blokktetelek havi gyujtoje
   - `CIMT[HHNN]` = Cimletezes havi gyujtoje
   - `NARF[HHNN]` = Napi arfolyamok gyujtoje
   - `WUNI[HHNN]` = Western Union es AFA gyujtoje
   - `WZAR[HHNN]` = WU zaras gyujtoje
   - `EDAT[HHNN]` = E-kereskedelem zaras gyujtoje
   - `EKER[HHNN]` = E-kereskedelem forgalom gyujtoje
   - `KDAT[HHNN]` = Kezelesi dij zaras gyujtoje
   - `KEZD[HHNN]` = Kezelesi dij forgalom gyujtoje
7. Napzar jelentes nyomtatasa
8. `HARDWARE.LEZARTNAP` frissitese

**KRITIKUS**: Masolas utan TORLES a forras tablakbol (`DELETE FROM BLOKKFEJ`, stb.)

### 3.3 Cimletezes logika (cimlet/makedll/unit2.pas)

**HUF cimletek (14 fele, fixhuzalozva):**
```
20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1
```

**Cimletezesi tipusok (9 fele):**
1. Valuta penztar cimletezes
2. Kezelesi koltseg cimletezes
3. Western Union penztar cimletezes
4. AFA penztar cimletezes
5. Ugyfel foglalo cimletezes
6. E-kereskedelem cimletezes
7. Atadas-atvetel cimletezes
8. AXA biztositas cimletezes
9. MoneyGram keszlet cimletezes

**Adatbazis tablak:**
- `CIMINI` - Cimletezes alap tabla (valutanem, cimlettype, aktkeszlet, cimletezett, ready, cimlet1-14)
- `CIMLETEK` - Vegso cimletezesi eredmeny

**Konfiguracio:**
- `c:\ertektar\cimlet.cfg` - Melyik valutanemhez milyen cimletek leteznek
- Formatum: `[DnemKod][DarabKod][CimletPozKodok]` - pl. `EURCBCD` = EUR-hoz 3 cimlet: B, C, D pozicio

**Validacio:**
- Cimletek osszege == keszletben nyilvantartott osszeg kell legyen
- Ha nem egyezik, nem enged tovabb (piros/feher jelzes)
- Ha mindegyik valuta egyezik, zold jelzes es tovabb engedi

### 3.4 Arfolyam karbantartas (arftmk/makedll/unit2.pas)

**Adatbazis tablak:**
- `ARFOLYAM` - Arfolyam tabla (valutanem, elszamolasiarfolyam, veteliarfolyam, eladasiarfolyam, nyito, zaro)

**Funkciok:**
- FTP szerver csatlakozas arfolyam letoltesre (`FTPSzerverbeBelep`)
- CurRate webes arfolyam lekerdezese (`GetCurrate`)
- Iroda-specifikus arfolyam beallitas (`IrodaAdatBeolvasas`)
- Arfolyam validalas
- Dupla supervisor kod ellenorzes

**Arfolyam tipusok:**
- Elszamolasi arfolyam (MNB kozeparfolyam)
- Veteli arfolyam (mennyit fizet az ugyfelnek)
- Eladasi arfolyam (mennyit ker az ugyfeltol)

## 4. Adatbazis rendszer

### 4.1 Firebird/InterBase adatbazisok

| Fajl | Tartalon | Megjegyzes |
|------|----------|------------|
| `valuta.fdb` | Fo valuta adatbazis | Penztari tranzakciok, arfolyamok |
| `valdata.fdb` | Valuta archiv adatok | Havi gyujtok (BF, BT, CIMT, NARF, stb.) |
| `engedely.fdb` | Engedelyek | Hatosagi engedelyek |
| `korlevel.fdb` | Korlevelek | Hatosagi korlevek |
| `hazihrk.fdb` | HRK hazi | Horvat kuna specialis kezelese |
| `expedvet.fdb` | Export adatvetel | Export adatok |
| `arfolyam.fdb` | Arfolyam | Arfolyam archivum |
| `booking.fdb` | Foglalás | Deviza elofoglalasok |
| `lemento.fdb` | Mentes | Mentesi naplo |
| `bizlatok.fdb` | Bizlatok | Ugyfel adatbazis |
| `darius.fdb` | Darius | Versenytars arfolyamok |
| `trade.gdb` | Trade | E-kereskedelem (matrica, feltoltes) |
| `police.gdb` | Rendorseg | Rendorsegi adatszolgaltatas |
| `perseek.gdb` | Szemelyek | Szemelyes adatok keresese |

### 4.2 Fo adatbazis sema (rekonstrualt a kodbol)

```sql
-- Penztari alap tablak
PENZTAR (PENZTARKOD, ...)
HARDWARE (MEGNYITOTTNAP, LEZARTNAP, NAPISTORNO, MENETSZAM, ...)
ARFOLYAM (VALUTANEM, ELSZAMOLASIARFOLYAM, VETELIARFOLYAM, ELADASIARFOLYAM, NYITO, ZARO)

-- Tranzakcio tablak
BLOKKFEJ (BIZONYLATSZAM, TIPUS, DATUM, IDO, FORINTERTEK, TETEL,
          TRBPENZTAR, TARSPENZTARKOD, PENZTAROSNEV, IDKOD,
          PLOMBASZAM, SZALLITONEV, STORNO, STORNOBIZONYLAT)

BLOKKTETEL (BIZONYLATSZAM, VALUTANEM, ARFOLYAM, BANKJEGY,
            FORINTERTEK, ELSZAMOLASIARFOLYAM, ELOJEL, TORTRESZ, STORNO, DATUM)

-- Bizonylat szamlalok
UTOLSOBLOKKOK (LASTATVET, LASTATADAS, LASTFTATVETEL, LASTFTATADAS)

-- Ideiglenes tabla
VTEMP (VALUTANEM, ARFOLYAM, BANKJEGY, FORINTERTEK,
       BIZONYLATSZAM, STORNOBIZONYLAT, STORNO, TIPUS, DATUM, IDO, STORNOINDOK,
       ELLENORNEV, ELLENORBEO)

-- Cimletezes tablak
CIMINI (VALUTANEM, CIMLETTYPE, AKTKESZLET, CIMLETEZETT, READY,
        CIMLET1..CIMLET14)
CIMLETEK (DATUM, VALUTANEM, BANKJEGY, CIMLET1..CIMLET14)

-- Kezelesi dij
KEZDIJ (BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
KEZDIJDATA (NYITO, BEVETEL, KIADAS, ZARO)

-- E-kereskedelem
EKERESKEDELEM (BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
EKERDATA (NYITO, BEVETEL, KIADAS, ZARO)

-- Western Union / AFA
WUAFAFORG (BIZONYLAT, VALUTANEM, ELOJEL, BANKJEGY, PENZTAR, BIZTIPUS, STORNO)
WZARO (USDNYITO, USDBEVETEL, USDKIADAS, USDZARO,
       HUFNYITO, HUFBEVETEL, HUFKIADAS, HUFZARO,
       AFANYITO, AFABEVETEL, AFAKIADAS, AFAZARO)

-- HRK naplo
HRKNAPLO (DATUM, ZARO, ...)

-- Havi gyujto tablak (dinamikus nevek: BF[HHNN], BT[HHNN], stb.)
BF[HHNN] (azonos struktura mint BLOKKFEJ + DATUM)
BT[HHNN] (azonos struktura mint BLOKKTETEL + DATUM)
CIMT[HHNN] (DATUM, BANKJEGY, VALUTANEM, PROSSZAM, CIMLET1..CIMLET14)
NARF[HHNN] (DATUM, VALUTANEM, ELSZAMOLASIARFOLYAM, NYITO, ZARO)
WUNI[HHNN] (DATUM, VALUTANEM, BIZONYLAT, BANKJEGY, ELOJEL, PENZTAR, BIZTIPUS, STORNO)
WZAR[HHNN] (DATUM, USD/HUF/AFA NYITO/BEVETEL/KIADAS/ZARO)
EDAT[HHNN] (DATUM, NYITO, BEVETEL, KIADAS, ZARO)
EKER[HHNN] (DATUM, BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
KDAT[HHNN] (DATUM, NYITO, BEVETEL, KIADAS, ZARO)
KEZD[HHNN] (DATUM, BIZONYLAT, ELOJEL, BANKJEGY, PENZTAR, STORNO)
```

### 4.3 Zalog rendszer SQL sema (EXZ01 - kulonallo rendszer)

Az EXZ01 (Zalog) rendszernek onallo SQL migracios rendszere van (1204-1335 szamu scriptek):

**Fo tablacsoportok:**
- `pawn_loan` - Zalogkolcson nyilvantartas
- `pawn_loan_event` - Zalogkolcson esemenyek (befizetes, kikeredes, stb.)
- `client` - Ugyfelek
- `worker` - Dolgozok
- `site` - Fiok telephelyek
- `bulletin` - Hirdetmenyek
- `closing` - Zarasok
- `day` / `day_frame` - Naptari napok es idokeretek
- `fee_rate` - Dijszabas
- `settlement` - Telepulesek

**View-k:**
- `pawn_loan_search_v` - Zalogkolcson kereso nezet
- `worker_data_v` - Dolgozo adatok nezet
- `client_document_data_v` - Ugyfel dokumentum adatok
- `closing_data_v` - Zaras adatok
- `event_group_and_event_list_v` - Esemeny csoport es lista
- `pawn_loan_notifications_v` - Zalog ertesitesek

## 5. Konfiguracios es adatfajlok

### 5.1 cimlet.cfg
Valutanemenkent definiálja, hogy milyen cimletek leteznek. Fordum: `[DNEM(3)][DARAB_KOD(1)][CIMLET_POZ_KODOK]` ahol a pozicio kodok A-N (A=20000, B=10000 ... N=1).

### 5.2 EU szankcios lista (Terrorlista2008.txt, .bin fajlok)
- 5366 soros AML szankcios lista
- EU penzmosas-elleni korlatozo intezkedesek alattiak listaja
- Szemelyek es szervezetek nevlistaja
- Tobbnyelvu (magyar, angol, gorog, roman, bolgar karakterekkel)
- A `.bin` fajlok ugyanennek a listanak mas peldanyai

### 5.3 Banki import CSV formatum
Felpontosvesszos CSV, oszlopok:
```
ugyfel_tipus; uzlethelyiseg_azonosito; tranzakcio_datuma; osszeg; valutanem;
eladas_vetel; alkalmazott_arfolyam; tranzakcio_forint_osszege;
tranzakcio_egyedi_azonositoja; csaladi_es_utonev; szuletesi_nev;
szuletesi_datum; szuletesi_hely; anyja_neve; allampolgarsag;
azonosito_okmany_tipusa; azonosito_okmany_szama;
allando_lakcim_telepules; allando_teljes_lakcim;
[ceges mezo-csoportok...]
```

### 5.4 Rendorsegi jelentes formatum (police.txt)
```
[penztar_id]=[datum]/[bizonylat_szam]->[osszeg] [valutanem]
```
Pl: `8=2014.12.22/V000450->9100 NOK` = 8-as penztarnal, V000450 bizonylatszam, 9100 NOK

### 5.5 E-kereskedelem termekek (TRADE/ct.txt)
CSV: `[id],[termek_nev],[szolgaltato],[ar_HUF],[aktiv]`
- Mobil feltoltesek: T-Mobile, Vodafone, Telenor, Tesco-Mobile
- AAK matricak: autapalya D1/D2/B2 heti/havi/eves
- T-COM karttak: kontrol-kartya, barangolo-kartya
- Megyei e-matricak
- NeoPhone feltoltesek

### 5.6 TRADE XML protokollok
- `prequest.txt` - PaySafeCard XML kerese (terminalId, username, password, productId)
- `live.txt` - AAK matrica eles XML (TransactionId)
- `cancel.txt` - Sztorno XML
- `liverply.txt` / `testrply.txt` - Szerver valasz formatum

### 5.7 Havi penztarzaras jelentes (havizar.txt)
Szoveges jelentes formatum:
```
[Ceganev]
[Penztar cim]
[Ev] ev [Honap] havi penztarzaras
VALUTA    NOVEKEDES    CSOKKENES
[dnem]  Nyito: [osszeg]
  Elad-vetel: [novekedes] [csokkenes]
  Atvet-atad: [novekedes] [csokkenes]
  Tobbl-hiany: [osszeg]
  Zaro: [osszeg]
```

### 5.8 Napi tranzakcio naplo (mentes.txt)
```
Datum    Ido   Blokkszam   Valuta osszege   Ft. osszege  Kedv.arf  Elsz.arf
V119277        123.456.000 SEK              123.197.400 Ft  12345.78  12345.78
```

### 5.9 Hirlevel/arfolyam kijelzo (litenews/v4.txt)
Egyetlen sor, az iroda kirakataba ki&iacute;rt arfolyam szoveg:
```
ZALOG - EKSZER - MUTARGY - CHANGE : CHF: 288,70/292,59  EUR: 314,70/317,59 ...
```

## 6. v2.0 Figdoc HTML fajlok

A `Kosa csoport/Valuta/v2.0/HTML/` konyvtarban ~900 `.figdoc.html` fajl talalhato. Ezek a v2.0 tervezesi dokumentaciok, valoszinuleg egy Figma-export:

**Legfontosabbak a valutavalto szempontjabol:**
- `meghatalmazottak.figdoc.html` - Meghatalmazottak kezelese
- `partner.figdoc.html` - Partner (ugyfel) kezelese
- `company.figdoc.html` - Ceg kezeles
- `document.figdoc.html` - Dokumentum kezeles
- `calendar.figdoc.html` - Naptar kezeles
- `dictionary.figdoc.html` - Szotar/kodtablak
- `demand.figdoc.html` - Igenyles kezeles
- `inst_loc.figdoc.html` - Telephelykezeles

## 7. Kritikus uzleti szabalyok (kodbol kinyerve)

### 7.1 Tranzakcio tipusok es bizonylat prefixek
| Prefix | Tipus | Leiras |
|--------|-------|--------|
| `V` | Vetel | Penztaros vesz devizat ugyfeltol |
| `E` | Eladas | Penztaros ad devizat ugyfelnek |
| `VF`/`UF` | Deviza-deviza vetel | Deviza-deviza atvaltas |
| `EF`/`FF` | Deviza-deviza eladas | Deviza-deviza atvaltas |

### 7.2 Storno allapotok
| STORNO ertek | Jelentes |
|--------------|----------|
| 1 | Normal (sztornirhato) bizonylat |
| 2 | Sztornozott (eredeti bizonylat - inaktiv) |
| 3 | Sztorno bizonylat (az uj, negativ bizonylat) |

### 7.3 Napzaras szigoru sorrendje
1. Minden cimletezesnek egyeznie kell (5 fele penztar)
2. Supervisor jelszo kotelezo
3. Teljes napi adat ellenorzes
4. Adatok havi gyujtokbe masolasa
5. Forras tablak torlese (DELETE)
6. Jelentes nyomtatasa
7. HARDWARE.LEZARTNAP frissitese

### 7.4 DLL architektura
- Minden modul onallo DLL (`stdcall` konvencio)
- Altalaban egyetlen exported function: pl. `stornorutin`, `napzarrutin`, `cimletezorutin`
- A DLL-ek elosztott adatbazis kapcsolatokat hasznalnak (kulon IBDatabase/IBTransaction komponensek)
- Eleresi utak fixhuzalozva: `c:\ertektar\bin\*.dll`

### 7.5 Multi-penztar architektura
- Penztarkod 3 jegyu numerikus azonosito
- Tarspenztarkod - penztarok kozti atadas celpenztar
- Minden bizonylat tartalmazza a penztarkodot a bizonylat szamban

## 8. Relevancia az uj rendszerhez

### Kozvetlen megfeleltetes (legacy -> uj rendszer):
| Legacy | Uj rendszer (Java/Spring) |
|--------|--------------------------|
| `BLOKKFEJ` + `BLOKKTETEL` | `Transaction` + `TransactionItem` entity |
| `ARFOLYAM` | `ExchangeRate` entity |
| `CIMINI` / `CIMLETEK` | `Denomination` entity |
| `HARDWARE.MEGNYITOTTNAP/LEZARTNAP` | `DailyClosing` entity |
| `UTOLSOBLOKKOK` | `ReceiptSequence` entity |
| `storno.dll` | `StornoService` |
| `napzar.dll` | `DailyClosingService` |
| `cimlet.dll` | `DenominationService` |
| `arftmk.dll` | `ExchangeRateService` |
| `terror.dll` | `AmlService` |
| `police.dll` | `PoliceReportService` |
| Firebird `.fdb` | PostgreSQL |
| Lokalis DLL-ek | REST API + Electron offline sync |

### Fontos kulonbsegek:
1. **Havi gyujtok**: A legacy rendszer havonta kulon tablakat hozott letre (BF0901, BF0902, stb.). Az uj rendszer ezt egyetlen tablaval kezeli datum szuressel.
2. **Fixhuzalozott valutak**: A legacy 27 valuta fixhuzalozva. Az uj rendszer dinamikus valuta konfiguracioval dolgozik.
3. **Cimletek**: A legacy 14 cimlet HUF-ra fixhuzalozva. Az uj rendszer valutanemenkent konfiguralhato cimletekkel mukodik.
4. **Adatbazis**: Firebird -> PostgreSQL migracio. A `.fdb` fajlok tartalmazzak a legacy adatokat, ha szukseges a migracio.
5. **FTP arfolyam**: A legacy FTP-n kapta az arfolyamokat. Az uj rendszer API-n keresztul kommunikal.
