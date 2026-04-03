# Anti rendszer teljes körű feltérképezése

## Cél és hatókör
Ez a dokumentum a `D:\repo\valutavalto-program\Anti` könyvtár teljes forrásalapú feltérképezése alapján készült. A célja, hogy technikai és üzleti szinten is leírja:

- a rendszer szerkezetét
- a fő futtatható alkalmazásokat és alrendszereket
- a menüket és üzleti folyamatokat
- a pénztári, értéktári, szerveres, mentési és bizonylatkezelési logikát
- a Delphi/Pascal DLL-modulok szerepét
- a Java alapú kamera- és központi rendszerek kapcsolatát

## Fontos megjegyzés
A workspace-ben tényleges `.dll` és `.exe` binárisok nem találhatók, ezért a leírás a hozzájuk tartozó Delphi projektfájlokból, Pascal forrásokból, DFM formokból, Java forrásokból, konfigurációkból és egyéb artefaktokból készült. A DLL-ek működése a forrásuk és a főalkalmazásból történő hívásaik alapján rekonstruált.

## 1. Top-level rendszerkép
Az `Anti` mappa nem egyetlen program, hanem több generációból álló, hibrid pénzügyi ökoszisztéma.

### Fő részek
- `Anti\VALUTA`
  - a klasszikus Delphi/Pascal valutaváltó mag
  - fő belépési pontok: `IBVALTO`, `TRADE`, valamint nagy számú DLL modul
- `Anti\camera2\camera`
  - újabb Java/Maven alapú kamera és központi platform
  - moduláris, több komponensből álló rendszer
- `Anti\camera3\old`
  - régebbi Java ökoszisztéma
  - külön management, desktop client, WU inspecter, NAV és más szerverek
- `Anti\camera`
  - telepítési és futtatási artefaktok, konfigurációs maradványok

### Technológiai rétegek
- Delphi 7 / Pascal desktop kliens és DLL plugin-rendszer
- InterBase / Firebird alapú lokális és távoli adatbázisok
- JavaFX / Spring / MySQL alapú újabb vagy kísérő rendszerek
- fájlalapú nyomtatás, export és mentés
- távoli Firebird elérés host:path formában
- HTTP, FTP és segéd-EXE integrációk

## 2. A legacy valutás mag szerkezete

### 2.1. Fő desktop alkalmazások

#### `IBVALTO`
Ez a fő valutaváltó kasszaprogram.

Belépési pont:
- `Anti\VALUTA\IBVALTO\IBVALTO.DPR`

Lényegi jellemzők:
- mutexszel védi az egyszeres futást: `IBVALTO.EXE`
- splash/loader képernyőt használ
- betölti a fő formokat:
  - `FORM1`
  - `ZARASFORM`
  - `FOMENUFORM`
  - `UJKONVERZIO`
  - `OPENKERDOFORM`
  - `TOLTOFORM`
  - `TRYAGAINFORM`

Ez az alkalmazás nem közvetlenül implementál minden üzleti folyamatot, hanem egy shell/orchestrator szerepet tölt be, és a konkrét műveleteket a `c:\valuta\bin\*.dll` modulokba delegálja.

#### `TRADE`
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

Ez nem azonos az `IBVALTO` napi valutás főfolyamataival, hanem külön üzleti kiegészítő alkalmazás.

### 2.2. DLL alapú plugin architektúra
Az `IBVALTO` működésének gerince az, hogy a főprogram egy nagy külső DLL-készletet hív.

Példák a központi DLL-importokra:
- `getarf.dll` - árfolyam letöltés
- `arfreg.dll` - árfolyam regiszter
- `arftmk.dll` - árfolyam beállítások
- `atadvet.dll` - pénztárak közötti átadás/átvétel
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
- `qrgener.dll` - QR kijelzés / napnyitási segéd
- `regen.dll` - regenerálás
- `super.dll` - supervisor jelszó
- `wunion.dll` - Western Union
- `verzfris.dll` - verziófrissítés

Ez gyakorlatban azt jelenti, hogy a shell csak irányít, az üzleti logika jelentős része a DLL-ekben van szétszedve.

## 3. `IBVALTO` működési modellje

### 3.1. Indulási sorrend
Az indulás főbb lépései:

