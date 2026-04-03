# AntivalutaTeljes

## Cél
Ez a dokumentum egyetlen helyre összefűzi és egységesíti a teljes `Anti` legacy rendszerre elkészített anyagokat:

1. teljes rendszerfeltérképezés
2. funkció- és menüponttérkép
3. adatbázis- és adattérkép
4. AI-nak szánt végrehajtási prompt

Ez a fájl úgy készült, hogy önmagában is használható legyen:

- fejlesztői handoff dokumentumként
- legacy reverse engineering alapként
- modernizációs specifikáció kiindulópontként
- AI ügynök végrehajtási promptjaként

---

# I. Teljes rendszerfeltérképezés

## 1. Top-level rendszerkép
Az `Anti` könyvtár nem egyetlen program, hanem több generációból álló, hibrid pénzügyi ökoszisztéma.

### Fő részek
- `Anti\VALUTA`
  - klasszikus Delphi/Pascal valutaváltó mag
  - fő belépési pontok: `IBVALTO`, `TRADE`, nagy számú DLL modul
- `Anti\camera2\camera`
  - újabb Java/Maven alapú kamera és központi platform
- `Anti\camera3\old`
  - régebbi Java ökoszisztéma
  - desktop client, management, WU inspecter, NAV és más szerverek
- `Anti\camera`
  - telepítési és futtatási artefaktok

### Technológiai rétegek
- Delphi 7 / Pascal desktop kliens és DLL plugin-rendszer
- InterBase / Firebird lokális és távoli adatbázisok
- JavaFX / Spring / MySQL alapú újabb kísérő rendszerek
- fájlalapú nyomtatás, export és mentés
- távoli Firebird elérés host:path formában
- HTTP, FTP és segéd-EXE integrációk

## 2. Fő desktop alkalmazások

### `IBVALTO`
Ez a fő valutaváltó kasszaprogram.

Belépési pont:
- `Anti\VALUTA\IBVALTO\IBVALTO.DPR`

Lényegi jellemzők:
- mutexszel védi az egyszeres futást
- splash/loader képernyőt használ
- betölti a fő formokat
- shell/orchestrator szerepet tölt be
- a konkrét üzleti műveleteket DLL-ekbe delegálja

Bizonyíték:

```pascal
program ibvalto;

uses
  Forms,
  Windows,
  Dialogs,
  Unit1 in 'UNIT1.PAS' {FORM1},
  Unit18 in 'Unit18.pas' {ZARASFORM},
  Unit47 in 'Unit47.pas' {FOMENUFORM},
  Unit3 in 'Unit3.pas' {UJKONVERZIO},
  Unit2 in 'Unit2.pas' {OPENKERDOFORM},
  Unit4 in 'Unit4.pas' {TOLTOFORM},
  Unit5 in 'Unit5.pas' {TRYAGAINFORM};
```

### `TRADE`
Másodlagos, különálló Delphi alkalmazás.

Belépési pont:
- `Anti\VALUTA\TRADE\fejleszt\trade.dpr`

Fő funkciói:
- telefonfeltöltés
- autópályamatrica
- logolvasás
- tanúsítványkezelés
- feladás és listák
- elektronikus kereskedés
- archíválás

## 3. DLL plugin architektúra
Az `IBVALTO` működésének gerince egy nagy külső DLL-készlet.

### Kiemelt runtime DLL-ek
- `getarf.dll` - árfolyam letöltés
- `arfreg.dll` - árfolyam regiszter
- `arftmk.dll` - árfolyam beállítás
- `atadvet.dll` - pénztárak közti átadás/átvétel
- `atadolap.dll` - átadólap
- `bizodisp.dll` - bizonylat tallózás
- `cimlmenu.dll` - címletezés menü
- `eladas.dll` - valuta eladás
- `vasarlas.dll` - valuta vétel
- `napzar.dll` - napi zárás
- `havizar.dll` - havi zárás
- `storno.dll` - sztornó
- `ptartmk.dll` - társpénztár karbantartás
- `listak.dll` - listák, riportok
- `prosbe.dll` - pénztáros beléptetés
- `proski.dll` - pénztáros kiléptetés
- `prostmk.dll` - pénztáros/jelszó karbantartás
- `terminal.dll` - terminál
- `qrgener.dll` - QR / napnyitási segéd
- `regen.dll` - regenerálás
- `super.dll` - supervisor jelszó
- `wunion.dll` - Western Union
- `verzfris.dll` - verziófrissítés

## 4. `IBVALTO` működési modell

### Indulási sorrend
1. egyszeres futás ellenőrzése mutexszel
2. splash és részmodulok betöltése
3. képernyőfelbontás ellenőrzése
4. lokális könyvtárak és ideiglenes fájlok előkészítése
5. hardver- és pénztáradatok beolvasása
6. szerver-hozzáférés meghatározása
7. pénztáros bejelentkeztetése
8. értéktárszám bekérése, ha hiányzik
9. napállapot-ellenőrzés
10. napnyitás, ha kell
11. havi zárás státusz ellenőrzése
12. terminál/OTP jellegű kapcsolatok
13. dekád és kezelési díj ellenőrzése
14. főmenü indítása

