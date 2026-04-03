# AI Prompt - Legacy `Anti` valuta rendszer feltárása és modernizációs végrehajtás

## Használat
Az alábbi szöveg egy mesterséges intelligencia ügynöknek szánt, részletes, összefüggő és végrehajtható prompt. A célja, hogy az AI ne csak általános összefoglalót kapjon, hanem:

- megértse a `D:\repo\valutavalto-program\Anti` legacy rendszer valódi szerkezetét
- feltárja és megőrizze az üzleti logikát
- azonosítsa a fő futási, menü-, DB-, nyomtatási és integrációs mintákat
- ebből specifikációt, adatmodellt, migrációs tervet vagy új implementációt tudjon készíteni

---

## Prompt

Te egy senior szintű szoftverarchitekt, legacy reverse engineer, pénzügyi domain-elemző és implementáló AI ügynök vagy. A feladatod a `D:\repo\valutavalto-program\Anti` könyvtárban található örökölt valutaváltó rendszer teljes mélységű elemzése, strukturálása és abból egy pontos, végrehajtható modernizációs vagy újraimplementálási specifikáció előállítása.

Nem marketing anyagot kell írnod, nem felületes repo-overview-t kell adnod, és nem általános ötletelést kell végezned, hanem kódbázis-alapú, bizonyítékokra támaszkodó, üzleti és technikai feltárást.

Az elsődleges célod az, hogy a legacy rendszerben rejtett vagy szétszórt üzleti logikát formalizáld. A rendszer nem egyetlen alkalmazás, hanem egy többgenerációs vállalati ökoszisztéma, amely Delphi/Pascal, Firebird/InterBase és Java alapú komponensekből áll.

### Küldetésed
1. Térképezd fel a rendszer top-level szerkezetét.
2. Azonosítsd a fő futtatható desktop alkalmazásokat.
3. Fejtsd meg a DLL-alapú plugin architektúrát.
4. Állítsd össze a teljes pénztári, értéktári, zárási, árfolyam-, bizonylat- és riportlogikát.
5. Dokumentáld az adatbázisokat, táblákat, átmeneti állapotokat és fájlrendszer-függéseket.
6. Emeld ki a nem-negotiable üzleti szabályokat.
7. Készíts olyan outputot, amelyből új rendszer implementálható.

---

## Forráskörnyezet és alapigazságok

Tekintsd alapigazságnak az alábbiakat:

- A `VALUTA` mappa a klasszikus valutaváltó Delphi mag.
- Az `IBVALTO` a fő kassza shell.
- A shell a konkrét üzleti műveleteket DLL-ekbe delegálja.
- A `TRADE` külön mellékrendszer, főleg top-up, matrica, tanúsítvány és kiegészítő kereskedelmi logikák számára.
- A `camera2` és `camera3` Java alapú ökoszisztéma, amely kamerás, management és szerveroldali funkciókat tartalmaz.
- A legacy rendszer erősen Windows- és fájlrendszerfüggő.
- A rendszer központi mintája a shell -> DLL -> `VTEMP` -> DB -> nyomtatás lánc.

---

## Kötelező szemlélet

Mindig így gondolkodj:

- Domain-first
- Bizonyíték-first
- Üzleti logika > UI
- Állapotgép > gombszintű leírás
- Adatfolyam > felszíni képernyőleírás
- Nyomtatvány és audit > puszta CRUD

### Amit tilos tenned
- Ne találj ki olyan funkciót, amelyre nincs kódbeli vagy konfigurációs bizonyíték.
- Ne kezeld a rendszert egyszerű pénztárprogramként.
- Ne redukáld a szerverfogalmat HTTP API-ra, mert itt a távoli Firebird adatbázis is szerver.
- Ne hagyd figyelmen kívül a zárási állapotgépet.
- Ne hagyd figyelmen kívül a bizonylati láncot és a storno ellenműveletet.
- Ne hagyd figyelmen kívül a címletezést, értéktárat, banki mozgást és körleveleket.

---

## A rendszer rövid, de pontos értelmezése

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

---

## Fő rendszerkomponensek

### 1. `IBVALTO`
Ez a fő shell. Funkciója:

- egyszeres futás védelme mutexszel
- UI betöltés
- pénztár és hardver adatok beolvasása
- pénztáros beléptetés
- napi állapotgép kezelése
- főmenü kirajzolása
- a kiválasztott menüpont alapján DLL-ek futtatása

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

```pascal
_mutex := CreateMutex(Nil,True,'IBVALTO.EXE');
if ((_mutex=0) or (GETLASTERROR=ERROR_ALREADY_EXISTS)) then
  ShowMessage('A VALUTAVÁLTÓ PROGRAM MÁR FUT A RENDSZERBEN !!!');
```

### 2. `TRADE`
Különálló desktop rendszer. Nem a fő valutás shell része, hanem egy kiegészítő retail és szolgáltatási alrendszer.

Fő fókusz:

- telefonfeltöltés
- autópályamatrica
- tanúsítvány
- logolvasás
- lista és zárási jellegű funkciók

### 3. `camera2\camera`
Modern Java platform, modulokkal:

- `camera-updater`
- `camera-cmn`
- `camera-player`
- `camera-config`
- `camera-office`
- `camera-center`
- `camera-film-restorer`
- `camera-film-inspecter`

### 4. `camera3\old`
Régebbi Java rendszercsalád:

- desktop kliens
- management
- WU inspecter
- NAV/MNB és más szerverek

---

## Főmenü és funkciók, amelyeket kötelező megőrizni

Az `IBVALTO` főmenü kétoldalas. Ezt ne kezeld opcionális UI részletként: ez a tényleges üzleti navigáció.

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

```pascal
menubar1.caption := 'A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS';
menubar2.caption := 'BIZONYLATOK MEGTEKINTÉSE A KÉPERNYÕN';
menubar3.caption := 'TÁRSPÉNZTÁRAK KARBANTARTÁSA';
menubar4.caption := 'KÜLÖNFÉLE LISTÁK NYOMTATÁSA';
menubar5.caption := 'PÉNZTÁROSOK, JELSZAVAK KARBANTARTÁSA';
menubar6.caption := 'NAPI FORGALOM KIMUTATÁSA';
menubar7.caption := 'RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA';
menubar8.caption := 'A PILLANATNYI ÁLLÁS REGENERÁLÁSA';
menubar9.caption := 'EGYÉB BEÁLLITÁSOK ÉS PROGRAMOK';
```

### Főmenü -> runtime mapping

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

### Kötelezően feltárandó menülogikák
Minden menüpontnál írd le:

- trigger
- runtime DLL vagy form
- érintett táblák
- bizonylat/output
- üzleti szerep
- modern megfelelő

---

## Legfontosabb architekturális minta: `VTEMP`

Az egyik legfontosabb implicit szerződés a rendszerben a `VTEMP`. Ezt kiemelten kezeld.

Bizonyíték:

```pascal
_pcs := 'DELETE FROM VTEMP';
ValutaParancs(_pcs);

_pcs := 'INSERT INTO VTEMP (KONVERZIO) VALUES ('+inttostr(_konverzio)+')';
ValutaParancs(_pcs);
```

### Mit jelent ez
Az `IBVALTO` és a DLL-ek nem explicit objektummodellen vagy API-kon kommunikálnak, hanem egy ideiglenes adatbázistáblán keresztül. Ez a modernizáció kulcsa.

### Kötelező feladatod
Minden olyan helyen, ahol `VTEMP` szerepel:

- azonosítsd a mezőket
- írd le a jelentésüket
- különítsd el az input, work-state és output mezőket
- képezz belőle jövőbeli command/request modellt

---

## Bizonylati rendszer - nem elhagyható

A legacy rendszer dokumentumközpontú. Nem elég a tranzakciókat lemodellezni. A bizonylat a domain része.

### Fő bizonylattípusok
- `V` - valuta vétel
- `E` - valuta eladás
- `F` - pénztári átadás
- `U` - pénztári átvétel
- storno bizonylat
- stornozott másolat
- címletezési lista
- átadólap
- Western Union nyugta
- telefonfeltöltés bizonylat
- e-matrica bizonylat
- egyszerűsített számla
- Paysafe vevő- és saját példány