1. egyszeres futás ellenőrzése mutexszel
2. splash és részmodulok betöltése
3. képernyőfelbontás ellenőrzése
4. lokális könyvtárak és ideiglenes fájlok előkészítése
5. hardver- és pénztáradatok beolvasása
6. szerver-hozzáférés állapotának meghatározása
7. pénztáros bejelentkeztetése DLL-en keresztül
8. értéktárszám bekérése, ha hiányzik
9. napállapot-ellenőrzés
10. szükség esetén napnyitás
11. havi zárás státusz ellenőrzése
12. opcionális terminál/OTP beléptetés
13. dekád és kezelési díj nyomtatások ellenőrzése
14. főmenü indítása

### 3.2. Napi állapotgép
A rendszer nagyon erős napnyitás-napzárás logikával működik.

A `ZarasControl` jellegű logika alapján a program megkülönböztet:
- normál újrabelépést
- normál új nap nyitását
- lezáratlan nap utáni újranyitási kísérletet
- lezárt nap utáni újrabelépést
- hibás állapotot

Ez üzletileg azt jelenti, hogy a napi működés nem szabadon indul újra, hanem a rendszer napstátusza vezérli.

### 3.3. Pénztáros beléptetés
A kasszás nem a shellben azonosítja magát, hanem külső DLL kezeli a beléptetést:
- `prosbe.dll`

Sikeres belépés után:
- a shell kiolvassa a pénztáros azonosítóját és nevét
- naplózza a belépést
- megjeleníti az aktív kezelőt

Kilépés:
- `proski.dll`

### 3.4. Hardver és környezet
A shell induláskor foglalkozik:
- képernyőfelbontással
- log és körlevél könyvtárakkal
- hardver adatokkal
- pénztár paraméterekkel
- verziófrissítés szükségességével
- futófény / hirdetés panellel
- terminál és opcionális integrációk kapcsolóival

## 4. A `IBVALTO` menürendszere

### 4.1. Menüstruktúra
Az alkalmazás nem klasszikus `TMainMenu` menüt használ, hanem saját paneles főmenüt:
- `FOMENUFORM`
- kétoldalas menü
- 9-9 menüponttal

### 4.2. Főmenü 1. oldal
- `VALUTA VÉTEL`
- `VALUTA ELADÁS`
- `VALUTA KONVERZIÓ`
- `PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL`
- üres / tiltott hely
- `MAI BIZONYLAT SZTORNÓJA`
- `ÁRFOLYAM BEÁLLITÁSOK`
- `A PILLANATNYI PÉNZTÁR ÁLLÁSA`
- `VALUTA FORGALOM ÖSSZESITŐJE`

### 4.3. Főmenü 2. oldal
- `A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS`
- `BIZONYLATOK MEGTEKINTÉSE A KÉPERNYŐN`
- `TÁRSPÉNZTÁRAK KARBANTARTÁSA`
- `KÜLÖNFÉLE LISTÁK NYOMTATÁSA`
- `PÉNZTÁROSOK, JELSZAVAK KARBANTARTÁSA`
- `NAPI FORGALOM KIMUTATÁSA`
- `RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA`
- `A PILLANATNYI ÁLLÁS REGENERÁLÁSA`
- `EGYÉB BEÁLLITÁSOK ÉS PROGRAMOK`

### 4.4. Menü dispatch
A kiválasztott menüpontot a shell timer alapú diszpécserrel futtatja le:

- 1 -> `vasarlasrutin`
- 2 -> `eladasrutin`
- 3 -> `Ujkonverzio.ShowModal`
- 4 -> `atadatvetrutin`
- 6 -> `stornorutin`
- 7 -> `arfolyamtmkrutin`
- 8 -> `pillallasrutin`
- 9 -> `forgosszrutin`
- 10 -> `ZarasForm.ShowModal`
- 11 -> `bizonylattallozo`
- 12 -> `penztartmkrutin`
- 13 -> `kulonfelelistak`
- 14 -> `penztaroskarbantartas`
- 15 -> `napiforgalomrutin`
- 16 -> `regizarasrutin`
- 17 -> `regeneralorutin`
- 18 -> `othertaskrutin`, majd kilépés

### 4.5. Gyorsgombok és egyéb látható funkciók
A fő formon a menün kívül külön gombok/funkciósáv is látszik. A források alapján ezek közt szerepel:
- főmenü
- árfolyam
- foglaló
- terminál
- ÁFA tábla
- mai forgalom
- Tesco ÁFA
- Metro ÁFA
- supervisor
- készlet
- átadólap
- Western Union
- kilépés
- verziófrissítés
- körlevelek