### Napi állapotgép
A rendszer erős napnyitás-napzárás logikával működik.

Megkülönböztet:
- normál újrabelépést
- normál új nap nyitását
- lezáratlan nap utáni újranyitási kísérletet
- lezárt nap utáni újrabelépést
- hibás állapotot

### Pénztáros beléptetés
- `prosbe.dll`
- sikeres belépés után a shell kiolvassa a pénztáros nevét és azonosítóját
- naplózza a belépést
- kilépés: `proski.dll`

## 5. Menürendszer

### Főmenü 1. oldal
- `VALUTA VÉTEL`
- `VALUTA ELADÁS`
- `VALUTA KONVERZIÓ`
- `PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL`
- `MAI BIZONYLAT SZTORNÓJA`
- `ÁRFOLYAM BEÁLLITÁSOK`
- `A PILLANATNYI PÉNZTÁR ÁLLÁSA`
- `VALUTA FORGALOM ÖSSZESITŐJE`

Bizonyíték:

```pascal
menubar1.caption := 'VALUTA VÉTEL';
menubar2.caption := 'VALUTA ELADÁS';
menubar3.caption := 'VALUTA KONVERZIÓ';
menubar4.caption := 'PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL';
menubar6.caption := 'MAI BIZONYLAT SZTORNÓJA';
menubar7.caption := 'ÁRFOLYAM BEÁLLITÁSOK';
menubar8.caption := 'A PILLANATNYI PÉNZTÁR ÁLLÁSA';
menubar9.caption := 'VALUTA FORGALOM ÖSSZESITÕJE';
```

### Főmenü 2. oldal
- `A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS`
- `BIZONYLATOK MEGTEKINTÉSE A KÉPERNYŐN`
- `TÁRSPÉNZTÁRAK KARBANTARTÁSA`
- `KÜLÖNFÉLE LISTÁK NYOMTATÁSA`
- `PÉNZTÁROSOK, JELSZAVAK KARBANTARTÁSA`
- `NAPI FORGALOM KIMUTATÁSA`
- `RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA`
- `A PILLANATNYI ÁLLÁS REGENERÁLÁSA`
- `EGYÉB BEÁLLITÁSOK ÉS PROGRAMOK`

### Menü dispatch

```pascal
case _FomenuPont of
  1: begin
       vtempelokeszites(0);
       vasarlasrutin;
     end;
  2: begin
       vtempelokeszites(0);
       eladasrutin;
     end;
  3: Ujkonverzio.Showmodal;
  4: atadatvetrutin;
  6: stornorutin;
  7: arfolyamtmkrutin;
  8: pillallasrutin;
  9: forgosszrutin;
  10: ZarasForm.ShowModal;
  11: bizonylattallozo;
  12: penztartmkrutin;
  13: kulonfelelistak;
  14: penztaroskarbantartas;
  15: napiforgalomrutin;
  16: regizarasrutin;
  17: regeneralorutin(0);
  18: begin
       othertaskrutin;
       Application.terminate;
       exit;
     end;
end;
```

## 6. Fő üzleti folyamatok

### Valuta vétel
- `VTEMP` előkészítése
- `vasarlas.dll`
- ügyfél- és partneradatok beolvasása
- árfolyam és kezelési díj számítása
- bizonylat generálás
- adatbázis könyvelés
- készletfrissítés

### Valuta eladás
- `VTEMP` előkészítése
- `eladas.dll`
- partner- és ügyfélazonosítás
- árfolyam és tranzakciós adatok feldolgozása
- nyomtatás
- könyvelés

### Konverzió
- `UJKONVERZIO`
- összetett vétel+eladás logika
- `VTEMP.KONVERZIO`

### Pénztárak közötti átadás/átvétel
- `atadvet.dll`
- `atadolap.dll`
- belső pénz- és készletmozgatás
- külön bizonylatolt átadás és átvétel

### Sztornó
- `storno.dll`
- nem törlés, hanem ellenművelet
- külön storno bizonylat

### Árfolyamkezelés
- `arftmk.dll`
- `getarf.dll`
- `arfreg.dll`
- `setrate.dll`

### Készlet és pillanatnyi állás
- `pillall.dll`
- `pillkesz.dll`
- `aktkesz.dll`
- `matptar.dll`
- `keszup.dll`
- `keszedit.dll`

### Napi és havi zárás
- `napzar.dll`
- `havizar.dll`
- `cimlmenu.dll`
- `cimlnyom.dll`
- `terminal.dll`

### Regenerálás
- `regen.dll`

### Bizonylattallózás
- `bizodisp.dll`

### Listák és riportok
- `listak.dll`

## 7. Pénztár, értéktár, főértéktár logika