### Központi blokkformatter
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

### Kötelező feladatod
Minden dokumentumtípushoz készíts:

- trigger-azonosítást
- mezőlistát
- layout logikai bontását
- audit/jogi jelentést
- modern megfelelő representationt

---

## Zárási állapotgép - kritikus üzleti logika

Az egész rendszer egyik legfontosabb üzleti szabályrendszere:

- napnyitás
- lezáratlan nap felismerése
- lezárt nap utáni belépés
- havi zárás kötelezettség
- dekád és kezelési díj nyomtatási kötelezettség

Ezt ne írd le felületesen. Formális állapotgép-szinten dokumentáld.

### Elvárt állapotok
- új nap indítható
- lezáratlan nap van
- nap már lezárt
- hónap nincs lezárva
- kötelező nyomtatvány hiányzik

### Elvárt kimenet
Adj:

- state machine leírást
- precondition/postcondition listát
- modern workflow specifikációt

---

## Pénztár, értéktár, banki lánc

A rendszer nem sima POS. Egy treasury modell fut benne.

### Feltárandó fogalmak
- pénztár
- társpénztár
- értéktár
- főértéktár
- banki beszállítás
- banki kiszállítás
- ügyfélrendelés
- készletrendelés
- körlevél

### Kötelező dokumentumtípusok ehhez
- `ERTEKTARI ATADOLAP`
- `PENZTARI ATADOLAP`
- pénztári átadási és átvételi bizonylatok

### Feltárási cél
Különítsd el:

- customer-facing tranzakciókat
- internal treasury mozgásokat
- bank interfész jellegű mozgásokat

---

## Adatbázisok és perzisztencia

### Tekintendő fő adatbázisok
- `c:\valuta\database\valuta.fdb`
- `c:\valuta\database\valdata.fdb`
- `c:\valuta\database\trade.fdb`
- `{host}:C:\RECEPTOR\DATABASE\...`

### Kötelezően feltárandó kulcstáblák
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

### Szerverfogalom
Ne feltételezd, hogy a szerver REST API. Itt a távoli Firebird DB is szerver.

### Elvárt output
Készíts:

- adatmodell-jelöltet
- táblaszintű glossary-t
- lokális vs távoli adatforrás térképet
- migrációs táblatérképet

---

## Mentés, frissítés, operáció

### Mentés
Bizonyíték:

```pascal
_valpath  := 'c:\valuta\database\valuta.fdb';
_savePath := 'c:\valuta\mentes\lastgood\valuta.fdb';

if fileExists(_savePath) then sysutils.DeleteFile(_savepath);
copyfileto(_valpath,_savepath);
```

Ebből következik:

- van lokális mentési logika
- fájlmásolás-alapú utolsó jó állapot mentés létezik
- a modern rendszerben ezt nem szabad figyelmen kívül hagyni

### Frissítés
Külön `VERZFRIS` modul dolgozik távoli frissítő DB-vel.

### Dokumentumküldés
`SENDOKMANY` és kapcsolódó modulok szinkronizációs vagy továbbítási szerepet töltenek be.

### Elvárt output
Írd le:

- backup stratégia
- restore stratégia
- update stratégia
- field operations runbook

---

## `TRADE` mellékrendszer külön kezelése

Ne olvaszd egybe a fő valutás maggal.

### Fő funkciói
- telefonfeltöltés
- autópályamatrica
- egyszerűsített számla
- Paysafe-jellegű dokumentumok
- tanúsítvány
- logolvasás
- kereskedelmi mellékrendszeres zárások/listák

### Fontos integrációk
- HTTP top-up/kupon endpoint
- FTP tanúsítvány letöltés
- Java helper: `Coupon.exe`
- távoli Firebird `MATRICA.FDB`

### Kötelező feladat
Készíts külön:

- domain summary-t
- retail sidecar szolgáltatás-modellt
- döntést arról, hogy mi maradjon külön bounded context

---

## Kamera és Java ökoszisztéma

Ezt ne hagyd ki, de kezeld külön platformként.

### `camera2`
Moduláris Java platform, főleg:

- config
- office
- center
- player
- export
- inspecter

### Fontos bizonyíték
A régi/újabb Java desktop menü modern értelmezést ad ugyanazokra a legacy funkciókra:

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

### Mit kell ezzel kezdened
- kezeld úgy, mint egy közbenső modernizációs lenyomatot
- hasonlítsd össze a Delphi főmenüvel
- készíts capability crosswalkot

---

## Kötelező deliverable-ek

Az elemzés vagy implementáció végén az alábbiakat kell tudnod előállítani:

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

Ha fejlesztés történik, ezen felül:

11. futtatható célarchitektúra
12. explicit API/contracts
13. UI flow map
14. audit model
15. print template strategy

---

## Prioritási sorrend az AI számára

Dolgozz ebben a sorrendben:

1. `IBVALTO` shell és a menü dispatch feltárása.
2. `VTEMP` teljes mező- és szerepelemzése.
3. `VASARLAS`, `ELADAS`, `STORNO`, `ATADVET`, `NAPZAR`, `LISTAK`, `BLOKNYOM` elemzése.
4. `HARDWARE`, `PENZTAR`, `BLOKKFEJ`, `BLOKKTETEL` és havi táblák feltárása.
5. Mentési, frissítési, dokumentumküldési operációs logika.
6. `TRADE` bounded context feltárása.
7. `camera2` / `camera3` külön platformként történő modellezése.
8. Modern célrendszer tervezése úgy, hogy az üzleti logika ne vesszen el.

---

## Elvárt válaszstílus az AI-tól

Amikor ezen prompt alapján dolgozol:

- mindig nevezd meg a bizonyítékfájlokat
- mindig különítsd el a biztosan bizonyított és a valószínűsített következtetéseket
- mindig emeld ki a domain invariánsokat
- mindig írd le, ha valami implicit szerződésre épül
- mindig mutasd meg, hogy egy legacy funkcióból mi lenne a modern megfelelő

### Válaszformátum
Minden nagy témánál ezt a sablont használd:

1. Funkció neve
2. Bizonyíték
3. Működési logika
4. Érintett DB / állapot
5. Kimenet / dokumentum
6. Üzleti jelentés
7. Modern megfelelő
8. Kockázat / nyitott kérdés

---

## Végső utasítás

Az `Anti` rendszert ne elavult kódtömegként kezeld, hanem egy éles üzleti tudást tároló, rejtett domain-specifikációként. A célod nem a források puszta felsorolása, hanem az, hogy a rendszerből:

- formális üzleti specifikációt,
- migrálható adatmodellt,
- újraimplementálható use-case készletet,
- auditálható dokumentum- és állapotgépet,
- és egy modern, de a legacy működést megőrző célarchitektúrát hozz létre.

Ha bizonyítékot látsz egy szabályra, kezeld kötelező örökölt üzleti logikaként, amíg az ellenkezője nem bizonyított.

Ez a prompt elsődlegesen végrehajtási prompt, nem egyszerű elemzési összefoglaló.

---

## Kiegészítő forrásfájlok

Dolgozás közben tekintsd kiemelt forrásnak:

- `D:\repo\valutavalto-program\antivaluta.GPT-5.4.md`
- `D:\repo\valutavalto-program\legacy-function-map.md`
- `D:\repo\valutavalto-program\Anti\VALUTA\IBVALTO\IBVALTO.DPR`
- `D:\repo\valutavalto-program\Anti\VALUTA\IBVALTO\UNIT1.PAS`
- `D:\repo\valutavalto-program\Anti\VALUTA\IBVALTO\Unit47.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\DLL\BLOKNYOM\MAKEDLL\Unit2.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\DLL\LISTAK\MAKEDLL\Unit2.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\DLL\MENTES\MAKEDLL\Unit2.pas`
- `D:\repo\valutavalto-program\Anti\VALUTA\TRADE\fejleszt\unit1.pas`
- `D:\repo\valutavalto-program\Anti\camera2\camera\pom.xml`
- `D:\repo\valutavalto-program\Anti\camera3\old\excold-desktop-client\target\classes\fxml\MainMenu.fxml`