## 5. Fő üzleti folyamatok

### 5.1. Valuta vétel
Menüpont:
- `VALUTA VÉTEL`

Folyamat:
1. `VTEMP` előkészítése `KONVERZIO=0` értékkel
2. `vasarlas.dll` meghívása
3. partner- és ügyféladatok beolvasása
4. árfolyam, címlet, fizetendő és kezelési díj számítása
5. bizonylat generálás
6. adatbázis könyvelés
7. készletállapot frissítése

### 5.2. Valuta eladás
Menüpont:
- `VALUTA ELADÁS`

Folyamat:
1. `VTEMP` előkészítése
2. `eladas.dll` meghívása
3. partner- és ügyfélazonosítás
4. árfolyam és tranzakciós adatok feldolgozása
5. nyomtatás
6. könyvelés

### 5.3. Konverzió
Menüpont:
- `VALUTA KONVERZIÓ`

Folyamat:
- a `UJKONVERZIO` form dolgozik
- üzletileg ez vétel+eladás jellegű összetett tranzakció
- a shell szerint végül ugyanúgy `vasarlas` és `eladas` logikára támaszkodik
- a `VTEMP` `KONVERZIO` mezője külön jelöli

### 5.4. Pénztárak közötti átadás/átvétel
Menüpont:
- `PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL`

Kapcsolódó modulok:
- `atadvet.dll`
- `atadolap.dll`

Üzleti jelentés:
- pénztár és társpénztár közötti pénzmozgás
- a rendszer külön bizonylatolja az átadást és az átvételt
- pénz, valuta, jutalék és egyes esetekben készlet/társ-pénztári viszony is megjelenik

### 5.5. Sztornó
Menüpont:
- `MAI BIZONYLAT SZTORNÓJA`

Kapcsolódó modul:
- `storno.dll`

Üzleti szabály:
- nem egyszerű törlés
- storno bizonylatot állít elő
- hivatkozik az eredeti bizonylatra
- külön ok és státuszmezőkkel dolgozik

### 5.6. Árfolyamkezelés
Menüpont:
- `ÁRFOLYAM BEÁLLITÁSOK`

Kapcsolódó modulok:
- `arftmk.dll`
- `getarf.dll`
- `arfreg.dll`
- `setrate.dll`

Funkciók:
- árfolyam beállítás
- árfolyam letöltés
- árfolyam történet / regiszter
- kedvezményes árfolyamok
- engedélyhez kötött árfolyam-módosítás

### 5.7. Pillanatnyi pénztárállás és készlet
Menüpontok:
- `A PILLANATNYI PÉNZTÁR ÁLLÁSA`
- készlet jellegű gombok

Kapcsolódó modulok:
- `pillall.dll`
- `pillkesz.dll`
- `aktkesz.dll`
- `matptar.dll`
- `keszup.dll`
- `keszedit.dll`

Funkciók:
- aktuális készletnézet
- címlet- és valutabontás
- pénztár és társpénztár készletviszonyok
- bizonyos esetekben szerver felé készletbeküldés

### 5.8. Napi és havi zárás
Menü:
- `A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS`

Kapcsolódó modulok:
- `napzar.dll`
- `havizar.dll`
- `cimlmenu.dll`
- `cimlnyom.dll`
- `terminal.dll`

Napi zárás logika:
1. `VTEMP` feltöltése a nyitott nappal
2. `napzarrutin`
3. siker esetén a rendszer jelzi, hogy az adatok beküldhetők
4. innen terminálművelet is indítható

Havi zárás:
- külön fut
- a rendszer blokkolhatja a munkát, ha előző hónap nincs lezárva

### 5.9. Regenerálás
Menüpont:
- `A PILLANATNYI ÁLLÁS REGENERÁLÁSA`

Kapcsolódó modul:
- `regen.dll`

Szerepe:
- pillanatnyi állás és adatállapot újraszámítása / helyreállítása
- kritikus adminisztratív/helyreállító funkció

### 5.10. Bizonylat tallózás és újranyomtatás
Menüpont:
- `BIZONYLATOK MEGTEKINTÉSE A KÉPERNYŐN`

Kapcsolódó modul:
- `bizodisp.dll`

Funkciók:
- korábbi bizonylatok listázása
- típus szerinti megjelenítés
- másolat / újranyomtatás
- stornozott és storno bizonylatok megkülönböztetése