### Pénztár
- kód
- név
- cím
- telefon
- ha nincs pénztáradat, a program megáll

Bizonyíték:

```pascal
sql.add('SELECT * FROM PENZTAR');
...
_HomePenztarKod     := trim(FieldByname('PENZTARKOD').asString);
_homePenztarnev     := trim(FieldByNAme('PENZTARNEV').AsString);
_HomePenztarcim     := trim(FieldByName('PENZTARCIM').asString);
_HomePenztarTelefon := trim(FieldByName('TELEFONSZAM').AsString);
```

### Értéktár
- értéktárszám
- pénzkészlet egyezés/eltérés
- tartozások
- követelések
- banki beszállítás
- banki kiszállítás

### Főértéktári / központi logika
- központi árfolyamlogika
- készletkövetés
- banki kapcsolatok
- körlevelek
- supervisor és engedélyezési logika

## 8. Adatbázisok és szerverlogika

### Fő lokális DB-k
- `c:\valuta\database\valuta.fdb`
- `c:\valuta\database\valdata.fdb`
- `c:\valuta\database\trade.fdb`

### Távoli adatbázisok
- `{host}:C:\RECEPTOR\DATABASE\ugyfelYY.fdb`
- `{host}:C:\RECEPTOR\DATABASE\kisugyfel.fdb`
- `{host}:C:\RECEPTOR\DATABASE\TERRORISTS.FDB`
- `{host}:C:\RECEPTOR\DATABASE\RECEPTOR.FDB`
- `{host}:C:\RECEPTOR\DATABASE\frissito.fdb`

### Kulcstáblák
- `HARDWARE`
- `PENZTAR`
- `VTEMP`
- `JELENLET`
- `BLOKKFEJ`
- `BLOKKTETEL`
- `BFyyMM`
- `BTyyMM`
- `TRADyyMM`
- `PENZTARFORGALOM`

### `VTEMP`
Központi scratch/átadó tábla shell és DLL-ek között.

Bizonyíték:

```pascal
_pcs := 'DELETE FROM VTEMP';
ValutaParancs(_pcs);

_pcs := 'INSERT INTO VTEMP (KONVERZIO) VALUES ('+inttostr(_konverzio)+')';
ValutaParancs(_pcs);
```

## 9. Mentés, frissítés, archiválás

### Mentés
- `MENTES` DLL
- `valuta.fdb` másolása `lastgood` helyre
- `VTEMP` bejegyzés
- `sendokmanyrutin`

Bizonyíték:

```pascal
_valpath  := 'c:\valuta\database\valuta.fdb';
_savePath := 'c:\valuta\mentes\lastgood\valuta.fdb';

if fileExists(_savePath) then sysutils.DeleteFile(_savepath);
copyfileto(_valpath,_savepath);
```

### Verziófrissítés
- `VERZFRIS`
- remote `frissito.fdb`
- lokális DB-k és állományok kezelése

Bizonyíték:

```pascal
_remotePath := _host + ':C:\receptor\database\frissito.fdb';
...
remotedbase.databasename := _remotePath;
```

### `TRADE` archíválás
- régi `TRAD*` táblák kezelése
- housekeeping

## 10. Bizonylatok és dokumentumtípusok

### Fő bizonylattípusok
- `V` - valuta vételi bizonylat
- `E` - valuta eladási bizonylat
- `F` - pénztári átadási bizonylat
- `U` - pénztári átvételi bizonylat
- storno bizonylat
- stornozott másolat
- címletezési lista
- átadólap
- WU nyugta
- telefonfeltöltés bizonylat
- autópályamatrica bizonylat
- egyszerűsített számla
- Paysafe példányok

### Központi blokkformatter
- `Anti\VALUTA\DLL\BLOKNYOM\MAKEDLL\Unit2.pas`

Bizonyíték:

```pascal
GetVTempBasic;
if (_tipus='V') or (_tipus='E') then GetPartnerPara;

if _storno=3 then
  begin
    logirorutin(pchar('Stornóblokk nyomtatás'));
    StornoBlokknyomtatas;
    KilepoTimer.Enabled := True;
    exit;
  end;

if (_tipus='F') OR (_tipus='U') then
    if FileExists(_cimDataPath) then _vancimlet := Cimletbedolgozas;

if _tipus='V' then VetelSzamlaNyomtatas;
if _tipus='E' then EladasSzamlaNyomtatas;
if _tipus='F' then AtadBlokkNyomtatas;
if _tipus='U' then AtveszBlokkNyomtatas;
```

### Közös nyomtatási pipeline
1. szöveg generálása `c:\valuta\aktlst.txt` vagy hasonló fájlba
2. vezérlőkódok beszúrása
3. `LPT1` vagy Windows printer
4. a textfájl kiküldése a nyomtatóra

## 11. `TRADE` rendszer

### Fő funkciók
- telefonfeltöltés
- autópályamatrica
- számla
- tanúsítvány
- logolvasás
- elektronikus kereskedési interfész

