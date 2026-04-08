# Eszter — Legacy Delphi SZERVER elemzés

Dátum: 2026-04-07
Forrás: `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\`

## 1. Vezetői összefoglaló

A vizsgált legacy rendszer nem egyetlen „szerver”, hanem egy nagy, fájlrendszerre és Firebird/InterBase adatbázisokra támaszkodó, erősen moduláris, de fizikailag széttagolt Delphi 7 ökoszisztéma. A `SZERVER`, `VALUTA` és `ERTEKTAR` ágak együtt egy teljes üzleti platformot alkotnak: pénztári kliens, központi feldolgozó, receptori/gyűjtő folyamatok, értéktári modulok, számos DLL-es részfunkció és adatbázis-létrehozó segédprogram.

A legfontosabb megállapítások:

- A fa **8368 fájlt** és kb. **939 MB** adatot tartalmaz, tehát nem csak forráskód, hanem sok build-artifact, bináris, DLL, EXE, DFM és FDB adatbázis is benne van.
- A „forrás-jellegű” állományok (`.pas`, `.dpr`, `.dfm`, `.cfg`, stb.) önmagukban is kb. **3533 fájl / 137 MB** méretűek.
- A rendszer **erősen Firebird/InterBase-központú**: 665 Pascal fájlban látható IB-komponens vagy InterBase-használat.
- A teljes architektúra **vastag klienses, form-alapú, timer/event-driven**; a „szerver” is VCL alkalmazásként indul, nem Windows service-ként vagy headless daemonként.
- A kódbázis **DLL-orientált**: a fő alkalmazások üzleti funkciók nagy részét külső DLL-ekbe szervezik ki, tipikusan `c:\valuta\bin\*.dll` vagy `c:\receptor\*.dll` hívásokkal.
- A rendszer **hard-coded környezetfüggő**: abszolút `C:\...` utak, lokális könyvtárszerkezet, nyomtatóport (`LPT1`), fájljelzők, marker file-ok, lokális adatbázisok és több helyen hardcoded DB credential található.
- A migrációhoz a legjobb megközelítés nem a fájlonkénti portolás, hanem a **domain-ek és adatáramlások leválasztása**: pénztári runtime, receptor/feldolgozó, értéktári funkciók, ügyfél- és iroda-admin, valamint külső integrációk (OTP, Western Union, e-trade, e-mail, FTP).

## 2. Mennyiségi és szerkezeti kép

### 2.1. Teljes fa

A teljes `_extracted` fa szkennelt állapota:

- összes fájl: **8368**
- összméret: **939,905,802 byte**
- felső szintű megoszlás:
  - `SZERVER`: **3933 fájl**
  - `VALUTA`: **3184 fájl**
  - `ERTEKTAR`: **1233 fájl**
  - `firebird`: **17 fájl**

### 2.2. Főbb kiterjesztések

- `.pas`: **1156**
- `.dfm`: **1153**
- `.dcu`: **1147**
- `.ddp`: **1097**
- `.dpr`: **668**
- `.cfg`: **522**
- `.dof`: **521**
- `.exe`: **425**
- `.dll`: **291**
- `.~pas`: **129**
- `.~dfm`: **129**

Ez azt mutatja, hogy a fa valójában **forrás + IDE melléktermék + fordított komponensek + futtatható csomagok** keveréke, tehát közvetlen modernizáció előtt kötelező lesz a **source/artifact szétválasztás**.

### 2.3. Forrás-jellegű állományok

A forrásnak tekinthető állományok (`.pas`, `.dpr`, `.dfm`, `.cfg`, `.txt`, stb.) becsült volumene:

- **3533 fájl**
- **137,233,194 byte**

Felső szinten:

- `SZERVER`: **1533** forrás-jellegű fájl
- `VALUTA`: **1421**
- `ERTEKTAR`: **579**

### 2.4. Szerkezeti minták

A repository-ban nagyon erős a fejlesztési/kiadási duplikáció:

- `debug` könyvtárak: **250**
- `makedll` könyvtárak: **247**
- `fejleszt` könyvtárak: **267**
- `ujdll` könyvtárak: **118**
- `save` könyvtárak: **12**

Ez tipikus Delphi 7-es „minden modul külön projekt + debug/makedll pár” szerkezet, ami azt jelzi, hogy a rendszer **funkciók százaira darabolt build-univerzum**, nem pedig egy tiszta komponensstruktúra.

## 3. Magas szintű architektúra

## 3.1. A rendszer valós képe

A név ellenére ez nem klasszikus client/server webes szerverarchitektúra. A kód alapján inkább ez a topológia rajzolódik ki:

1. **Pénztári / front runtime** (`VALUTA`, részben `SZERVER`)  
   Vastag kliens, helyi DB-kkel, DLL-es funkciókkal, üzleti tranzakciókkal.

2. **Központi irányító / admin / supervisory alkalmazások** (`SZERVER\fejleszt\server`, admin és riport modulok)  
   Sok form, menü, felügyeleti és feldolgozó funkció.

3. **Receptor / adatbegyűjtő / mail-alapú csomagfeldolgozó** (`SZERVER\fejleszt\recptor`)  
   Marker fájlokat, bejövő csomagokat, archívumot, daybookokat és napi zárási adatokat kezel.

4. **Értéktár modulok** (`ERTEKTAR`)  
   Készlet-, átadás-átvétel-, címlet-, nyomtatási és értéktári folyamatok.

5. **Segéd- és specializált DLL-univerzum**  
   A fő programok tömegesen hívnak külső DLL-eket, amelyek a valódi üzleti funkciók jelentős részét hordozzák.

## 3.2. Vastag kliens, nem headless szerver

A `SZERVER\fejleszt\server\server.dpr` alapján a „server” alkalmazás VCL GUI app:

- `Application.Initialize;`
- több tucat `Application.CreateForm(...)`
- `Application.Run;`

Ez alapján a központi komponens **nem service-first** és nem háttérfolyamat, hanem **operátori felületre épülő desktop alkalmazás**.

## 3.3. DLL-vezérelt üzleti motor

A `SZERVER\fejleszt\server\unit1.pas` alapján a fő form rengeteg külső DLL-függvényt deklarál, pl.:

- `afatab.dll`
- `getarf.dll`
- `arfreg.dll`
- `atadvet.dll`
- `atadolap.dll`
- `bizodisp.dll`
- `napzar.dll`
- `otp.dll`
- `wunion.dll`
- `verzfris.dll`

A fő alkalmazás inkább **orchestrator shell**, nem pedig monolit üzleti motor. A logika jelentős része DLL-ekbe van kiszervezve.

## 4. Fő domain-ek és felelősségek

## 4.1. `SZERVER`

A `SZERVER` ág a központi adminisztratív és feldolgozó mag.

Jellemzők:

- sok száz projekt és alprojekt
- `server`, `recptor`, `arfolyam`, `booking`, `ugyfelcontrol`, `korlevel`, `mentes`, `statiszt`, `western`, stb.
- újabb DLL-változatok külön `ujdll` ágban

A `server` főprojektből látható, hogy ide tartoznak többek között:

- MNB listák
- hibakijelzés
- címletezés
- hiányzó zárások
- felhasználókezelés
- kézi adatpótlás
- iroda törzs (`Unit16`)
- árfolyam törzs
- forgalom/készlet display
- bankforgalom
- adatlegyűjtés
- jutalékszámítás
- átlagárfolyam
- WU/WAFA kontroll

Ez alapján a `SZERVER` a **központi üzletirányítási és adatkonzolidációs réteg**.

## 4.2. `VALUTA`

A `VALUTA\IBVALTO\UNIT1.PAS` alapján ez egy erős operátori pénztári runtime:

- Firebird/IB komponensek
- Indy HTTP/TCP, WinInet, FTP, registry és fájlrendszer-használat
- OTP terminál integráció
- trade/e-kereskedelem támogatás
- verziófrissítés, futófény, körlevél, készlet, supervisor funkciók

A kód operatív jellemzői:

- napi nyitás/zárás kontroll
- hardver/szerver állapotellenőrzés
- pénztárosi beléptetés
- lokális state fájlok (`wait.txt`, `mess.txt`, `phone.txt`)
- több lokális FDB (`trade.fdb`, `ujnaplo.fdb`, stb.)

Ez a réteg a tényleges **branch / office runtime**.

## 4.3. `ERTEKTAR`

Az `ERTEKTAR\etdll\atadvet\debug\unit2.pas` alapján ez a domain értéktári tranzakciókat kezel:

- átadás / átvétel
- pénz- és címletkezelés
- valutánkénti címletstruktúrák
- blokkfej/blokktétel írás
- nyomtatás és fájlkimenet
- készletkontroll
- FTP-s vagy távoli feltöltési folyamatok

Ez a rész kifejezetten **cash / denomination / custody** logikát hordoz, tehát migrációs szempontból külön bounded contextként kezelendő.

## 4.4. `recptor` mint adatbegyűjtő back office

A `SZERVER\fejleszt\recptor\unit1.pas` alapján a receptor:

- `C:\RECEPTOR\MAIL\IN\` mappában marker (`*.m`) file-okat figyel
- azok alapján csomagfájlokat keres
- csomagkiterjesztésből dátumot dekódol
- `unpackerrutin` DLL-lel feldolgoz
- daybookot frissít
- archíválja a csomagot
- napimentést, napi forgalomküldést, jelenléti íveket és scan-kópiát indít

Ez gyakorlatilag **file-based integration hub / overnight processor**, nem modern üzenetsor vagy API alapú feldolgozó.

## 5. Technikai mintázatok

## 5.1. Firebird/InterBase dominancia

A mintaszkennelés alapján:

- InterBase/IBX használat: **665 Pascal fájl**
- SQL-mintát tartalmaz: **633 Pascal fájl**

Gyakori komponensek:

- `TIBDatabase`
- `TIBQuery`
- `TIBTable`
- `TIBTransaction`

A kód tipikusan ezt a mintát ismétli:

- kapcsolat megnyitása
- tranzakció indítása
- dinamikus SQL string összerakása
- `ExecSQL` / `Open`
- explicit commit
- kapcsolat bezárása

Ez azt jelenti, hogy a domain-logika nagyon sok helyen **közvetlenül UI eventekből adatbázist ír/olvas**, ORM vagy elkülönített repository réteg nélkül.

## 5.2. UI-vezérelt folyamatok

A kódbázis erősen VCL és form-központú:

- nagy mennyiségű `.dfm`
- fő űrlapokban üzleti logika
- timer-ekkel vezérelt ciklusok (`InditoTimer`, `MenuInditoTimer`, `IdoTimer`, `Figyelo`, `BigMenet`)
- modal ablakok és operátori interakciók

A modernizációt nehezíti, hogy a business flow jelentős része **eseménykezelőkbe van beágyazva**, nem tiszta szolgáltatási rétegben él.

## 5.3. Fájl-alapú állapotkezelés

Sok komponens fájlokkal kommunikál:

- state flag-ek (`wait.txt`, `mess.txt`, `notfree`)
- marker file-ok (`*.m`)
- print/list output (`aktlst.txt`, címletlista)
- telefon- és egyéb konfigurációs textfile-ok
- archívált mail/csomag file-ok

Ez arra utal, hogy az architektúra részben **file-based IPC / outbox / flag signalling** mintákból épült fel.

## 5.4. Külső integrációk

A minták és a konkrét unitok alapján jelen vannak:

- FTP kapcsolat (`TNMFTP`, `FTPtry.Connect`)
- Indy HTTP/TCP komponensek
- WinInet internetellenőrzés
- OTP terminál integráció
- Western Union és WAFA funkciók
- e-mail küldés/értesítés
- Excel/COM/OLE automatizáció több projektben

A mintaelemzésben **79 Pascal fájl** mutat COM/OLE használatot, ami tipikusan Excel-export / Office automatizációs örökségre utal.

## 5.5. DLL-es plugin/részrendszer modell

A mintaszkennelés szerint **280 Pascal fájlban** látható DLL vagy dinamikus library használat. A projektstruktúra is ezt támogatja:

- nagyon sok `debug` / `makedll` pár
- külön `ujdll` ág
- több száz `.dpr`, amelyek valójában kisebb modulok vagy DLL projektek

Ez a rendszer modern szemmel nézve egy **sajátos plugin-monolit**, ahol a komponenshatárok technikailag DLL-ek, de a szerződések nincsenek explicit API-szinten formalizálva.

## 6. Minőségi és kockázati megállapítások

## 6.1. Hard-coded környezet és elérési utak

A szkennelés szerint **1165 fájlban** található abszolút `C:\...` elérési út. Példák:

- `c:\valuta\...`
- `c:\receptor\...`
- `c:\ertektar\...`
- `LPT1`

Ez kritikus technikai adósság, mert:

- géphez kötött a futás
- nehéz izolálni, konténerizálni vagy automatán tesztelni
- minden modern deployment modelllel ütközik

## 6.2. Hardcoded credential / DB secret

A szkennelés **18 helyen** talált közvetlen `SYSDBA ... PASSWORD` mintát. Bizonyított példa:

- `SZERVER\fejleszt\recptor\unit1.pas`: `Params.Add('USER ''SYSDBA''PASSWORD ''dek@nySo''');`
- `SZERVER\fejleszt\server\unit16.pas`: ugyanilyen mintával új FDB létrehozása

Ez egyértelmű security debt:

- hardcoded Firebird admin credential
- forráskódban tárolva
- több projekten át újrahasznosítva

## 6.3. SQL-string összefűzés és gyenge szeparáció

A rendszerben széles körben dinamikusan összeépített SQL-ek vannak, pl.:

- `UPDATE HARDWARE SET ...`
- `INSERT INTO VTEMP ...`
- `DELETE FROM VTEMP`
- `CREATE TABLE ...`

A tipikus minta nem paraméterezett query, hanem string-összefűzés. Ez nemcsak modern szemmel kockázatos, hanem a domain-logikát és az adatkezelést is szorosan összeragasztja.

## 6.4. Forrásduplikáció és build-zaj

A kódnév-analízis alapján:

- `Unit2`: **529** példány
- `Unit1`: **419** példány

Ez önmagában is jelzi, hogy a kódbázisban az egységnevek tömegesen generikusak, így:

- nehéz navigálni
- nehéz automatikus átnevezést vagy statikus elemzést csinálni
- importálásnál / portolásnál magas a félreazonosítási kockázat

Ehhez társul a `debug`, `makedll`, `save`, `old`, `orecept`, `unpacked` és hasonló ágakból adódó verziótöredezettség.

## 6.5. GUI + state + DB + I/O egy helyen

A reprezentatív unitok alapján gyakori, hogy egyetlen form osztály egyszerre kezeli:

- UI rajzolást
- user inputot
- adatbázis tranzakciókat
- fájlírást/olvasást
- DLL-hívásokat
- időzítést
- hálózati állapotot

Ez erősen anti-layered felépítés, ami modernizációnál **kötelező bontást** igényel.

## 7. Mit árul el a domainről?

A rendszer fő üzleti fogalmai jól azonosíthatók:

- pénztár / iroda / üzlet (`PENZTAR`, `IRODAK`, `UZLET`)
- napi nyitás-zárás (`MEGNYITOTTNAP`, `LEZARTNAP`, `napzárás`)
- készlet és címletek
- blokkfej / blokktétel
- pénztárosi beléptetés
- árfolyamkezelés
- ügyfelek és jogi személyek
- OTP / Western Union / Tesco / Metro és egyéb partnerfolyamatok
- receptor / bejövő csomag / napi zárási adatcsere

Ez erős jel arra, hogy a modern rendszer bounded contextjei már most kirajzolhatók.

## 8. Javasolt modernizációs felosztás

A migrációt nem technikai rétegen, hanem üzleti kontextusok mentén érdemes szervezni.

### 8.1. 1. hullám: adat- és domain-feltárás

Elsőként külön ki kell emelni és dokumentálni:

- központi törzsadatok: `HARDWARE`, `PENZTAR`, `IRODAK`, `RENDSZER`
- napi runtime state mezők
- tranzakciós táblák: `BLOKKFEJ`, `BT*`, `BF*`, `CIMT*`, `NARF*`, `TRAD*`, stb.
- receptor/daybook táblák
- ügyfél és jogi személy táblák

### 8.2. 2. hullám: runtime bontás

Külön szolgáltatásként/alkalmazásként kezelendő:

1. **Pénztári runtime**
2. **Központi admin / supervisory**
3. **Receptor / csomagfeldolgozó**
4. **Értéktári folyamatok**
5. **Integrációs adapterek** (OTP, WU, FTP, e-mail, Office export)

### 8.3. 3. hullám: technikai adósság-vágás

Prioritási sorrendben:

- hardcoded utak kiváltása
- credential kiszervezése
- SQL-réteg paraméterezése / absztrakciója
- DLL-szerződések dokumentálása
- source vs artifact tisztítás
- duplikált projektágak konszolidálása

## 9. Prioritásos kockázatok a modernizációhoz

### Kritikus

1. **Hardcoded DB admin credential a forrásban**
2. **Abszolút lokális útvonalak mindenhol**
3. **Business logic erősen UI eventekbe ágyazva**
4. **DLL-függőség explicit interfészleírás nélkül**

### Magas

5. **File-based állapot- és integrációkezelés**
6. **Projektverziók és debug/makedll ágak töredezettsége**
7. **Nem tiszta „szerver”, hanem desktop-orchestrator modell**

### Közepes

8. **Generikus unitnevek miatt nehéz automatikus kódtérkép**
9. **COM/Office és printer függőségek**
10. **Lokális DB-k és havi/dátum-alapú táblaelnevezések**

## 10. Ajánlott következő lépések

1. **Source inventory normalizálása**  
   Artifactok (`.dcu`, `.exe`, `.dll`, `.fdb`, backupok, `.~*`) leválasztása külön rétegbe.

2. **Adatmodell-katalógus generálása**  
   Tábla- és mezőszintű feltárás a `CREATE TABLE` mintákból és élő FDB-kből.

3. **DLL contract inventory készítése**  
   Mely DLL, melyik fő appból, milyen paraméterrel, milyen side effecttel hívódik.

4. **Bounded context map készítése**  
   `Valuta runtime` / `Receptor` / `Ertéktár` / `Admin-SZERVER` / `Integrációk` bontásban.

5. **Kiemelt flow-k újramodellezése**  
   - napi nyitás/zárás
   - pénztáros beléptetés
   - receptor csomagfeldolgozás
   - értéktári átadás/átvétel
   - árfolyamfrissítés

## 11. Bizonyítékok

### Mennyiségi szkennelés

- teljes fa statisztika: saját szkennelés a teljes `_extracted` könyvtáron
  - 8368 fájl / 939 MB
  - 1156 `.pas`, 1153 `.dfm`, 668 `.dpr`
- forrás-jellegű állományok: 3533 fájl / 137 MB
- struktúra minták: `debug` 250, `makedll` 247, `fejleszt` 267, `ujdll` 118

### Konkrét fájlbizonyítékok

- `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\SZERVER\fejleszt\server\server.dpr`
  - VCL GUI indulás, tömeges `Application.CreateForm`, nem headless service
- `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\VALUTA\IBVALTO\UNIT1.PAS`
  - pénztári runtime, IBX + hálózat + OTP + DLL orchestration + napi nyitás/zárás logika
- `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\SZERVER\fejleszt\recptor\unit1.pas`
  - receptor, marker file figyelés, csomagfeldolgozás, archíválás, daybook, e-mail és scan workflow
- `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\SZERVER\fejleszt\server\unit16.pas`
  - iroda-admin, új FDB-k létrehozása, hardcoded `SYSDBA` jelszó, sémagenerálás
- `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\ERTEKTAR\etdll\atadvet\debug\unit2.pas`
  - értéktári átadás/átvétel, készlet- és címletlogika, blokkírás, pénzkezelési domain

## 12. Végső értékelés

Ez a legacy kódbázis üzletileg értékes, mert a teljes valutaváltós működés szervezőelvei jól felismerhetők benne. Ugyanakkor technikailag egy erősen összenőtt, fájl- és DLL-orientált Delphi 7 ökoszisztéma, amelynek modernizációja csak akkor lesz kontrollálható, ha előbb:

- kitisztul a source/artifact határ,
- explicitté válnak a domain-határok,
- dokumentáljuk az adatmodellt,
- és leválasztjuk a GUI-ba ragadt üzleti logikát.

Röviden: **a rendszer migrálható, de nem komponensenkénti „code translation” módszerrel; domain-központú újratervezés kell, a legacy kódot pedig referenciaként és viselkedési specifikációként kell használni.**