### 5.11. Különféle listák, riportok
Menüpont:
- `KÜLÖNFÉLE LISTÁK NYOMTATÁSA`

Kapcsolódó modul:
- `listak.dll`

Fő riportok:
- kiadott bizonylatok listája
- pénztárforgalmi lista
- TRB-specifikus forgalomlista
- forgalomstatisztika
- havi tabló
- pillanatnyi készlet
- dekád lista
- kezdődíj lista

## 6. Pénztár, értéktár, főértéktár logika

### 6.1. Pénztár
A rendszer pénztárcentrikus:
- minden kasszához kód, név, cím, telefon tartozik
- a `PENZTAR` tábla alap a működéshez
- ha nincs pénztáradat, a program leáll

### 6.2. Értéktár
Az értéktár a kasszát ellátó és összesítő szereplő.

Bizonyítékok az üzleti modellre:
- értéktárszám bekérése induláskor
- `ERTEKTARI ATADOLAP`
- pénzkészlet egyezés/nem egyezés/eltérés logika
- tartozások és követelések
- banki beszállítás és kiszállítás

### 6.3. Főértéktári / központi logika
A forrásokból erősen kirajzolódik:
- központi árfolyamlogika
- készletkövetés
- banki kapcsolatok
- körlevelek
- engedélyezési és supervisor logika

Ez a rendszer nem egyszerű pénztárprogram, hanem hálózatos treasury modell.

## 7. Adatbázis és szerveroldali működés

### 7.1. Fő adatbázis-modell
A Delphi rész InterBase/Firebird adatbázisokra épül.

Jellemző lokális adatbázisfájlok:
- `c:\valuta\database\valuta.fdb`
- `c:\valuta\database\valdata.fdb`
- `c:\valuta\database\trade.fdb`

Távoli adatbázisok:
- `{host}:C:\RECEPTOR\DATABASE\...`
- például:
  - `ugyfelYY.fdb`
  - `kisugyfel.fdb`
  - `TERRORISTS.FDB`
  - `RECEPTOR.FDB`
  - `frissito.fdb`

### 7.2. Kulcstáblák és jelentésük
A források alapján a rendszer több fontos táblát használ:

- `HARDWARE`
  - gépfunkció, napállapot, értéktár, verzió és gépspecifikus beállítások
- `PENZTAR`
  - a saját pénztár törzsadatai
- `VTEMP`
  - központi scratch/átadó tábla a shell és a DLL-ek között
- `JELENLET`
  - napi jelenlét / aznapi állapot
- `BLOKKFEJ`
  - bizonylat fej
- `BLOKKTETEL`
  - bizonylat tételek
- `BFyyMM`, `BTyyMM`
  - havi lezárt fej/tétel állományok
- `TRADyyMM`
  - a `TRADE` alkalmazás havi könyvelési táblái
- `PENZTARFORGALOM`
  - pénztárforgalmi összesítő

### 7.3. `VTEMP` szerepe
Az egyik legfontosabb architekturális elem.

Feladata:
- shell -> DLL paraméterátadás
- tranzakció közbeni ideiglenes állapot
- nyomtatáshoz szükséges metaadatok átadása
- napzárás és egyéb funkciók paraméterezése

Lényegében egy köztes munkatábla, amelyre a modulok implicit szerződéssel támaszkodnak.

### 7.4. Szerverfogalom a rendszerben
Az `Anti` világában a "szerver" nem kizárólag HTTP API-t jelent.

Három szerverjellegű működés van:

1. Firebird/InterBase távoli adatbázis-hub
   - `C:\RECEPTOR\DATABASE\...`
   - ügyfél, terrorlista, frissítő, receptor adatok

2. Java központi alkalmazások
   - kamera office/center/inspecter
   - management webapp
   - WU inspecter

3. külső HTTP/FTP kapcsolatok
   - kupon/topup szolgáltatás
   - üzenetküldés
   - fájlletöltés/feltöltés

## 8. Mentés, archiválás, frissítés

### 8.1. Mentés
Külön `MENTES` DLL modul létezik.

Feltárt működés:
- a `valuta.fdb` másolása:
  - forrás: `c:\valuta\database\valuta.fdb`
  - cél: `c:\valuta\mentes\lastgood\valuta.fdb`
- utána `VTEMP` bejegyzés készül
- majd `sendokmanyrutin` fut

Ez alapján a mentés:
- legalább részben fájlmásolás alapú
- naphoz kötött folyamat
- kiegészül dokumentumküldéssel/exporttal