### Indulási logika
1. internetellenőrzés
2. alapadatok beolvasása
3. havi TRADE tábla biztosítása
4. logfájl előkészítése
5. matrica összesítő regenerálása
6. tanúsítvány-ellenőrzés
7. pénztáros belépés
8. cikktörzs betöltése

### Könyvelés
- `TRADyyMM` havi táblákba történik

Bizonyíték:

```pascal
_farok := midstr(_mamas,3,2)+midstr(_mamas,6,2);
_tablanev := 'TRAD' + _farok;
...
INSERT INTO ' + _tablanev + ' (...)
```

## 12. Kamera és Java ökoszisztéma

### `camera2\camera`
Modulok:
- `camera-updater`
- `camera-cmn`
- `camera-player`
- `camera-config`
- `camera-office`
- `camera-center`
- `camera-film-restorer`
- `camera-film-inspecter`

### `camera3\old`
Fő típusok:
- desktop client
- management webapp
- camera local/remote
- Western Union inspecter server
- NAV / MNB / egyéb provider szerverek

### Régi desktop kliens menü
Bizonyíték:

```xml
text="Eladás - Vétel"
text="Átadás - Átvétel"
text="Készlet"
text="Árfolyam"
text="Sztornó"
text="Forgalom"
text="Cimletezés"
text="Napzárás"
text="Nyomtatványok"
text="Foglaló"
```

## 13. Kiemelt technikai megfigyelések
- az üzleti logika nagyon nagy része DLL-ekbe van szórva
- erős implicit szerződésekre épít
- `VTEMP` központi szerződési pont
- a nyomtatás textfájl alapú
- a rendszer erősen Windows-függő
- a "szerver" fogalom itt Firebird remote DB-t is jelent

---

# II. Legacy Function Map

## 1. Fő belépési pontok

| Host EXE / App | Entry file | Szerep |
|---|---|---|
| `IBVALTO` | `Anti\VALUTA\IBVALTO\IBVALTO.DPR` | Fő valutás kassza shell, menüvezérlés, napi állapotgép, DLL orchestration |
| `TRADE` | `Anti\VALUTA\TRADE\fejleszt\trade.dpr` | Telefonfeltöltés, autópályamatrica, tanúsítvány, listák |
| `camera2` | `Anti\camera2\camera\pom.xml` | Java alapú kamera/config/office/center ökoszisztéma |
| `camera3 old desktop` | `Anti\camera3\old\excold-desktop-client\...` | Régebbi JavaFX desktop kliens |

## 2. `IBVALTO` főmenü mapping

### Főmenü 1. oldal

| Menu text | Runtime module | DB scope | Document output | Business purpose |
|---|---|---|---|---|
| `VALUTA VÉTEL` | `vasarlas.dll` | `VTEMP`, `BLOKKFEJ`, `BLOKKTETEL`, ügyfél DB-k | `V` bizonylat | valuta felvásárlása ügyféltől |
| `VALUTA ELADÁS` | `eladas.dll` | `VTEMP`, `BLOKKFEJ`, `BLOKKTETEL` | `E` bizonylat | valuta értékesítés ügyfélnek |
| `VALUTA KONVERZIÓ` | `UJKONVERZIO` + vétel/eladás | `VTEMP.KONVERZIO` | konverziós bizonylati lánc | devizaváltás egyik pénznemből a másikba |
| `PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL` | `atadvet.dll` | belső blokk- és pénztári adatok | `F` / `U` bizonylat | belső készletmozgatás |
| `MAI BIZONYLAT SZTORNÓJA` | `storno.dll` | eredeti blokk + storno állapot | storno bizonylat | ellenművelet |
| `ÁRFOLYAM BEÁLLITÁSOK` | `arftmk.dll` | árfolyam adatok | árfolyamnyomtatvány | árfolyam karbantartás |
| `A PILLANATNYI PÉNZTÁR ÁLLÁSA` | `pillall.dll` | készletállapot | álláslista | azonnali kasszaállapot |
| `VALUTA FORGALOM ÖSSZESITŐJE` | `forgossz.dll` | forgalmi aggregátumok | összesítő | forgalom áttekintés |

### Főmenü 2. oldal

| Menu text | Runtime module | DB scope | Document output | Business purpose |
|---|---|---|---|---|
| `A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS` | `ZARASFORM`, `napzar.dll`, `havizar.dll`, `cimlmenu.dll`, `cimlnyom.dll` | `VTEMP`, zárási állapot | napi/havi zárás, címletlista | zárás és készpénzrendezés |
| `BIZONYLATOK MEGTEKINTÉSE A KÉPERNYŐN` | `bizodisp.dll` | `BLOKKFEJ`, `BLOKKTETEL` | tallózás, másolat | korábbi bizonylatok visszanézése |
| `TÁRSPÉNZTÁRAK KARBANTARTÁSA` | `ptartmk.dll` | pénztár törzsadatok | admin output | társpénztár master data |
| `KÜLÖNFÉLE LISTÁK NYOMTATÁSA` | `listak.dll` | blokk- és forgalmi adatok | listák | riporting |
| `PÉNZTÁROSOK, JELSZAVAK KARBANTARTÁSA` | `prostmk.dll` | pénztáros/jelszó adatok | admin output | felhasználókarbantartás |
| `NAPI FORGALOM KIMUTATÁSA` | `napiforg.dll` | napi forgalmi adatok | napi riport | napi teljesítmény |
| `RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA` | `regizaro.dll` | historikus zárási adatok | újranyomtatott zárás | audit/reprodukció |
| `A PILLANATNYI ÁLLÁS REGENERÁLÁSA` | `regen.dll` | `valuta.fdb`, `valdata.fdb` | helyreállított állapot | adatkorrekció |
| `EGYÉB BEÁLLITÁSOK ÉS PROGRAMOK` | `othertsk.dll` | vegyes | vegyes | segéd/admin funkciók |

## 3. Gyorsgombok és közvetlen funkciók

| Funkció | Runtime module | Üzleti szerep |
|---|---|---|
| pénztáros belépés | `prosbe.dll` | műszak indítása |
| pénztáros kilépés | `proski.dll` | műszak lezárása |
| árfolyam history | `arfreg.dll` | történeti árfolyam megtekintése |
| átadólap | `atadolap.dll` | belső átadás dokumentálása |
| supervisor | `super.dll`, `supertsk.dll` | emelt jogosultságú művelet |
| terminál | `terminal.dll`, részben `otp.dll` | bankkártya/terminál folyamat |
| verziófrissítés | `verzfris.dll` | kliensfrissítés |
| körlevelek | `korlev.dll`, `newyear.dll` | központi kommunikáció |

## 4. Riportok és listák

| Report / list | Modul | Üzleti szerep |
|---|---|---|
| kiadott bizonylatok listája | `LISTAK.BizonylatListaPrint` | időszaki bizonylat-áttekintés |
| pénztárforgalmi lista | `LISTAK.PenztarForgalomLista` | belső átadás/átvétel aggregáció |
| forgalomstatisztika | `LISTAK` | vezetői áttekintés |
| havi tabló | `LISTAK` | periódusos riport |
| pillanatnyi készlet | `LISTAK` / készletmodulok | készletellenőrzés |
| dekád lista | `LISTAK` | napi könyvelési ciklus támogatása |
| kezdődíj lista | `LISTAK` | díjellenőrzés |
| napi forgalom | `NAPIFORG` | napi riport |
| régi zárás újranyomtatás | `REGIZARO` | audit és reprodukció |

---

# III. Legacy DB Map

## 1. Adatforrás-rétegek

### Lokális fő adatbázisok
- `c:\valuta\database\valuta.fdb`
- `c:\valuta\database\valdata.fdb`
- `c:\valuta\database\trade.fdb`

### Távoli adatbázisok
- `{host}:C:\RECEPTOR\DATABASE\ugyfelYY.fdb`
- `{host}:C:\RECEPTOR\DATABASE\kisugyfel.fdb`
- `{host}:C:\RECEPTOR\DATABASE\TERRORISTS.FDB`
- `{host}:C:\RECEPTOR\DATABASE\RECEPTOR.FDB`
- `{host}:C:\RECEPTOR\DATABASE\frissito.fdb`

### Egyéb perzisztencia
- `c:\valuta\aktlst.txt` - nyomtatási spool
- `c:\valuta\aktcim.dat` - címletezési input
- `c:\valuta\mentes\lastgood\valuta.fdb` - last good backup

## 2. Magtáblák

### `HARDWARE`
Felel:
- gépfunkció
- megnyitott nap
- lezárt nap
- host
- értéktár
- verzió és gép-specifikus állapot

Kulcs üzleti szerep:
- napi állapotgép
- remote host útvonalak
- gép szerepének meghatározása

### `PENZTAR`
Felel:
- pénztárkód
- pénztárnév
- pénztárcím
- telefonszám

Kulcs üzleti szerep:
- saját iroda beazonosítása
- shell indulásának előfeltétele

### `VTEMP`
A legfontosabb ideiglenes munkatábla.

Azonosított mezők a nyomtatási/üzleti pipeline alapján:
- `DATUM`
- `IDO`
- `TIPUS`
- `KULFOLDI`
- `UGYFELTIPUS`
- `UGYFELSZAM`
- `SECURLEVEL`
- `NETTO`
- `FIZETENDO`
- `KEZELESIDIJ`
- `BIZONYLATSZAM`
- `KONVERZIO`
- `STORNO`
- `TETEL`
- `ELOJEL`
- `PENZTARKOD`
- `STORNOBIZONYLAT`
- `SZALLITONEV`
- `PLOMBASZAM`
- `MEGJEGYZES`
- `COPYINDOK`
- `STORNOINDOK`
- `TARSPENZTARNEV`
- `FIZETOESZKOZ`
- `RECNUMS`
- `ZCOUNTS`
- `KEREKITES`
- `FORRAS`
- `ENGEDELYEZO`
- `KEDVEZMENYESARFOLYAM`
- `MEGBIZOSZAM`
- `KOZSZEREPLO`