### 8.2. Archíválás a `TRADE` rendszerben
Nem klasszikus backup, inkább adatritkítás.

Az `Archivalo` logika:
- régi `TRAD*` táblákat vizsgál
- korábbi év adatait dobhatja
- housekeeping jellegű

### 8.3. Verziófrissítés
Külön modul:
- `VERZFRIS`

A források szerint:
- távoli `frissito.fdb` elérhető
- lokális `trade.fdb`, `valuta.fdb`, `valdata.fdb` állományokat kezeli
- másolási/logikai frissítési lépések vannak

## 9. Bizonylatok, nyomtatás, dokumentumtípusok

### 9.1. Közös nyomtatási pipeline
Szinte az összes nyomtatás az alábbi mintát követi:

1. szöveg generálása `c:\valuta\aktlst.txt` vagy hasonló fájlba
2. ESC/P vagy hasonló vezérlőkódok beszúrása
3. `LPT1` vagy Windows printer használata
4. fájl tartalmának kiküldése a nyomtatóra

Ez fontos, mert:
- a bizonylatformátumok nagy része plain text alapú
- a layoutot a Pascal kód kézzel rajzolja ki
- nincs külön modern report engine a klasszikus magban

### 9.2. Fő bizonylattípusok
A forrásokból egyértelműen azonosítható típusok:

- `V` - valuta vételi bizonylat / számla
- `E` - valuta eladási bizonylat / számla
- `F` - pénztári átadási bizonylat
- `U` - pénztári átvételi bizonylat
- storno bizonylat
- stornozott bizonylat másolat
- címletezési lista
- átadólap
- WU nyugta
- telefonfeltöltés bizonylat
- autópályamatrica bizonylat
- egyszerűsített számla
- Paysafe saját és vevőpéldány
- különféle listák és összesítők

### 9.3. A `BLOKNYOM` központi szerepe
A klasszikus pénztári bizonylatok fő formattere:
- `Anti\VALUTA\DLL\BLOKNYOM\MAKEDLL\Unit2.pas`

Kezelt nyomtatások:
- `VetelSzamlaNyomtatas`
- `EladasSzamlaNyomtatas`
- `AtadBlokkNyomtatas`
- `AtveszBlokkNyomtatas`
- `StornoBlokkNyomtatas`
- árfolyammódosítási nyomtatás
- reklám / ügyfél / nyilatkozat típusú nyomtatások
- devizastátusz nyomtatás

### 9.4. Bizonylat tartalmi elemei
A forrás alapján jellemző mezők:
- cégadatok
- pénztárkód, pénztárnév, cím
- adószám
- terminál azonosító
- bizonylatszám
- dátum, idő
- ügyféladatok
- jogi személy adatok
- okmány adatok
- pénznem
- árfolyam
- bankjegyösszeg
- forintérték
- kezelési díj
- megjegyzés
- reprint indok
- storno indok
- engedélyező
- társpénztár neve
- forrás

### 9.5. Újranyomtatás
Külön támogatott.

Kapcsolódó adatok:
- másolat jelölés
- újranyomtatási indok
- eredeti/storno hivatkozás

### 9.6. Átadólapok
Két fontos forma:

#### Értéktári átadólap
Tartalma:
- értéktárszám
- dátum
- átadó
- átvevő
- pénzkészlet egyezés / eltérés
- tartozások
- követelések
- Western Union / ÁFA rendelések
- banki beszállítás
- banki kiszállítás
- pénztári rendelések
- körlevelek
- egyéb fontos információk

#### Pénztári átadólap
Tartalma:
- pénztárszám
- dátum
- átadó
- átvevő
- körlevelek
- ügyfélrendelések
- készletrendelés értéktár felé
- konkurenciával kapcsolatos tudnivalók
- egyéb tudnivalók

### 9.7. Western Union bizonylatok
A `WUNION` modul külön nyugtavilágot használ.

Típusok:
- átvétel exclusive cash pénztártól
- átadás exclusive cash pénztárnak
- átvétel Western Union pénztártól
- átadás Western Union pénztárnak
- pénzátvétel ügyféltől
- pénzátadás ügyfélnek

Jellemző adatok:
- bizonylatszám
- MTCN szám
- dátum, idő
- átadott/átvett összeg és devizanem
- szállító neve
- zsákplombaszám
- aláírási mezők

### 9.8. `TRADE` bizonylatok