Bizonyíték:

```pascal
_datum          := trim(FieldByname('DATUM').AsString);
_ido            := trim(FieldByName('IDO').AsString);
_tipus          := trim(FieldByName('TIPUS').AsString);
_ugyfeltipus    := FieldByNAme('UGYFELTIPUS').asString;
_ugyfelszam     := FieldByNAme('UGYFELSZAM').asInteger;
_netto          := FieldByName('NETTO').asInteger;
_fizetendo      := FieldByName('FIZETENDO').asInteger;
_kezelesidij    := FieldByNAme('KEZELESIDIJ').asInteger;
_bizonylatszam  := FieldByNAme('BIZONYLATSZAM').asstring;
_konverzio      := FieldByname('KONVERZIO').asInteger;
_storno         := FieldByName('STORNO').asInteger;
_penztarkod     := FieldByName('PENZTARKOD').asString;
_stornobizonylat:= trim(FieldByName('STORNOBIZONYLAT').asString);
_reprintindok   := trim(FieldByName('COPYINDOK').asString);
_stornoindok    := trim(FieldByName('STORNOINDOK').asstring);
_engedelyezo    := trim(FieldByname('ENGEDELYEZO').asstring);
```

### `JELENLET`
Szerepe:
- az aznapi jelenléti / session jellegű állapot
- új nap nyitásakor a korábbi napok törlése

### `BLOKKFEJ`
Szerepe:
- bizonylat fej rekordok
- dátum, stornoállapot, bizonylatszám és kapcsolódó meta

### `BLOKKTETEL`
Szerepe:
- bizonylat tételsorok
- valutánem
- bankjegy
- forintérték
- árfolyam

### `BFyyMM`, `BTyyMM`
Historikus havi lezárt állományok:
- `BFyyMM` fej
- `BTyyMM` tétel

### `PENZTARFORGALOM`
Szerepe:
- belső átadás/átvétel összesítések
- riporting és aggregáció

### `TRADyyMM`
`TRADE` havi könyvelési tábla.

Matrica jellegű könyvelt mezők:
- `TIPUS`
- `BIZONYLATSZAM`
- `KATEGORIA`
- `STARTDATUM`
- `ENDDATUM`
- `RENDSZAM`
- `COUNTRYNAME`
- `REFERENCEID`
- `TRANZAKCIO`
- `FIZETENDO`
- `PENZTAROSNEV`
- `DATUM`
- `IDO`
- `UGYFELSZAM`
- `UGYFELNEV`
- `UGYFELCIM`
- `ELKULDVE`

Telefonfeltöltés jellegű könyvelt mezők:
- `TIPUS`
- `BIZONYLATSZAM`
- `TRANZAKCIO`
- `TELEFONSZAM`
- `FIZETENDO`
- `PENZTAROSNEV`
- `DATUM`
- `IDO`
- `SZOLGALTATO`
- `SZOLGALTATAS`
- `ELKULDVE`

Bizonyíték:

```pascal
_tablanev := 'TRAD' + _farok;
...
INSERT INTO ' + _tablanev + ' (TIPUS,BIZONYLATSZAM,KATEGORIA,
STARTDATUM,ENDDATUM,RENDSZAM,COUNTRYNAME,REFERENCEID,TRANZAKCIO,FIZETENDO,
PENZTAROSNEV,DATUM,IDO,UGYFELSZAM,UGYFELNEV,UGYFELCIM,ELKULDVE)
```

## 3. Funkció -> DB map

| Funkció | Fő DB / tábla | Megjegyzés |
|---|---|---|
| shell indulás | `HARDWARE`, `PENZTAR` | gép és pénztár környezet |
| pénztáros belépés | pénztáros/jelszó adatok | DLL kezeli, shell olvassa eredményt |
| valuta vétel/eladás | `VTEMP`, `BLOKKFEJ`, `BLOKKTETEL` | customer-facing core tranzakció |
| konverzió | `VTEMP.KONVERZIO` + blokk adatok | összetett tranzakció |
| átadás/átvétel | blokk adatok + társpénztár | belső treasury mozgás |
| bizonylat nyomtatás | `VTEMP` + spool file | dokumentum-centrikus pipeline |
| listázás | `BTyyMM`, `BLOKKTETEL`, `VTEMP` | historikus és mai adatok kombinálása |
| zárás | `HARDWARE`, `VTEMP`, zárási állapot | nap/hónap állapotgép |
| mentés | `valuta.fdb` -> backup path | fájlmásolás alapú |
| frissítés | `frissito.fdb` | remote update koordináció |
| terrorlista | `TERRORISTS.FDB` | compliance |
| WU | `valuta.fdb`, `valdata.fdb`, ügyfél DB | külön bounded domain |
| `TRADE` retail flow | `TRADyyMM`, `MATRICA.FDB` | mellékrendszer |