#### Telefonfeltöltés
Szolgáltatók:
- T-Mobile
- Telenor
- Vodafone
- T-Com
- NeoPhone
- Tesco

Jellemző szövegek:
- szolgáltató megnevezése
- feltöltés dátuma
- telefonszám
- feltöltési összeg
- tranzakcióazonosító
- ügyfélszolgálati információk
- "Nem adóügyi bizonylat"

#### E-matrica
Típusok:
- seller copy
- customer copy
- egyszerűsített számla

Tartalmak:
- rendszám
- ország
- kategória
- érvényesség
- referencia
- fizetendő
- vevő adatai
- adószám

#### Paysafe
Típusok:
- vevőpéldány
- saját példány

#### `TRADE` zárási bizonylat
Az `F-...` logikájú pénzforgalmi záró/storno dokumentum is megjelenik.

## 10. Riportok és listák

### 10.1. Kiadott bizonylatok listája
Külön listázás készül:
- vétel (`V`)
- eladás (`E`)
- pénztári átvétel (`U`)
- pénztári átadás (`F`)

### 10.2. Pénztárforgalmi lista
Összesíti:
- átadott és átvett tételeket
- pénztáranként
- devizanemenként
- időszakra

### 10.3. Egyéb listák
Azonosított listák:
- forgalomstatisztika
- havi tabló
- pillanatnyi készlet
- dekád lista
- kezdődíj lista
- napi forgalom
- régi zárás újranyomtatás

## 11. Ügyfél, compliance, engedélyezés

### 11.1. Ügyfélkezelés
A források szerint az ügyféladatok külön adatbázisokban és modulokban élnek:
- `UGYFEL`
- `KISUGYFEL`
- `SENDOKMANY`
- `GETWUGYF`

Távoli DB-k:
- `ugyfelYY.fdb`
- `kisugyfel.fdb`

### 11.2. Terrorlista / compliance
Külön modul:
- `TERROR`

Távoli adatbázis:
- `TERRORISTS.FDB`

Ez alapján a rendszer compliance oldalon legalább tiltólista-ellenőrzést támogat.

### 11.3. Engedélyezési logika
Külön nyomok:
- `GETENGED`
- supervisor jelszó
- kedvezményes árfolyam
- engedélyező mezők a bizonylat pipeline-ban

Ez arra utal, hogy bizonyos műveletek magasabb jogosultsághoz kötöttek.

## 12. `TRADE` rendszer részletes képe

### 12.1. Funkcionális fókusz
A `TRADE` rendszer főleg nem klasszikus valutás, hanem kiegészítő kereskedelmi szolgáltatásokat visz:
- top-up
- matrica
- számla
- tanúsítvány
- logolvasás
- elektronikus kereskedési interfész

### 12.2. Indulási folyamat
1. internetellenőrzés
2. alapadatok beolvasása
3. havi TRADE tábla biztosítása
4. logfájl előkészítése
5. matrica összesítő regenerálása
6. tanúsítvány-ellenőrzés
7. pénztáros belépés
8. cikktörzs betöltése

### 12.3. Szerveres integrációi
- HTTP hívás kupon/topup oldalra
- FTP kapcsolat tanúsítvány letöltéshez
- Java helper `Coupon.exe`
- remote Firebird `MATRICA.FDB`

### 12.4. Könyvelési logika
Könyvelés havi táblákba történik:
- `TRADyyMM`

Mentett mezők például:
- típus
- bizonylatszám
- kategória
- tranzakció
- ügyféladatok
- fizetendő
- pénztáros neve
- dátum, idő
- szolgáltatás / szolgáltató

## 13. Kamera és Java alapú alrendszerek

## 13.1. `camera2\camera`
Ez a modernebb, Maven alapú kamera és office platform.

Modulok:
- `camera-updater`
- `camera-cmn`
- `camera-player`
- `camera-config`
- `camera-office`
- `camera-center`
- `camera-film-restorer`
- `camera-film-inspecter`

### 13.2. Kamera architektúra
Ez már nem a régi Delphi kasszaprogram része, hanem külön ökoszisztéma:
- kamera konfiguráció
- office kliens
- center
- film visszaállítás
- film inspecter
- player export

### 13.3. Adatbázis és config
Példa:
- `camera-config` dev config MySQL-t használ
- `jdbc:mysql://localhost:3306/camera`
- felhasználó: `exclusiveuser`

### 13.4. Export működés
A `FilmConverterMainThread` alapján:
- filmek exportálása kijelölt könyvtárba
- párhuzamos konvertálás
- opcionális lejátszó export
- opcionális tranzakciós adatexport
- `ExclusivePlayer.exe` másolása exportcsomagba

Ez arra utal, hogy a kameraanyag nem csak visszanézésre, hanem átadható exportcsomagokban is használatos.

### 13.5. Távoli üzenetküldés
A `MessageService` alapján:
- `http://excupdate.ddns.net:55658/api/sendMail/...`
- office azonosítóval és üzenettel küld jelentést

## 13.6. `camera3\old`
Ez a régebbi Java világ, különálló alkalmazásokkal.

Főbb típusok:
- desktop client
- management webapp
- camera local/remote
- Western Union inspecter server
- NAV / MNB / egyéb provider szerverek

### 13.7. Régi desktop kliens menü
A JavaFX `MainMenu.fxml` alapján egy modernebb kliensoldali menü is létezett.

Azonosított menüpontok:
- Eladás - Vétel
- Átadás - Átvétel
- Készlet
- Árfolyam
- Sztornó
- Forgalom
- Cimletezés
- Napzárás
- Nyomtatványok
- Foglaló

Ez jól mutatja, hogy a modernizációs irány már korábban is elkezdte újraszervezni a legacy funkciókat.

### 13.8. WU inspecter server
A `LocalDatabase.java` alapján:
- Firebird JDBC-vel dolgozik
- boltazonosítóhoz kötött lokális `V{shop}.FDB` állományt nyit
- `WUNIyyMM` táblákból olvas
- dátumintervallumra gyűjt tranzakciókat
- kiszűri a stornozott elemeket

## 14. Tematikus DLL-leltár
Az `Anti\VALUTA\DLL` alatt 119 `MAKEDLL` Delphi projekt található. Ezeket funkció szerint lehet csoportosítani.

### 14.1. Tranzakciók és árfolyam
- `VASARLAS`
- `ELADAS`
- `ARFVALT`
- `BIGARFVALT`
- `KISARFVALT`
- `SETRATE`
- `GETARF`
- `GETARF\UJDLL`
- `FORGOSSZ`
- `MAIFORG`
- `XTRANZ`
- `STORNO`

### 14.2. Pénztár és címlet
- `PTARTMK`
- `PTARKESZ`
- `PILLALL`
- `PILLKESZ`
- `CIMLET`
- `KCIMLET`
- `KISCIMLET`
- `CIMLCTRL`
- `CIMLMENU`
- `CIMLNYOM`
- `KELLCIM`
- `KESZEDIT`
- `KESZUP`

### 14.3. Zárás és periódus
- `NAPIKEZD`
- `NAPZAR`
- `HAVIZAR`
- `NAVZARO`
- `NAPIFORG`
- `NAPIJEL`
- `NAPKONYV`
- `IDOSZAK`
- `REGIZARO`
- `REGEN`

### 14.4. Bizonylat, lista, log
- `BLOKNYOM`
- `BIZODISP`
- `LISTAK`
- `LOGIRO`
- `LOGDISP`
- `NZNYOMT`
- `CHECKLST`

### 14.5. Ügyfél, compliance
- `UGYFEL`
- `KISUGYFEL`
- `UGYFELTMK`
- `GETWUGYF`
- `GETWCEG`
- `SENDOKMANY`
- `TERROR`
- `CONFIDEN`
- `GETENGED`

### 14.6. Admin és felügyelet
- `PROSBE`
- `PROSKI`
- `PROSTMK`
- `SUPERTSK`
- `SUPER`
- `OTHERTSK`
- `GEPSETUP`
- `VERZFRIS`
- `MENTES`
- `QUITFORM`

### 14.7. Integrációk
- `WUNION`
- `OTP`
- `OTPLOG`
- `TERMINAL`
- `TESCO`
- `METRO`
- `QRGENER`
- `QRDEPUTY`
- `COPY2FTP`

### 14.8. Foglaló és egyéb üzleti segédek
- `FOGLALO`
- `FOGLREND`
- `MATREGEN`
- `MATPTAR`
- `GETSTATUS`
- `GETISO`
- `GETFIZE`
- `GETNYUGT`
- `GETPLOMB`
- `KEZDKEDV`
- `KEZDIJ`
- `KEZDEKAD`