## 4. Riport / DB map

Bizonyíték a listázó átmeneti töltési logikára:

```pascal
_pcs := 'SELECT * FROM ' + _btTablanev
...
_pcs := _pcs + ' AND (STORNO=1)';
...
_pcs := 'INSERT INTO VTEMP (DATUM,TIPUS,VALUTANEM,ARFOLYAM,BANKJEGY,FORINTERTEK,BIZONYLATSZAM)'
```

Ez azt jelenti, hogy:
- a historikus havi táblákból és a mai élő táblákból is dolgozik
- a listázás előtt sok esetben `VTEMP`-be tölti át a kért halmazt
- a listázó réteg sem közvetlenül a teljes domaint modellezi, hanem átmeneti aggregált munkatáblát használ

## 5. Szerver- és hostfüggő DB map

### Távoli host szerepe
A `HARDWARE.HOST` mezőből számított útvonalak határozzák meg a remote DB-k elérését.

Bizonyíték:

```pascal
_remoteFdbPath := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';
RemoteDbase.DatabaseName := _remoteFdbPath;
```

Következmény:
- a szerverfogalom itt DB host
- nem REST API, hanem remote Firebird endpoint

## 6. Modernizációs DB-követelmények

Az új rendszernek legalább ezt a logikát kell explicit módon modelleznie:

- office / cashdesk / hardware state
- day state machine
- transaction header + lines
- document metadata
- print/reprint/storno audit
- temporary request state helyett explicit command model
- historical partitioning / monthly grouping
- remote sync/integration state
- backup and recovery state

---

# IV. AI Prompt

## Használat
Az alábbi szöveg mesterséges intelligencia ügynöknek szánt, végrehajtható prompt. Célja, hogy a legacy rendszerből formalizált specifikáció, adatmodell és modern implementációs terv legyen előállítható.

## Prompt
Te egy senior szintű szoftverarchitekt, legacy reverse engineer, pénzügyi domain-elemző és implementáló AI ügynök vagy. A feladatod a `D:\repo\valutavalto-program\Anti` könyvtárban található örökölt valutaváltó rendszer teljes mélységű elemzése, strukturálása és abból egy pontos, végrehajtható modernizációs vagy újraimplementálási specifikáció előállítása.

Nem marketing anyagot kell írnod, nem felületes repo-overview-t kell adnod, hanem kódbázis-alapú, bizonyítékokra támaszkodó üzleti és technikai feltárást.

### Küldetésed
1. Térképezd fel a rendszer top-level szerkezetét.
2. Azonosítsd a fő futtatható desktop alkalmazásokat.
3. Fejtsd meg a DLL-alapú plugin architektúrát.
4. Állítsd össze a teljes pénztári, értéktári, zárási, árfolyam-, bizonylat- és riportlogikát.
5. Dokumentáld az adatbázisokat, táblákat, átmeneti állapotokat és fájlrendszer-függéseket.
6. Emeld ki a nem-negotiable üzleti szabályokat.
7. Készíts olyan outputot, amelyből új rendszer implementálható.

## Kötelező szemlélet
- Domain-first
- Bizonyíték-first
- Üzleti logika fontosabb, mint a puszta UI-leírás
- Állapotgépek fontosabbak, mint a gombszintű felsorolás
- Adatfolyam fontosabb, mint a felszíni képernyőleírás
- Nyomtatvány és audit fontosabb, mint a puszta CRUD

### Amit tilos tenned
- Ne találj ki nem bizonyított funkciókat.
- Ne kezeld egyszerű pénztárprogramként.
- Ne redukáld a szerverfogalmat HTTP API-ra.
- Ne hagyd figyelmen kívül a zárási állapotgépet.
- Ne hagyd figyelmen kívül a bizonylati láncot és a storno ellenműveletet.
- Ne hagyd figyelmen kívül a címletezést, értéktárat, banki mozgást és körleveleket.

## A rendszer rövid értelmezése
Az `Anti` könyvtár egy legacy vállalati valutaváltó rendszer. Három nagy világa van:

1. Klasszikus Delphi pénztári mag (`VALUTA`)
2. Külön kiegészítő Delphi kereskedelmi rendszer (`TRADE`)
3. Java alapú kamera, office, center és inspecter rendszerek (`camera2`, `camera3`)

Ez nem csak valutavétel és eladás. A rendszer tud:
- valuta vétel
- valuta eladás
- konverzió
- pénztárak közti átadás/átvétel
- pénztár és értéktár készletlánc
- napnyitás, napzárás, havi zárás
- árfolyamkezelés és történet
- bizonylatkiadás, sztornó, újranyomtatás
- készlet- és forgalmi riportok
- Western Union műveletek
- top-up és e-matrica jellegű mellékfolyamatok
- mentés, frissítés, dokumentumküldés
- kameraexport és kapcsolódó központi funkciók