### 14.9. FNYUJSAG variánsok
Több telephely-specifikus vagy hardver-specifikus build:
- `FNYUJSAG\MAKEDLL`
- `FNYUJSAG\ALAP`
- `FNYUJSAG\BAJCSY`
- `FNYUJSAG\BCSABA`
- `FNYUJSAG\DIANA`
- `FNYUJSAG\DUPLACOM`
- `FNYUJSAG\DUPOTHER`
- `FNYUJSAG\FERENCES`
- `FNYUJSAG\IRGALMAS`
- `FNYUJSAG\NOSPEED`
- `FNYUJSAG\OROS`
- `FNYUJSAG\SZOBOSZLO`
- `FNYUJSAG\UJTIPUS`
- `FNYUJSAG\dombovar`
- `FNYUJSAG\spec8085`

## 15. A rendszer üzleti lényege összefoglalva
Az `Anti` alapján a teljes legacy üzleti modell a következő:

### 15.1. Napi pénztári működés
- pénztáros belép
- rendszer ellenőrzi a nap állapotát
- szükség esetén napnyitás történik
- ügyfél oldali valuta műveletek futnak
- a kassza folyamatosan bizonylatol
- a készlet és pénztárállás követve van
- időszakos beküldés/szinkron is előfordulhat
- nap végén zárás, címletezés, terminál, beküldés

### 15.2. Treasury/értéktári lánc
- pénztár ellátása
- értéktár-pénztár átadás
- banki beszállítás/kiszállítás
- körlevelek és rendelési információk
- készleteltérések kezelése

### 15.3. Dokumentumközpontú működés
A rendszer nem csak adatot tárol, hanem minden lényeges pénzmozgást papír/nyomtatvány oldalon is leképez:
- normál bizonylat
- storno
- lista
- átadólap
- címletlista
- számla
- nyugta
- WU dokumentum

### 15.4. Hibrid üzem
A rendszer egyszerre:
- lokális desktop alkalmazás
- távoli adatbázis-hub kliens
- exportoló/nyomtató rendszer
- részben szerverekhez kapcsolódó hálózatos megoldás
- külön kamerás és központi Java alrendszerekkel együttműködő ökoszisztéma

## 16. Kritikus technikai megfigyelések

### 16.1. Erősen implicit architektúra
Az üzleti logika nagyon nagy része:
- DLL-ekbe szórva
- `VTEMP` és hasonló átmeneti táblákra építve
- fájlrendszeres side effectekkel működik

### 16.2. Erős függés a lokális Windows környezettől
Keményen kódolt útvonalak:
- `c:\valuta\...`
- `LPT1`
- `c:\receptor\database\...`

### 16.3. Külső integrációk szétszórtak
Példák:
- Firebird remote DB
- HTTP topup/kupon
- FTP
- Java helper exe
- külön Java központi rendszerek

### 16.4. Üzleti szempontból mégis nagyon kiforrott
A források alapján a rendszer tudása mély:
- napi státuszgép
- pénztár-értéktár-bank lánc
- árfolyam és engedélyezés
- bizonylati fegyelem
- storno ellenművelet
- listázás és újranyomtatás
- kiegészítő kereskedelmi szolgáltatások
- kamera és export ökoszisztéma

## 17. Rövid végkövetkeztetés
Az `Anti` könyvtár egy teljes értékű, többgenerációs valutaváltó vállalati rendszer forrásvilága. A klasszikus mag a Delphi `IBVALTO` shellből és a mögötte álló sok tucat DLL üzleti modulból áll. Ezt kíséri a `TRADE` mellékrendszer, valamint egy külön Java alapú kamera- és központi management vonal.

Üzletileg a rendszer fő pillérei:
- valuta vétel/eladás/konverzió
- pénztárak közötti átadás-átvétel
- címletezés és készletkezelés
- napnyitás, napzárás, havi zárás
- bizonylatolás, storno, újranyomtatás
- értéktári és banki folyamatok
- Western Union és egyéb integrációk
- mentés, export, riport és központi kontroll

Technikailag a legfontosabb minták:
- Delphi shell + DLL plugin architektúra
- Firebird/InterBase lokális és távoli adatbázisok
- `VTEMP` alapú modulkommunikáció
- textfájl alapú nyomtatás
- Java alapú kamera és management alrendszerek

Ez a dokumentum használható:
- funkciótérképnek
- legacy audit alapnak
- modernizációs inputnak
- új AI ügynök vagy fejlesztő handoff dokumentumnak