## Legfontosabb architekturális minta: `VTEMP`
Az `IBVALTO` és a DLL-ek nem explicit objektummodellen vagy API-kon kommunikálnak, hanem egy ideiglenes adatbázistáblán keresztül.

Kötelező feladat:
- azonosítsd a `VTEMP` mezőit
- írd le a jelentésüket
- különítsd el az input, work-state és output mezőket
- képezz belőlük modern command/request modellt

## Bizonylati rendszer
A legacy rendszer dokumentumközpontú. Nem elég a tranzakciókat lemodellezni. A bizonylat a domain része.

### Kötelező dokumentumtípusok
- `V`
- `E`
- `F`
- `U`
- storno
- stornozott másolat
- címletezési lista
- átadólap
- WU nyugta
- telefonfeltöltés bizonylat
- e-matrica bizonylat
- egyszerűsített számla
- Paysafe példányok

## Zárási állapotgép
Formális állapotgép-szinten dokumentáld:
- új nap indítható
- lezáratlan nap van
- nap már lezárt
- hónap nincs lezárva
- kötelező nyomtatvány hiányzik

## Pénztár, értéktár, banki lánc
Különítsd el:
- customer-facing tranzakciókat
- internal treasury mozgásokat
- bank interfész jellegű mozgásokat

## Adatbázisok és perzisztencia
Tekintendő fő adatbázisok:
- `c:\valuta\database\valuta.fdb`
- `c:\valuta\database\valdata.fdb`
- `c:\valuta\database\trade.fdb`
- `{host}:C:\RECEPTOR\DATABASE\...`

Kötelezően feltárandó táblák:
- `HARDWARE`
- `PENZTAR`
- `VTEMP`
- `JELENLET`
- `BLOKKFEJ`
- `BLOKKTETEL`
- `BFyyMM`
- `BTyyMM`
- `TRADyyMM`
- `PENZTARFORGALOM`

## Mentés, frissítés, operáció
Írd le:
- backup stratégia
- restore stratégia
- update stratégia
- field operations runbook

## `TRADE` külön kezelése
Ne olvaszd össze a fő valutás maggal. Készíts külön bounded context értelmezést.

## Kamera és Java ökoszisztéma
Kezeld külön platformként. Hasonlítsd össze a Delphi főmenüvel, és készíts capability crosswalkot.

## Kötelező deliverable-ek
1. `legacy-function-map.md`
2. `legacy-db-map.md`
3. `domain-model.md`
4. `transaction-lifecycle.md`
5. `document-types.md`
6. `state-machines.md`
7. `integration-map.md`
8. `modernization-roadmap.md`
9. `bounded-contexts.md`
10. `migration-risk-register.md`

## Prioritási sorrend
1. `IBVALTO` shell és menü dispatch
2. `VTEMP`
3. `VASARLAS`, `ELADAS`, `STORNO`, `ATADVET`, `NAPZAR`, `LISTAK`, `BLOKNYOM`
4. `HARDWARE`, `PENZTAR`, `BLOKKFEJ`, `BLOKKTETEL`, havi táblák
5. mentés, frissítés, dokumentumküldés
6. `TRADE`
7. `camera2` és `camera3`
8. modern célrendszer tervezése

## Elvárt válaszformátum az AI-tól
Minden nagy témánál:
1. Funkció neve
2. Bizonyíték
3. Működési logika
4. Érintett DB / állapot
5. Kimenet / dokumentum
6. Üzleti jelentés
7. Modern megfelelő
8. Kockázat / nyitott kérdés

## Végső utasítás
Az `Anti` rendszert ne elavult kódtömegként kezeld, hanem egy éles üzleti tudást tároló, rejtett domain-specifikációként. A célod nem a források felsorolása, hanem az, hogy a rendszerből:

- formális üzleti specifikációt
- migrálható adatmodellt
- újraimplementálható use-case készletet
- auditálható dokumentum- és állapotgépet
- modern, de a legacy működést megőrző célarchitektúrát hozz létre

## Kiemelt forrásfájlok
- `D:\repo\valutavalto-program\antivaluta.GPT-5.4.md`
- `D:\repo\valutavalto-program\Anti\VALUTA\IBVALTO\IBVALTO.DPR`
- `D:\repo\valutavalto-program\Anti\VALUTA\IBVALTO\UNIT1.PAS`
- `D:\repo\valutavalto-program\Anti\VALUTA\IBVALTO\Unit47.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\DLL\BLOKNYOM\MAKEDLL\Unit2.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\DLL\LISTAK\MAKEDLL\Unit2.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\DLL\MENTES\MAKEDLL\Unit2.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\TRADE\fejleszt\unit1.pas`
- `D:\repo\valutavalto-program\Anti\camera2\camera\pom.xml`
- `D:\repo\valutavalto-program\Anti\camera3\old\excold-desktop-client\target\classes\fxml\MainMenu.fxml`

