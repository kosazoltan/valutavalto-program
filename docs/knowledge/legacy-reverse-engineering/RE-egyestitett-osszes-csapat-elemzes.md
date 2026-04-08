---
type: analysis
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Anti Valutavalto - Egyesiitett Reverse Engineering Elemzes"
load: on-demand
---

# Anti Valutavalto - Egyesiitett Reverse Engineering Elemzes

> **Datum:** 2026-04-02
> **Projekt:** Delphi 7 legacy -> Java + React + Electron
> **Szerzok:** GPT-5.4, Junior, Eszter, Tamas, Gabor
> **Modszer:** 5 parhuzamos elemzes tematikus egyesiitese

---


---

## S1 TARTALOMJEGYZĂK

1. [RendszerarchitektĂşra Ă©s komponensek](#01_RENDSZERARCHITEKTURA)
2. [MenĂĽrendszer, navigĂˇciĂł Ă©s kĂ©pernyĹ‘-tĂ©rkĂ©p](#02_MENURENDSZER)
3. [DLL modul katalĂłgus](#03_DLL_KATALOGUS)
4. [Ăśzleti logika Ă©s pĂ©nzĂĽgyi szabĂˇlyok](#04_UZLETI_LOGIKA)
5. [AML/KYC, ĂĽgyfĂ©lkezelĂ©s Ă©s compliance](#05_AML_KYC)
6. [AdatbĂˇzis architektĂşra Ă©s sĂ©ma](#06_ADATBAZIS)
7. [Bizonylatok, nyomtatĂˇs Ă©s dokumentumok](#07_BIZONYLAT_NYOMTATAS)
8. [Napi Ă©s havi zĂˇrĂˇsok, kĂ©szletkezelĂ©s](#08_ZARAS)
9. [BiztonsĂˇgi architektĂşra Ă©s kockĂˇzatok](#09_BIZTONSAG)
10. [UI/UX design, wireframe-ek Ă©s modernizĂˇciĂł](#10_UI_UX)
11. [KommunikĂˇciĂł, integrĂˇciĂłk Ă©s kĂĽlsĹ‘ rendszerek](#11_KOMMUNIKACIO)
12. [TelepĂ­tĂ©s, ĂĽzemeltetĂ©s Ă©s konfigurĂˇciĂł](#12_TELEPITES)
13. [TesztelhetĹ‘sĂ©g Ă©s tesztstratĂ©gia](#13_TESZTELES)
14. [KĂłdminĹ‘sĂ©g, duplikĂˇciĂł Ă©s karbantarthatĂłsĂˇg](#14_KODMINOSEG)
15. [MigrĂˇciĂłs terv Ă©s stratĂ©gia](#15_MIGRACIO)
16. [JogszabĂˇlyi megfelelĹ‘sĂ©g](#16_JOGSZABALY)
17. [FĂĽggelĂ©kek Ă©s kiegĂ©szĂ­tĹ‘ elemzĂ©sek](#99_FUGGELEKEK)

---

<a name="01_RENDSZERARCHITEKTURA"></a>

# 1. RendszerarchitektĂşra Ă©s komponensek

---


---

## S2 GPT_54_ELEMZĂSE


---

## S3 1_TOP_LEVEL_RENDSZERKEP

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






---

## S4 2_A_LEGACY_VALUTAS_MAG_SZERKEZETE



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





---


---

## S5 JUNIOR_ELEMZĂSE


---

## S6 1_ALKALMAZAS_ARCHITEKTURA

### 1.1 Általános felépítés

A rendszer egy **moduláris Win32 asztali alkalmazás**, amely egyetlen fő EXE-ből (`TRADE.EXE`) és **110+ dinamikusan betöltött DLL modulból** áll. Minden üzleti funkció külön DLL-ben van megvalósítva.

```
TRADE.EXE (fő alkalmazás)
  ├── VALUTA.FDB (Firebird/InterBase adatbázis — pénztári törzsadatok)
  ├── TRADE.FDB  (Firebird/InterBase adatbázis — tranzakciós napló)
  ├── c:\valuta\bin\*.dll (110+ üzleti modul)
  └── c:\valuta\temp\ (ideiglenes fájlok, XML kommunikáció)
```

### 1.2 EXE-DLL kommunikáció

A DLL-ek `stdcall` konvencióval exportálnak egyetlen belépési függvényt. A fő EXE `external` deklarációval tölti be őket:

```pascal
function supervisorjelszo(_para: integer): integer; stdcall;
  external 'c:\valuta\bin\Super.dll' name 'supervisorjelszo';
function matricaregeneralo: integer; stdcall;
  external 'c:\valuta\bin\Matregen.dll' name 'matricaregeneralo';
```

Minden DLL saját Form-ot tartalmaz, ami `ShowModal`-lal jelenik meg. A DLL és az EXE közös Firebird adatbázison keresztül kommunikálnak — nincs közvetlen memória-megosztás, az adatcsere az adatbázison és globális változókon át történik.

### 1.3 Adatbázis-kapcsolat

Két fő Firebird adatbázis:
- **VALUTA.FDB** (`c:\valuta\database\valuta.fdb`): törzsadatok (pénztár, pénztárosok, ügyfelek, hardver, devizanemek, árfolyamok)
- **TRADE.FDB** (`c:\valuta\database\trade.fdb`): tranzakciós adatok (havonta TRADyymm táblák)

Remote szerver adatbázis (központi):
- **REMOTEDBASE** (`193.68.57.146`): központi szinkronizáció, árfolyamok, ügyfélnyilvántartás

Minden DLL saját `TIBDatabase`, `TIBQuery`, `TIBTransaction` komponensekkel kapcsolódik az adatbázisokhoz.

### 1.4 Fő EXE (TRADE.EXE) indulási szekvencia

1. `FormActivate` — ablak méretezés (1024×768, monitor közepére), dátum beállítás
2. `InditoTimer` — tényleges indítás:
   - `Archivalo` — régi havi TRADE táblák törlése (előző év)
   - `Vaninternet` — internet ellenőrzés (nélküle a program nem indul!)
   - `AlapadatBeolvasas` — pénztár név, cím, kód, nyomtató, utolsó ügyfél
   - `HaviTradeControl` — aktuális havi TRADyymm tábla létrehozása ha nincs
   - `SetLogFile` — XOR-kódolt naplófájl inicializálás
   - `matricaregeneralo` — autópálya matrica összesítő tábla regenerálás
   - `GetTanusitvany` — terminál ID/tanúsítvány ellenőrzés (4 karakter)
   - `GetPenztaros.ShowModal` — pénztáros beléptetés jelszóval
   - `CikktorzsBeolvasas` — cikktörzs betöltés memóriába

### 1.5 Könyvtárstruktúra (telepített rendszer)

```
C:\VALUTA\
  ├── bin\              DLL-ek, Coupon.exe (XML kommunikátor)
  ├── database\         Firebird .fdb adatbázisok
  ├── temp\             request.xml, REPLY.XML (kupon API)
  ├── TRADELOG\         XOR-kódolt napi logfájlok
  └── aktlst.txt        aktuális nyomtatási blokk
```

---



---


---

## S7 TAMAS_ELEMZĂSE

# Anti Valutaváltó — Technikai Architektúra és Integrációs Elemzés



---

## S8 TAMAS_TESTOPS_CHIEF_MELYARCHITEKTURA_ELEMZES

> **Dátum:** 2026-04-02  
> **Elemző:** Tamás (testops/Claude Sonnet 4.6)  
> **Forrás:** `D:\repo\valutavalto-program\Anti\VALUTA\`  
> **Referenciák:** `antivaluta-junior.md`, `anti-context-pack.md`, közvetlen forráskód-beolvasás  
> **Célközönség:** Migrációs csapat, tesztstratégia, architektúratervezés

---




---

## S9 1_RENDSZERARCHITEKTURA

### 1.1 Magasszintű komponensdiagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ANTI VALUTAVÁLTÓ RENDSZER                          │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    TRADE.EXE (Főalkalmazás)                          │   │
│  │   Win32 GUI · Delphi 7 · TForm1 · 1024×768 rögzített ablak          │   │
│  │                                                                      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │   │
│  │  │ TelefonGomb │  │ MatricaGomb │  │  ListaGomb  │  │KilepesGomb│  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────┬─────┘  │   │
│  └─────────┼───────────────┼───────────────┼──────────────────┼────────┘   │
│            │               │               │                  │             │
│            ▼               ▼               ▼                  │             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐          │             │
│  │  UNIT2.pas   │ │  UNIT3.pas   │ │  UNIT11.pas  │          │             │
│  │ TelefonForm  │ │ AutopalyaFrm │ │ ZarasForm    │          │             │
│  └──────────────┘ └──────────────┘ └──────────────┘          │             │
│                                                                │             │
│  ┌──────────────────────────────────────────────────────────┐ │             │
│  │                  DLL PLUGIN RÉTEG (110+ modul)           │ │             │
│  │                                                          │ │             │
│  │  c:\valuta\bin\ELADAS.dll     ← devizaeladás            │ │             │
│  │  c:\valuta\bin\VASARLAS.dll   ← devizavásárlás          │ │             │
│  │  c:\valuta\bin\STORNO.dll     ← tranzakció sztornó      │ │             │
│  │  c:\valuta\bin\NAPZAR.dll     ← napzárás                │ │             │
│  │  c:\valuta\bin\HAVIZAR.dll    ← havi zárás              │ │             │
│  │  c:\valuta\bin\UGYFEL.dll     ← ügyféladatok            │ │             │
│  │  c:\valuta\bin\BLOKNYOM.dll   ← bizonylat nyomtatás     │ │             │
│  │  c:\valuta\bin\TERROR.dll     ← terrorizmus szűrés      │ │             │
│  │  c:\valuta\bin\WUNION.dll     ← Western Union           │ │             │
│  │  c:\valuta\bin\OTP.dll        ← OTP terminál            │ │             │
│  │  c:\valuta\bin\COPY2FTP.dll   ← FTP szinkronizáció      │ │             │
│  │  c:\valuta\bin\VERZFRIS.dll   ← verziófrissítés         │ │             │
│  │  ... (+100 további modul)                               │ │             │
│  └───────────────────────────┬──────────────────────────────┘ │             │
│                               │                                              │
│  ┌────────────────────────────▼───────────────────────────────────────────┐ │
│  │                  ADATBÁZIS RÉTEG                                        │ │
│  │                                                                         │ │
│  │  ┌───────────────────┐  ┌──────────────────┐  ┌─────────────────────┐  │ │
│  │  │   VALUTA.FDB      │  │   TRADE.FDB      │  │  REMOTE (TCP)       │  │ │
│  │  │  Törzsadatok      │  │  Tranzakciók     │  │  193.68.57.146      │  │ │
│  │  │  Firebird/IB      │  │  TRADyymm táblák │  │  Firebird Remote    │  │ │
│  │  └───────────────────┘  └──────────────────┘  └─────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 EXE-DLL Interfész Protokoll

A rendszer kizárólag `stdcall` hívási konvenciót alkalmaz az EXE-DLL határán. Ez a Win32 API szabványa, amely garantálja a stack-cleanup rendjét a hívott (callee) oldalán.

#### 1.2.1 Exportált belépési függvény mintája

Minden DLL egyetlen exportált függvényt tartalmaz, amely:
1. Létrehozza a Form objektumot (`TForm.Create(Nil)`)
2. Megmutatja modálisan (`ShowModal`)
3. Felszabadítja (`Free`)
4. Visszaadja a módális eredményt (integer)

```pascal
// STORNO.DLL — stornorutin exportált függvény
function stornorutin: integer; stdcall;
begin
  Stornoform := TstornoForm.Create(Nil);
  Result     := stornoform.showmodal;
  Stornoform.free;
end;

// VASARLAS.DLL — vasarlasrutin exportált függvény
function VasarlasRutin: integer; stdcall;
begin
  VasarlasForm := TVasarlasForm.Create(Nil);
  Result := VasarlasForm.Showmodal;
  VasarlasForm.Free;
end;

// TERROR.DLL — terrorcontrol exportált függvény
function terrorcontrol: integer; stdcall;
begin
  Terror   := TTerror.Create(Nil);
  result   := Terror.showmodal;
  Terror.Free;
end;
```

#### 1.2.2 Statikusan linkelt külső DLL-ek (TRADE.EXE-ből)

```pascal
// A fő EXE nem dynamic LoadLibrary-t használ, hanem fordítási időben
// deklarált 'external' kötéseket:
function supervisorjelszo(_para: integer): integer; stdcall;
  external 'c:\valuta\bin\Super.dll' name 'supervisorjelszo';

function matricaregeneralo: integer; stdcall;
  external 'c:\valuta\bin\Matregen.dll' name 'matricaregeneralo';
```

**Kritikus megfigyelés:** A DLL-ek statikusan kötöttek hardcoded abszolút útvonalakkal. Ha a `c:\valuta\bin\` könyvtár nem létezik, az EXE a betöltésnél azonnal crashel.

#### 1.2.3 Visszatérési értékek konvenciója

| Visszatérési érték | Jelentés |
|-------------------|----------|
| `1` | Sikeres, rendben |
| `2` | Kilépés / megszakítás |
| `-1` | Hiba / jogosultság hiány |
| `3` | Stop / nem folytatható (BIGCTRL komment szerint) |

#### 1.2.4 Paraméterátadás a DLL-ek között

A DLL-ek nem kapnak közvetlen paramétereket — az adatcsere **kizárólag az adatbázis VTEMP táblán** keresztül zajlik. Ez egy szándékos tervezési döntés: a DLL-ek „csomag"-ot olvasnak be a VTEMP-ből és „csomag"-ot írnak vissza.

```
┌─────────┐    VTEMP INSERT    ┌─────────────┐    VTEMP SELECT    ┌─────────┐
│ VASARL. │ ──────────────────► │  TRADE.FDB  │ ──────────────────► │ BLOKNYOM│
│  .DLL   │                    │  VTEMP tbl  │                    │  .DLL   │
└─────────┘    eredmény olv.   └─────────────┘    eredmény ír.   └─────────┘
```

### 1.3 DLL Belső Struktúra — Anatómia

Minden DLL-projekt azonos szekvenciát követ:

```
DLL Projekt struktúra:
├── Project1.dpr          ← Delphi project fájl (library deklaráció)
├── Unit2.pas             ← Egyetlen Pascal forrás (az összes logika itt)
├── Unit2.dfm             ← Form leíró (XML-szerű bináris/text)
└── (opcionális) Unit1.pas ← Segéd unit

Unit2.pas belső felépítése:
├── interface szekció
│   ├── uses (Windows, IBDatabase, IBQuery, IBTable, ...)
│   ├── type TFormX = class(TForm) [UI komponensek deklarációja]
│   ├── var [globális változók — nincs encapsulation!]
│   └── function <modul>rutin: integer; stdcall; [export deklaráció]
└── implementation szekció
    ├── function <modul>rutin: integer; stdcall; [Form create/showmodal/free]
    ├── procedure TFormX.FormActivate [inicializáció + VTEMP olvasás]
    ├── [üzleti eljárások]
    └── [segédfüggvények]
```

### 1.4 Build Rendszer

A rendszer Delphi 7 IDE-vel készül. Nincs automatizált build pipeline — minden DLL-t manuálisan kell lefordítani és `c:\valuta\bin\` alá másolni.

**Verziószám kezelés (VERZFRIS.DLL):**
```pascal
_aktverzio: string = '35.25';  // Hardcoded a DLL forrásban!

// A frissítés folyamata:
_PCS := 'c:\valuta\bin\valto.exe';   // Külső frissítő EXE futtatása
_pacs := pchar(_pcs);
WinExecAndWait32(_pacs, sw_normal);  // Szinkron végrehajtás

// Verzió bejegyzés az adatbázisba:
_pcs := 'UPDATE HARDWARE SET VERZIO=' + _aktVerzio;
ValutaParancs(_pcs);
```

A `WinExecAndWait32` egy szokásos wrapper a `CreateProcess` API köré, amely szinkron módon várja a folyamat végét.

**FTP-alapú automatikus frissítés — azonos belépési adatok mint a szinkronizáció:**
```pascal
_ftpPort    : integer = 21100;
_userId     : string  = 'ebc-10%';
_ftpPassword: string  = 'klc+45%';
```

### 1.5 Alkalmazás Indítási Szekvencia (Részletes)

```
FormActivate (ablak geometria beállítás)
    │
    ▼
InditoTimer (tényleges inicializáció)
    │
    ├─► Archivalo          → TRADyymm táblák törlése (előző év)
    │
    ├─► Vaninternet        → InternetCheckConnection HTTP GET
    │       │
    │       └─ FAIL → ShowMessage('NINCS INTERNET!') → Application.Terminate
    │
    ├─► AlapadatBeolvasas  → TRADE.FDB: PARAMETERS tábla
    │       │                  _terminalid, _username, _password
    │       │                  _lastMatrica, _lastTelefon, _lastUgyfel
    │       │               VALUTA.FDB: PENZTAR tábla
    │       │                  _homePenztarNev, _homePenztarCim, _penztarszam
    │       └─────────────────────────────────────────────────────────────────
    │
    ├─► HaviTradeControl   → Aktuális TRADyymm tábla létezés ellenőrzés
    │       │                  Ha nincs → CREATE TABLE TRAD[yymm] ...
    │       └─────────────────────────────────────────────────────────────────
    │
    ├─► SetLogFile         → C:\VALUTA\TRADELOG\LOG[dátum].dat megnyitás
    │
    ├─► matricaregeneralo  → Matregen.dll hívás (összesítő tábla)
    │
    ├─► GetTanusitvany check → length(_terminalid) <> 4 esetén tanúsítvány form
    │
    ├─► GetPenztaros.ShowModal → PROSBE.DLL: pénztáros beléptetés
    │       │                    result=1: OK, result<>1: kilépés timer
    │       └─────────────────────────────────────────────────────────────────
    │
    └─► CikktorzsBeolvasas → TRADE.FDB: CIKKTORZS tábla
            │                  _ctAzonosito[], _ctEgysegar[], _ctCikknev[]
            └─────────────────────────────────────────────────────────────────
```

### 1.6 Devizanem Tömb — Statikus Konfiguráció

A 27 devizanem kódja és neve statikusan, fordítási időben van meghatározva, több helyen is duplikálva (NAPZAR, HAVIZAR, NAPIFORG DLL-ekben):

```pascal
// NAPZAR.DLL — globális változó szekció
_dnem: array[1..27] of string = (
  'AUD','BAM','BGN','BRL','CAD','CHF','CNY',
  'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
  'JPY','MXN','NOK','NZD','PLN','RON','RSD',
  'RUB','SEK','THB','TRY','UAH','USD');

_dnev: array[1..27] of string = (
  'Ausztral dollar','Bosnyak marka','Bolgar leva',
  'Brazil real','Kanadai dollar','Svajci frank','Kinai juan','Cseh korona',
  'Dan korona','Euro','Angol font','Horvat kuna','Magyar forint',
  'Izraeli shakel','Japan jen','Mexikoi peso','Norveg korona',
  'Ujzelandi dollar','Lengyel zloty','Roman lei','Szerb dinar',
  'Orosz rubel','Sved korona','Thai bath','Torok lira','Ukran hrivnya',
  'Usa dollar');
```

**Architekturális probléma:** Új devizanem hozzáadása minden DLL-t újrafordítást igényel, és a tömb-index (1..27) hardcoded feltételekkel van használva a Scandnem() keresőfüggvényben.

---




---

## S10 2_ADATBAZIS_ARCHITEKTURA

### 2.1 Adatbázis Topológia

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ADATBÁZIS ARCHITEKTÚRA                          │
│                                                                         │
│  Helyi gépen (c:\valuta\database\)                                     │
│  ┌─────────────────────────────────┐  ┌──────────────────────────────┐ │
│  │        VALUTA.FDB               │  │         TRADE.FDB            │ │
│  │    Firebird/InterBase           │  │    Firebird/InterBase        │ │
│  │                                 │  │                              │ │
│  │  PENZTAR          HARDWARE      │  │  PARAMETERS    CIKKTORZS     │ │
│  │  PENZTAROSOK      ARFOLYAM      │  │  TRADyymm      VTEMP         │ │
│  │  UGYFEL           KESZLET       │  │  (havonta új)  MEDIA         │ │
│  │  JOGISZEMELY      CIMLET        │  │  HAVIFEJTABLA                │ │
│  │  DEVIZANEM        UTOLSOBLOKKOK │  │  HAVITETELTABLA              │ │
│  └─────────────────────────────────┘  └──────────────────────────────┘ │
│                                                                         │
│  Helyi gépen (c:\receptor\database\)                                   │
│  ┌─────────────────────────────────┐                                   │
│  │     TERRORISTS.FDB              │                                   │
│  │  UNOLIST (terror szankciós lista│                                   │
│  └─────────────────────────────────┘                                   │
│                                                                         │
│  Távoli szerveren (193.68.57.146)                                      │
│  ┌─────────────────────────────────┐                                   │
│  │     UGYFEL[yy].FDB              │                                   │
│  │     KISUGYFEL.FDB               │                                   │
│  │  (évtizedes ügyfél adatbázisok) │                                   │
│  └─────────────────────────────────┘                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 VALUTA.FDB — Törzsadatok Séma Rekonstrukció

#### 2.2.1 PENZTAR tábla

```sql
CREATE TABLE PENZTAR (
  PENZTARNEV     VARCHAR(40),  -- pl. "Szekszárd Centrum"
  PENZTARCIM     VARCHAR(60),  -- teljes cím
  PENZTARKOD     CHAR(4),      -- pl. "SZKS"
  PENZTARSZAM    SMALLINT      -- pl. 10 (< 151 = EBC, >= 151 = Expressz)
);
```

**Megjegyzés:** A `_penztarszam < 151` feltétel alapján dől el a cégnév és adószám:
```pascal
if _penztarszam < 151 then begin
  _adoszam := '32313332-2-02';
  _cegnev  := 'Exclusive Best Change Zrt';
end else begin
  _cegnev  := 'EXPRESSZ EKSZERHAZ';
  _adoszam := '14040535-2-02';
end;
```

#### 2.2.2 HARDWARE tábla

```sql
CREATE TABLE HARDWARE (
  PRINTER         SMALLINT,     -- 0 = LPT1, 1 = Windows USB nyomtató
  ERTEKTAR        SMALLINT,     -- értéktár kódja (1=SZEKSZÁRD,2=SZEGED,...)
  MEGNYITOTTNAP   CHAR(10),     -- aktuálisan megnyitott nap (éééé.hh.nn)
  HOST            VARCHAR(20),  -- központi szerver IP (pl. '193.68.57.146')
  VERZIO          VARCHAR(10),  -- telepített szoftver verzió
  VFD             SMALLINT,     -- vevőoldali kijelző (0=nincs)
  KELLMATRICA     SMALLINT,     -- 1 = e-matrica funkció aktív
  KELLWESTERN     SMALLINT,     -- 1 = Western Union aktív
  KELLOTP         SMALLINT,     -- 1 = OTP terminál aktív
  NAV             SMALLINT      -- 1 = NAV online kapcsolat aktív
);
```

#### 2.2.3 PENZTAROSOK tábla

```sql
CREATE TABLE PENZTAROSOK (
  PENZTAROSSZAM  INTEGER,       -- sorszám (automatikusan számozódik)
  PENZTAROSNEV   VARCHAR(25),   -- pénztáros neve
  JELSZO         VARCHAR(50),   -- jelszó: '$' prefix = XOR kódolt hex string
  IDKOD          VARCHAR(10)    -- azonosító kód (személyi igazolványhoz)
);
```

**Jelszó formátum:**
- Régi: egyszerű szöveg (nincs `$` prefix)
- Új: `$` + XOR-kódolt hex stringstream (a `Evaulate()` függvény dekódolja)

```pascal
// PROSBE.DLL — Evaulate() jelszó dekódoló
function TprosBelep.Evaulate(_hxj: string): string;
var _hdpw, _cjelszo: string;
    _hxkod, _pp, _lenlex: byte;
begin
  _lenlex  := length(_hxj) - 1;
  _cjelszo := midstr(_hxj, 2, _lenlex);  // '$' levágása
  _pp := 1;
  _hdpw := '';
  while _pp <= _lenlex do begin
    _hxkod := 255 - ord(_cjelszo[_pp]);  // XOR invertálás (255-char)
    _hdpw  := _hdpw + chr(_hxkod);
    inc(_pp);
  end;
  result := _hdpw;
end;
```

#### 2.2.4 ARFOLYAM tábla (rekonstruált)

```sql
CREATE TABLE ARFOLYAM (
  VALUTANEM      CHAR(3),       -- ISO 4217 kód (EUR, USD, stb.)
  VETELIARF      INTEGER,       -- vételi árfolyam (HUF/egység, egész)
  ELADASIARF     INTEGER,       -- eladási árfolyam
  ELSZAMOLASARF  INTEGER,       -- elszámolási árfolyam
  MODOSITODATUM  CHAR(10),      -- utolsó módosítás dátuma
  MODOSITOIDO    CHAR(8)        -- utolsó módosítás ideje
);
```

#### 2.2.5 KESZLET tábla (rekonstruált)

```sql
CREATE TABLE KESZLET (
  VALUTANEM    CHAR(3),
  MENNYISEG    INTEGER,    -- darabszám
  ERTEK        INTEGER,    -- forintérték
  CIMLET_ADAT  BLOB        -- opcionális bináris cimletadat
);
```

### 2.3 TRADE.FDB — Tranzakciós Séma

#### 2.3.1 PARAMETERS tábla

```sql
CREATE TABLE PARAMETERS (
  ELESITVE        SMALLINT,     -- 1 = rendszer aktív
  ELESITESIDEJE   CHAR(16),     -- aktiválás dátum+idő
  LASTMATRICA     INTEGER,      -- utolsó matrica bizonylatszám
  LASTTELEFON     INTEGER,      -- utolsó telefon bizonylatszám
  TERMINALID      CHAR(4),      -- terminál azonosító (4 karakter)
  USERNAME        VARCHAR(20),  -- rendszer felhasználónév
  JELSZO          VARCHAR(50)   -- rendszer jelszó (XOR kódolt)
);
```

#### 2.3.2 CIKKTORZS tábla

```sql
CREATE TABLE CIKKTORZS (
  AZONOSITO    INTEGER,       -- cikkszám
  CIKKNEV      VARCHAR(40),   -- megnevezés (pl. 'T-Mobile 1000 Ft')
  EGYSEGAR     INTEGER,       -- ár forintban
  OPERATOR     VARCHAR(20)    -- operátor neve
);
```

#### 2.3.3 TRADyymm — Dinamikus Havi Tranzakciós Tábla

A tábla neve dinamikusan generálódik: `TRAD` + 2 jegyű év + 2 jegyű hónap:
- `TRAD2601` = 2026 január
- `TRAD2602` = 2026 február
- stb.

```sql
CREATE TABLE TRADyymm (
  TIPUS         CHAR(1),       -- 'M'=matrica, 'T'=T-Mobile, 'N'=Telenor, 'V'=Vodafone
  BIZONYLATSZAM CHAR(8),       -- 8 jegyű bizonylatsorszám
  KATEGORIA     CHAR(33),      -- cikknév/kategória
  STARTDATUM    CHAR(10),      -- érvényesség kezdete
  ENDDATUM      CHAR(10),      -- érvényesség vége
  TELEFONSZAM   CHAR(12),      -- telefonszám (feltöltésnél)
  RENDSZAM      CHAR(10),      -- rendszám (matricánál)
  COUNTRYNAME   CHAR(30),      -- ország neve
  REFERENCEID   CHAR(25),      -- külső referencia azonosító
  TRANZAKCIO    CHAR(12),      -- kupon tranzakció azonosító
  FIZETENDO     INTEGER,       -- forint összeg
  PENZTAROSNEV  CHAR(25),      -- pénztáros neve
  DATUM         CHAR(10),      -- tranzakció dátuma (éééé.hh.nn)
  IDO           CHAR(8),       -- tranzakció ideje (óó:pp:mm)
  SZOLGALTATO   CHAR(10),      -- szolgáltató neve
  SZOLGALTATAS  CHAR(30),      -- szolgáltatás neve
  UGYFELSZAM    INTEGER,       -- ügyfél azonosítója (0 = kisugyfel)
  UGYFELNEV     CHAR(25),      -- ügyfél neve (max 25 karakter)
  UGYFELCIM     CHAR(40),      -- ügyfél címe
  TARSPENZTAR   CHAR(4),       -- társpénztár kódja
  STORNO        SMALLINT,      -- 0=normál, 1=sztornózva
  ELKULDVE      SMALLINT       -- 0=nincs elküldve, 1=elküldve szerverre
);
```

#### 2.3.4 VTEMP — Átmeneti Kommunikációs Tábla

Ez a tábla a legkritikusabb integrációs pont — részletes elemzés a 4. fejezetben.

```sql
CREATE TABLE VTEMP (
  -- Ügyfélszekció
  UGYFELNEV      VARCHAR(40),
  UGYFELCIM      VARCHAR(60),
  UGYFELTIPUS    CHAR(1),      -- 'N'=természetes, 'J'=jogi
  UGYFELSZAM     INTEGER,
  -- Tranzakciószekció
  DATUM          CHAR(10),
  IDO            CHAR(8),
  NEVTABLA       VARCHAR(30),  -- hivatkozott tábla neve
  -- Devizaszekció (soronként több deviza)
  VALUTANEM      CHAR(3),
  ARFOLYAM       INTEGER,
  BANKJEGY       INTEGER,
  FORINTERTEK    INTEGER,
  ELOJEL         CHAR(1),      -- '+' vagy '-'
  -- Bizonylat szekció
  BIZONYLATSZAM  CHAR(8),
  FIZETENDO      INTEGER,
  NETTO          INTEGER,
  TRANZDIJ       INTEGER,
  KEZELESIDIJ    INTEGER,
  -- Egyéb
  GONGYOLVE      SMALLINT,
  SORSZAM        INTEGER,
  STORNO         SMALLINT
);
```

#### 2.3.5 HAVIFEJTABLA és HAVITETELTABLA

Ezek a táblák a napzárás során töltődnek fel a TRADyymm adatokból:

```sql
-- HAVIFEJTABLA: minden tranzakció fejléce havi bontásban
CREATE TABLE HAVIFEJTABLA (
  BIZONYLATSZAM       CHAR(8),
  TIPUS               CHAR(2),       -- tranzakció típus kód
  DATUM               CHAR(10),
  IDO                 CHAR(8),
  NETTO               INTEGER,
  TRANZDIJ            INTEGER,
  KEZELESIDIJ         INTEGER,
  FIZETENDO           INTEGER,
  OSSZESFORINTERTEK   INTEGER,
  UGYFELTIPUS         CHAR(1),
  UGYFELSZAM          INTEGER,
  UGYFELNEV           VARCHAR(40),
  TETEL               SMALLINT,      -- tételek száma
  PENZTAROSNEV        CHAR(25),
  TARSPENZTARKOD      CHAR(4),
  TRBPENZTAR          CHAR(4),       -- trb pénztár kód
  MEGBIZOSZAM         INTEGER,
  MEGBIZOTT           INTEGER,
  PLOMBASZAM          VARCHAR(20),
  STORNO              SMALLINT,
  STORNOZOTTBIZONYLAT CHAR(8),
  STORNOBIZONYLAT     CHAR(8),
  IDKOD               VARCHAR(10),   -- azonosító kód
  FIZETOESZKOZ        SMALLINT       -- 1=készpénz, 2=bankkártya
);

-- HAVITETELTABLA: minden tranzakció tétele (devizasorok)
CREATE TABLE HAVITETELTABLA (
  BIZONYLATSZAM          CHAR(8),
  VALUTANEM              CHAR(3),
  ARFOLYAM               FLOAT,
  ELSZAMOLASIARFOLYAM    FLOAT,
  BANKJEGY               INTEGER,
  FORINTERTEK            INTEGER,
  ELOJEL                 CHAR(1),
  COIN                   SMALLINT,   -- 0=bankjegy, 1=érmék
  STORNO                 SMALLINT,
  DATUM                  CHAR(10)
);
```

### 2.4 Tábla-Kapcsolati Térkép

```
VALUTA.FDB                         TRADE.FDB
═══════════                        ══════════
PENZTAR ──────────────────────────► PARAMETERS (nincs FK, de szinkron adat)
    │                               │
    │ penztarszam                   │ terminalid
    ▼                               ▼
HARDWARE                           CIKKTORZS
    │                               │
    │ ertektar                      │ azonosito
    ▼                               ▼
PENZTAROSOK                        TRADyymm ──────┐
    │                               │              │
    │ penztarosszam                 │ bizonylat    │ Napzáráskor
    ▼                               ▼              ▼
ARFOLYAM                           VTEMP ──► HAVIFEJTABLA
    │                               │   (temp)     │
    │ valutanem                     │              │
    ▼                               │              ▼
KESZLET                            │         HAVITETELTABLA
    │                               │
    │ valutanem                     │ datum
    ▼                               ▼
CIMLET                             (archív törlés előző év)


RECEPTOR (helyi, c:\receptor\database\)
═══════════════════════════════════════
TERRORISTS.FDB
    └── UNOLIST (TERROR_NAME LIKE '%keresés%')

REMOTE (193.68.57.146)
══════════════════════
UGYFEL[yy].FDB    ← évtizedes bontás (pl. ugyfel2.fdb = 2020-as évtized)
KISUGYFEL.FDB     ← 300k alatti, azonosítás nélküli ügyfelek
```

### 2.5 Dinamikus Útvonal-konstruálás

```pascal
// VASARLAS.DLL — remote path meghatározás az évtized alapján
_aktdek := yearof(Date) - 2000;  // pl. 2026 → 26 → aktdek=2 (2020-as évtized)
_remotePath    := _host + ':c:\receptor\database\ugyfel' + inttostr(_aktdek) + '.fdb';
_kisRemotePath := _host + ':c:\receptor\database\kisugyfel.fdb';
```

Ez azt jelenti: 2020-2029 között az `ugyfel2.fdb` fájlt használja — évtizedenkénti adatbázis-rotáció.

---




---

## S11 6_BIZTONSAGI_ARCHITEKTURA

### 6.1 Jelszókezelés

#### 6.1.1 XOR-alapú Jelszó Titkosítás

Az alkalmazásban kétféle jelszókezelés van:

**1. Pénztáros jelszó (PROSBE.DLL):**

```pascal
// JelszoKodolo — jelszó titkosítás (íráskor)
function TPROSBELEP.JelszoKodolo(_bej: string): string;
// Az implementáció valószínűleg: minden karakter → 255-char (XOR invertálás)
// Majd hex string konvertálás '$' prefix-szel

// Evaulate — jelszó visszafejtés (olvasáskor)
function TprosBelep.Evaulate(_hxj: string): string;
var _hdpw, _cjelszo: string;
    _hxkod, _pp, _lenlex: byte;
begin
  _lenlex  := length(_hxj) - 1;
  _cjelszo := midstr(_hxj, 2, _lenlex);  // '$' prefix levágása
  _pp := 1;
  _hdpw := '';
  while _pp <= _lenlex do begin
    _hxkod := 255 - ord(_cjelszo[_pp]);  // XOR: 255 - ASCII kód
    _hdpw  := _hdpw + chr(_hxkod);
    inc(_pp);
  end;
  result := _hdpw;
end;
```

**Kritikus biztonsági gyengeség:** Ez nem titkosítás, hanem csak obfuszkáció. Az `f(f(x)) = x` — azaz az algoritmus saját inverze. Bármilyen hex dump az adatbázisból azonnal visszafejthető.

**2. Supervisor jelszó hardcoded backdoor:**
```pascal
// PROSBE.DLL — jelszó ellenőrzés
if _beirtjelszo = '628' then begin
  ShowMessage('JELSZO RENDBEN. A PROGRAM INDULHAT !');
  Rendbenvissza;
  exit;
end;
```

**A `'628'` a mesterjelszó (backdoor)!** Bármelyik pénztárosként be lehet lépni ezzel.

#### 6.1.2 Naplófájl XOR Titkosítás

```pascal
// TRADE.EXE — Kodxor()
function TForm1.Kodxor(_s: string): string;
begin
  result := '';
  for _y := 1 to length(_s) do begin
    _asc := 255 - ord(_s[_y]);  // XOR invertálás (255-karakter)
    result := result + chr(_asc);
  end;
end;
```

Azonos algoritmus a jelszókezeléssel. A naplóbejegyzések `Kodxor` transzformáción mennek át. Egy XOR-naplót visszafejteni: `Kodxor(Kodxor(naplóbejegyzés)) = naplóbejegyzés`.

#### 6.1.3 LOGOLVASÓ — Log visszafejtés

```pascal
// LOGOLVASAS.DLL
// A supervisor a LOGOLVASOGOMB-ra kattintva olvashatja a logot
// Előfeltétel: supervisor jelszó (Super.dll)
// A megjelenítéskor Kodxor() függvénnyel dekódolja a sorokat
```

### 6.2 Hitelesítési Architektúra

#### 6.2.1 Supervisor Jelszó (SUPER.DLL)

```pascal
// Minden védett funkcióban:
_spk := supervisorjelszo(0);
if _spk <> 1 then begin
  // Megtagadva
  exit;
end;
```

A `supervisorjelszo()` visszatérési értéke:
- `1` = helyes jelszó megadva
- `<>1` = elutasítás

Védett műveletek:
- Tanúsítvány szerkesztés
- Log megtekintés
- Árfolyam módosítás
- Sztornó
- Árfolyam módosítás
- Terrorizmus szűrés engedélyezése

#### 6.2.2 Pénztáros Belépés Folyamata

```
1. Pénztáros grid megnyitása (VALUTA.FDB / PENZTAROSOK tábla)
2. Pénztáros kiválasztása (kattintás vagy Enter)
3. Jelszó bekérése (JelszoPanel)
4. Jelszó ellenőrzés:
   a. Ha hexMark = '$' → Evaulate() dekódolás → összehasonlítás
   b. Ha nincs '$' prefix → JelszoKodolo() titkosítás → DB-be írás (első bejelentkezés!)
   c. Ha beirt jelszó = '628' → mindenképpen belép (BACKDOOR)
5. 3 hibás kísérlet → ModalResult = -1 (kilépés)
6. Ha IDKOD > '/' → közvetlen belépés
   Ha IDKOD <= '/' → ID kód lista megnyitása (személyi igazolvány szám választó)
```

### 6.3 Hálózati Biztonság

#### 6.3.1 Hardcoded Credentials — Összefoglalás

```pascal
// Minden helyen azonos, hardcoded FTP hitelesítés:
_host        : string = '185.43.207.99';
_ftpPort     : integer = 21100;
_userId      : string = 'ebc-10%';
_ftpPassword : string = 'klc+45%';
```

Ez a jelszó megtalálható a forrásban:
- `TRADE.EXE Unit1.pas`
- `COPY2FTP.DLL Unit2.pas`
- `PROSBE.DLL Unit2.pas`
- `VERZFRIS.DLL Unit2.pas`
- Minden más DLL ami FTP-t használ

#### 6.3.2 Firebird Szerver Hozzáférés

```pascal
// Firebird kapcsolat nincs titkosítva (Firebird 2.x plain text wire protocol)
// Nincs SSL wrapper
// Port 3050 alapértelmezetten nyitva kell legyen a tűzfalon
// A szerver oldali hitelesítési adatok az IBDatabase komponens property-jeiben vannak
// (ezek a .dfm fájlokban tárolódnak — bináris/text form leíró)
```

#### 6.3.3 HTTPS Kupon API Kapcsolat

```pascal
_url := 'https://193.68.57.146/kupon/as.php';
// HTTPS-t használ, de:
// - IP cím alapú, nem hostname
// - Valószínűleg self-signed cert
// - WinInet alapértelmezetten elfogadja a self-signed cert-et warning nélkül
```

### 6.4 Terrorizmus / AML Szűrés Architektúra

```pascal
// TERROR.DLL — BetuKiemelo transzformáció
// Az ügyfélnév ékezet-nélküli formára hozása:
// Á→A, É→E, Í→I, Ó→O, Ö→O, Ő→O, Ú→U, Ü→U, Ű→U
// Majd: 'TERROR_NAME LIKE [ügyfélnév]%' keresés az UNOLIST táblában

// A szűrés eredménye:
// _recno = 0 → nincs találat → automatikus folytatás (log bejegyzéssel)
// _recno > 0 → gyanús találat → ablak megnagyobbodik, manuális döntés kell

// Engedélyezés:
_spk := supervisorjelszo(0);  // Supervisor jelszó kell!
if _spk <> 1 then _mResult := -1  // megtagadva
else _mResult := 1;               // engedélyezve

// Regisztrálás:
procedure TTERROR.Regisztracio;
// INSERT INTO VTEMP (ENGEDELYEZO, ...) VALUES (...)
```

### 6.5 Kriptográfiai Gyengeségek Összefoglalás

| Terület | Jelenlegi megoldás | Kockázat szint | Modern alternatíva |
|---------|-------------------|----------------|-------------------|
| Pénztáros jelszó | XOR (255-char) | KRITIKUS | bcrypt/Argon2 |
| Naplófájl | XOR obfuszkáció | MAGAS | HMAC-SHA256 |
| Supervisor jelszó | Hardcoded '628' backdoor | KRITIKUS | MFA |
| FTP jelszó | Plaintext forrásban | KRITIKUS | Env var / KeyVault |
| Firebird kapcsolat | Titkosítatlan | MAGAS | SSL/TLS |
| HTTP kupon API | HTTPS de self-signed | KÖZEPES | Érvényes cert |
| Ügyfél adatok DB | Titkosítatlan DB fájl | MAGAS | Firebird embedded encrypt |

---



---


---

## S12 GABOR_ELEMZĂSE


---

## S13 1_VEZETOI_OSSZEFOGLALO

Az Anti Valutaváltó rendszer egy **Delphi 7-ben írt, Win32 asztali alkalmazás**, amely 2000-es évek közepének design paradigmáit tükrözi. A 110+ DLL modulra épülő architektúra, a hardkódolt abszolút koordináták, a `bsNone` border-stílus és a TShape-alapú layout mind egy olyan korszak termékei, amikor a desktop UI fejlesztés legjobb práktikái alapvetően mások voltak.

### Kulcsmegállapítások

**Erősségek (amit meg kell tartani):**
- A valutaváltási workflow logikailag érthető és lineáris
- A nagy betűs, kontrasztos fejlécek (ELADÁS, VÁSÁRLÁS) vizuálisan segítik a gyors orientációt
- A keyboard-first megközelítés (End/Escape billentyűk) profi pénztáros-munkavégzést támogat
- A moduláris DLL-architektúra izolált funkcionalitást biztosít

**Kritikus problémák (amit modernizálni kell):**
- Abszolút pixel-pozicionálás → nem skálázható, nem reszponzív
- Konzisztens design language hiánya (minden form más színvilágban, más fontokban)
- Nulla accessibility support (screen reader, billentyűzet-navigáció rendszertelen)
- Modal-heavy UX (minden DLL `ShowModal`) → párhuzamos munkavégzés lehetetlen
- Hardkódolt 1024×768 → modern kijelzőkön használhatatlan skálán fut
- Nincs state management, nincs visszavonás, nincs undo
- Az ügyfél-azonosítási flow rendkívül hosszú és megzavarható

### Migrációs stratégia egy mondatban

> A modern rendszernek meg kell tartania a **pénztáros-centrikus, gyors billentyűzetes munkavégzési paradigmát**, miközben egy egységes, skálázható, hozzáférhető React component library-n alapuló design rendszert vezet be.

---




---

## S14 2_A_LEGACY_RENDSZER_VIZUALIS_DNA_JA_DFM_ALAPU_ELEMZES

### 2.1 Szín- és stílusrendszer rekonstrukció

A DFM fájlok alapján az egyes formok saját, egymástól eltérő színvilágot használnak:

| Form | Háttérszín | Fejléc | Akcentus |
|------|-----------|--------|---------|
| TRADE főmenü | `clMoneyGreen` (#00FF80 jellegű) | Fehér keret | Fehér szegély 8px |
| VASARLASFORM | `6324288` (sötét kékeszöld) | `clNavy` szöveg | `clSilver` árnyék-duplikátum |
| ELADASFORM | `16756991` (halvány kék) + `clNavy` keret | `clRed` + `clSilver` duplikátum | Piros/ezüst 3D-effekt |
| STORNOFORM | `clTeal` | `clWhite` Elephant font | `clGreen` panel |
| NAPZARFORM | `3289650` (sötétzöld) | `clYellow` szöveg | `clWhite` keret |
| UGYFELINPUT | `10526880` (ólomszürke-kék) | — | AlphaBlend=True |
| PROSBELEP | `clBlack` + `5592405` (szürkéskék) | `clYellow` szöveg | `10066329` (sötét) |
| SUPERVISORFORM | `clGray` + `clBlack` | `clYellow` szöveg | `5592405` panel |
| BIZONYLATDISP | `clWhite` alap | `4210752` (sötétszürke) | `clYellow` fejléc |
| FOGLALO | `clMedGray` | háttérkép (tengerpart JPEG) | TImage fullscreen |
| CIMLETEZES | `11599871` (kékeszöld) | `clMoneyGreen` keret | `15782096` (arany) |

**Következtetés:** A rendszerben **legalább 8 különböző színséma** van párhuzamosan alkalmazva. Nincs egységes design token, nincs brand guideline, nincs konzisztens UX.

### 2.2 Tipográfia elemzés

A DFM-ekben előforduló fontok:

| Font | Előfordulás | Kontextus |
|------|------------|---------|
| `MS Sans Serif` | MINDEN form alapértelmezése | Alap UI szöveg (11pt) |
| `Times New Roman` | ELADÁS/VÁSÁRLÁS fejlécek | 96pt (!) szuperméretű fejlécek |
| `Arial Narrow` | STORNO instrukciós szövegek | Bold Italic |
| `Arial` | Bizonylat grid, STORNO bizonylat | Bold, 19-29pt |
| `Elephant` | STORNO főcím | 27pt Bold — dekoratív |
| `Britannic Bold` | BIZODISP NAV gomb | Monospaced decorative |
| `Stencil` | Verziófelirat (főmenü) | 32pt Bold Italic — katonai stencil |
| `Times New Roman Italic` | Napzárás checklist | 21pt Italic |

**Kritika:** 8 különböző fontcsalád, 5+ különböző méreti skála, inkonzisztens stílus. A `Elephant` és `Stencil` fontok kifejezetten dekoratív, nem üzleti célra tervezett betűtípusok — egy pénztári rendszerben ez professzionalizmus-hiányra utal.

### 2.3 Layout koordináták elemzése

**VASARLASFORM (1031×752 px) layout mérés:**
- Fejléc blokk: Shape1 @ Left=152, Top=10, W=649, H=105 → a form szélességének 63%-a
- Fő beviteli terület: Shape2 @ Left=24, Top=128, W=945, H=361 → 91% széles, 48% magas
- Árfolyam panel: Shape20 @ Left=816, Top=8, W=169, H=105 → jobb felső sarok
- Devizanem panel: Shape22 @ Left=8, Top=8, W=129, H=105 → bal felső sarok
- Számoló terület: Shape3-4 @ Left=40-232, Top=550, H=105 → alsó harmad
- Akció gombok: Shape6-7 @ Left=432-712, Top=660, H=49 → legalul

**ELADASFORM (1001×755 px) layout mérés:**
- Fejléc: Shape1 @ Left=296, Top=16, W=441, H=105 → középen, kisebb mint a VASARLAS
- Árfolyam box: Shape2 @ Left=752, Top=24, W=225, H=105
- Fő beviteli: Shape3 @ Left=24, Top=136, W=945, H=353
- Devizanem bal: Shape21 @ Left=24, Top=16, W=257, H=105

**Megállapítás:** Még a két legfontosabb, egymáshoz legszorosabban kapcsolódó képernyő (vétel/eladás) sem egységes layout-on alapul. A fejléc pozíciója, a panel méretek, a gomb elhelyezések mind különböznek.

### 2.4 Interakciós modellek

**Billentyűzetes navigáció:**
- `End` → tranzakció rögzítése / jóváhagyás (mindkét form alján felirat: "End")
- `Escape` → kilépés a formból (mindkét form alján felirat: "Escape")
- `FormKeyDown` eseménykezelők → billentyűzetes workflow-k
- `DBGrid OnDblClick` → bizonylat megnyitás dupla kattintással

**Modális ablakok:**
- Minden DLL `ShowModal`-lal hívódik → a teljes alkalmazás blokkolódik
- Nincs párhuzamos munkafolyamat (pl. árfolyam ellenőrzése tranzakció közben)
- Nincs Tab-sorend dokumentáció a DFM-ekben

### 2.5 A "3D árnyék" szöveg technika

Az ELADÁS és VÁSÁRLÁS fejléceken alkalmazott vizuális technika:

```
Label11 (clRed, 96pt, Left=328, Top=16)    ← előtér, piros
Label1  (clSilver, 96pt, Left=344, Top=24) ← árnyék, ezüst, 16px offsettel
```

Ez egy 2000-es évekbeli Delphi "3D szöveg" trükk — két azonos szöveges label pixeleltolással, hogy mélység-illúziót keltsen. Érdemes megjegyezni, hogy ez a mai CSS `text-shadow` egyenértékűje volt, egykor.

---




---

## S15 3_NAVIGACIOS_ARCHITEKTURA_ELEMZES

### 3.1 A jelenlegi navigáció

A jelenlegi rendszer navigációs modellje: **Lapos, közvetlen modal-hívás**.

```
TRADE.EXE (főmenü)
    │
    ├── [TelefonGomb] → TELEFONFORM.dll (ShowModal)
    ├── [MatricaGomb] → AUTOPALYAFORM.dll (ShowModal)
    ├── [ListaGomb]   → ZARAS.dll → (belül tovább)
    │                              ├── NAPZAR.dll
    │                              ├── NAPKONYV.dll
    │                              ├── NAPIFORG.dll
    │                              └── ...
    ├── [KilepesGomb] → QUITFORM.dll (megerősítés)
    ├── [TanusitvanyGomb] → SUPER.dll jelszó → GETTANUSITVANY.dll
    └── [LOGOLVASOGOMB]   → SUPER.dll jelszó → LOGOLVASAS.dll

Devizaváltás (nincs külön gomb a főmenün! — belső flow)
    └── ELADAS.dll / VASARLAS.dll → UGYFEL.dll → TERROR.dll → BLOKNYOM.dll
```

**Probléma:** A devizaváltás — a rendszer elsődleges funkciója — nem látható a főmenün! A pénztáros a "Lista és Zárás" gombból navigál a tényleges váltási funkciókhoz, ami kontra-intuitív.

### 3.2 Navigációs mélység-térkép

```
Szint 0: TRADE.EXE főmenü (4+2 gomb)
    │
    Szint 1: DLL modal (egyszerre egy látható)
        │
        Szint 2: Belső DLL-hívás más DLL-ből
            │
            Szint 3: Megerősítő dialog (CONFIRM.dll, QUITFORM.dll)
```

Maximális navigációs mélység: **3-4 szint**, de mivel minden szint blokkoló modal, a felhasználó nem látja, hol tart a folyamatban.

### 3.3 Kontextus-elvesztési pontok

1. A STORNO formban bizonylat kiválasztása után ha a pénztáros visszanavigál, az indoklás mező ürül
2. A VASARLAS és ELADAS formokban ha internetkapcsolat szakad, a form bezárul adatvesztéssel (VTEMP tábla maradvány)
3. UGYFEL bevitelkor ha a terror szűrés meghiúsul, az egész ügyfél-adatbevitel elvész

---




<a name="02_MENURENDSZER"></a>

# 2. MenĂĽrendszer, navigĂˇciĂł Ă©s kĂ©pernyĹ‘-tĂ©rkĂ©p

---


---

## S16 GPT_54_ELEMZĂSE


---

## S17 4_A_IBVALTO_MENURENDSZERE



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





---


---

## S18 JUNIOR_ELEMZĂSE


---

## S19 2_FOMENU_ES_MENUPONTOK

A fő Form1 4 nagy gombot tartalmaz:

| Gomb | Funkció | DLL/Form |
|------|---------|----------|
| **TelefonGomb** | Mobiltelefon feltöltés | TELEFONFORM (Unit2) |
| **MatricaGomb** | Autópálya matrica vásárlás | AUTOPALYAFORM (Unit3) |
| **ListaGomb** | Feladás és listák / Zárás | ZARAS (Unit11) |
| **KilepesGomb** | Kilépés | — |
| **TanusitvanyGomb** | Tanúsítvány szerkesztés (supervisor) | GETTANUSITVANY (Unit9) |
| **LOGOLVASOGOMB** | Naplóolvasó (supervisor) | LOGOLVASAS (Unit13) |

A "supervisor" funkciókhoz (`TanusitvanyGomb`, `LOGOLVASOGOMB`) előzetes supervisor jelszó szükséges a `Super.dll`-en keresztül.

---



---


---

## S20 GABOR_ELEMZĂSE


---

## S21 4_KEPERNYO_KATALOGUS_ES_ASCII_WIREFRAME_EK

### 4.1 Főmenü (TRADE.EXE / Form1)

**DFM adatok:**
- Méret: 1022×740px, `bsNone`, `wsMaximized`
- Háttér: `Shape2` — `clMoneyGreen` fill, `clWhite` Pen.Width=8
- Verziófelirat: `Label4` — "35.10 verzió", `Stencil` font, 32pt, clRed
- Jobb felső: `Shape4` RoundRect

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│██████████████████████████████████████████████████████████████████████████████████████│
│█                                                                                    █│
│█  35.10 verzió          [EXCLUSIVE BEST CHANGE logó/fejléc]       [Tanúsítvány]    █│
│█  (Stencil, piros)                                                [Szerkesztés]     █│
│█                                                                                    █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │         T E L E F O N                       │                      █│
│█              │         feltöltés                           │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │         M A T R I C A                       │                      █│
│█              │         autópálya                           │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │     L I S T Á K  /  Z Á R Á S              │                      █│
│█              │                                             │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█              ┌─────────────────────────────────────────────┐                      █│
│█              │                                             │                      █│
│█              │         K I L É P É S                       │                      █│
│█              │                                             │                      █│
│█              └─────────────────────────────────────────────┘                      █│
│█                                                                                    █│
│█  [NAPLÓ]                                          [háttérkép: NYC skyline]        █│
│██████████████████████████████████████████████████████████████████████████████████████│
```

**UX kritika:**
- A **devizaváltás nincs a főmenün** — a rendszer primér funkciója láthatatlan
- 4 főgomb + 2 supervisor gomb = nagyon szűk funkcionális felület
- A "Lista és Zárás" összevont gomb kettős felelősséget hordoz (riport + napi zárás)
- A háttérkép (New York City skyline) `Image1` komponensként be van ágyazva → teljesen irreleváns a pénztári kontextusban

---

### 4.2 Devizavásárlás (VASARLASFORM)

**DFM adatok:**
- Méret: 1031×752px, `bsNone`
- Háttér: `6324288` (sötét kékeszöld)
- Fejléc: VÁSÁRLÁS — kétréteges Label (clNavy + clSilver árnyék), 96pt Times New Roman Bold
- `AlphaBlendValue = 225` (95% opák)
- Shape22 = devizanem bal felső (Left=8, W=129)
- Shape20 = árfolyam jobb felső (Left=816, W=169)
- Shape2 = fő input zóna (Left=24, Top=128, W=945, H=361)
- Shape3 = bal alsó panel (Left=40, Top=550, W=177, H=105)
- Shape4 = jobb alsó panel (Left=232, Top=550, W=745, H=105)
- Shape6, Shape7 = akció gombok alul

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ [EUR]      ╔══════════════════════════════════════════╗      [Árfolyam: 395.50]     │
│ devizanem  ║         V Á S Á R L Á S                 ║      [Vételi / Eladási]      │
│            ║         (96pt Times, Navy+Silver)        ║                              │
│            ╚══════════════════════════════════════════╝                              │
│                                                                                      │
│ ╔══════════════════════════════════════════════════════════════════════════════════╗ │
│ ║  DEVIZA BEVITEL                                                                  ║ │
│ ║                                                                                  ║ │
│ ║  Összeg 1: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 2: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 3: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 4: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 5: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║  Összeg 6: [______] Bankjegy: [______] Darab: [______]  = [________] Ft         ║ │
│ ║                                                                                  ║ │
│ ║  [WA1..WA6 = összegmezők, WB1..WB6 = bankjegy, WD1..WD6 = darab]               ║ │
│ ╚══════════════════════════════════════════════════════════════════════════════════╝ │
│                                                                                      │
│ ╔═══════════╗  ╔═══════════════════════════════════════════════════════════════╗    │
│ ║  KÉSZLET  ║  ║  FIZETENDŐ:                              [125 480 Ft]         ║    │
│ ║  [állapot]║  ║  Kezelési díj: [500 Ft]     Nettó: [124 980 Ft]              ║    │
│ ╚═══════════╝  ╚═══════════════════════════════════════════════════════════════╝    │
│                                                                                      │
│              [  End — RÖGZÍT  ]              [  Escape — KILÉP  ]                   │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A WA1-WA6, WB1-WB6, WD1-WD6 mező-elnevezések szoftverfejlesztői nómenklatúra, nem felhasználóbarát
- 6 sor × 3 mező = 18 input mező egyidejűleg látható → kognitív túlterhelés
- Az árfolyam csak a jobb felső sarokban látható — nem kiemelkedő pozíció egy tranzakció szempontjából kritikus adatnak
- Nincs vizuális visszajelzés a gépelt összeg érvényességéről (keret-szín váltás, ikon)
- A `End` billentyű nem ENTER — nem intuitív első használatra
- A devizanem (EUR, USD stb.) kis méretű dobozban, bal felső sarokban → elveszett

---

### 4.3 Devizaeladás (ELADASFORM)

**DFM adatok:**
- Méret: 1001×755px, `bsNone`
- Háttér: `16756991` (halvány égkék)
- Fejléc: ELADÁS — kétréteges Label (clRed + clSilver árnyék, 96pt Times New Roman Bold Italic)
- Shape1 = fejléc keret (Left=296, Top=16, W=441, H=105) — KISEBB mint a VÁSÁRLÁSNÁL
- Shape21 = bal panel (Left=24, Top=16, W=257) — NINCSEN a VÁSÁRLÁSNÁL

**Megállapítás:** Az ELADÁS és VÁSÁRLÁS form szinte tükörképek üzletileg, de design szempontból különbözők:
- Más háttérszín (halvány kék vs. sötét kékeszöld)
- Más fejléc-pozíció és méret
- A fejléc szín más (piros vs. navy)
- Bal felső panel eltér (Shape21 vs. Shape22 eltérő méretű)

Ez azt jelenti, hogy a pénztáros vizuálisan is különbséget tud tenni vétel és eladás között — ez pozitív. De a végrehajtás ad hoc, nem rendszer-szintű designdöntés.

**Rekonstruált layout (összehasonlításban VASARLAS-szal):**

```
VÁSÁRLÁS (sötét háttér, navy fejléc):        ELADÁS (világos háttér, piros fejléc):
┌──────────────────────────────────┐          ┌──────────────────────────────────┐
│ [EUR]          VÁSÁRLÁS          │          │ [bal box]      ELADÁS            │
│                (navy/silver)     │ [Árfolyam│                (red/silver)      │
│                                  │  jobb f.]│                                  │
│  ╔══════════════════════════╗   │          │  ╔══════════════════════════╗   │
│  ║ 6×3 input mező           ║   │          │  ║ 6×3 input mező           ║   │
│  ╚══════════════════════════╝   │          │  ╚══════════════════════════╝   │
│  [Készlet] [Fizetendő panel]     │          │  [bal panel] [jobb panel]        │
│      [End]           [Escape]    │          │       [End]          [Escape]    │
└──────────────────────────────────┘          └──────────────────────────────────┘
```

---

### 4.4 Sztornó (STORNOFORM)

**DFM adatok:**
- Méret: 612×517px, `bsNone`
- Háttér: `clTeal`
- Fejléc: "MAI BIZONYLAT STORNÓJA" — `Elephant` font, 27pt Bold, fehér szöveg
- Panel1 (clGreen háttér): a fő tartalmi panel
- `radiok: TGroupBox` (Left=24, Top=64, W=193, H=281) — 4 radio gomb (VR/ER/UR/FR)
- `BIZONYLATRACS: TDBGrid` (Left=224, Top=76, W=329, H=267) — bizonylat lista
- Label9 "Bizonylat:" + Label1 "keresése ..." — szöveges vezető
- `INDOKEDIT` — indoklás mező

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────┐
│  MAI BIZONYLAT STORNÓJA   (Elephant font, 27pt, fehér/teal) │
│                                                              │
│  ╔════════════════════════════════════════════════════════╗  │
│  ║ (clGreen panel)                                        ║  │
│  ║                                                        ║  │
│  ║  VÁLASSZA KI A SZTORNÓZANDÓ BIZONYLATOT                ║  │
│  ║                                                        ║  │
│  ║  ┌─────────────────┐   ┌───────────────────────────┐  ║  │
│  ║  │ ( ) Vétel (VR)  │   │ BIZONYLAT  │ ÖSSZEG       │  ║  │
│  ║  │ ( ) Eladás (ER) │   │────────────┼──────────────│  ║  │
│  ║  │ ( ) Ügyfél (UR) │   │ 00123456   │   125 480    │  ║  │
│  ║  │ ( ) Forrás (FR) │   │ 00123457   │    45 200    │  ║  │
│  ║  │                 │   │ 00123458   │   318 000    │  ║  │
│  ║  │                 │   │            │              │  ║  │
│  ║  └─────────────────┘   └───────────────────────────┘  ║  │
│  ║                                                        ║  │
│  ║  Bizonylat: [___________________]   keresése ...       ║  │
│  ║                                                        ║  │
│  ║  Indoklás: [_____________________________________________]║  │
│  ║                                                        ║  │
│  ║   [ IGEN — Sztornózom ]     [ NEM — Mégsem ]          ║  │
│  ║                                                        ║  │
│  ╚════════════════════════════════════════════════════════╝  │
└──────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A `radiok` TGroupBox-ban 4 rádió gomb van (VR/ER/UR/FR) — ezek kódbetűk, nem felhasználóbarát megnevezések
- A bizonylat grid csak 2 oszlopot mutat (BIZONYLATSZAM, FIZETENDO) — hiányzik a dátum, devizanem, ügyfél
- A dupla megerősítés (`Surestorno`) külön DLL-ből hívódik — a flow megszakad
- Az indoklás mező helye (alul, a grid alatt) nem logikus — inkább a kiválasztás után kellene

---

### 4.5 Napzárás (NAPZARFORM)

**DFM adatok:**
- Méret: 578×504px, `bsNone`, `AlphaBlendValue = 180` (30% átlátszó!)
- Háttér: `3289650` (nagyon sötétzöld)
- Fejléc: "NAPI PÉNZTÁRZÁRÁS" — `clYellow`, 32pt Times New Roman Bold Italic
- `DATUMPANEL`: 2017.05.22 felirat (hardkódolt demo dátum!), 29pt Arial Bold Italic, fehér
- `ELLENORPANEL` (Visible=False): 5 ellenőrzési lépés panel

**Az ELLENORPANEL 5 lépése:**
- E1: MTCN számok ellenőrzése
- E2: Pénztárzárás címletezése
- E3: Kezelési díj ellenőrzése
- E4: W.U. címletezése
- E5: ÁFA pénztár címletezése

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│       NAPI PÉNZTÁRZÁRÁS                              │
│       (clYellow, 32pt, sötétzöld háttér)             │
│                                                      │
│  ╔══════════════════════════════════════════════╗    │
│  ║  2017.05.22   (DATUMPANEL — aktuális dátum)  ║    │
│  ╚══════════════════════════════════════════════╝    │
│                                                      │
│  ╔══════════════════════════════════════════════╗    │
│  ║ [ELLENORPANEL — kezdetben Visible=False]      ║    │
│  ║                                              ║    │
│  ║  ╔═══════════════════════════════════════╗   ║    │
│  ║  ║  Ellenőrzési folyamatok               ║   ║    │
│  ║  ╟───────────────────────────────────────╢   ║    │
│  ║  ║  E1: MTCN számok ellenőrzése    [ OK ]║   ║    │
│  ║  ║  E2: Pénztárzárás címletezése   [ .. ]║   ║    │
│  ║  ║  E3: Kezelési díj ellenőrzése   [ .. ]║   ║    │
│  ║  ║  E4: W.U. címletezése           [ .. ]║   ║    │
│  ║  ║  E5: ÁFA pénztár címletezése    [ .. ]║   ║    │
│  ║  ╚═══════════════════════════════════════╝   ║    │
│  ║                                              ║    │
│  ╚══════════════════════════════════════════════╝    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**UX kritika:**
- `AlphaBlendValue = 180` → a form 30%-ban átlátszó, az alatta lévő háttér átütközik — ez nem szándékos design, hanem véletlen konfiguráció
- Az ELLENORPANEL `Visible=False`-szal indul — a felhasználó nem látja rögtön, mi fog történni
- A lépések (E1-E5) szekvencián belüli státuszjelzés csak a panel megjelenésekor látható
- Nincs haladásjelző (progress bar), nincs becsült idő
- A napzárás 14+ eljárásból áll, de ezek a felhasználó számára teljesen láthatatlanok

---

### 4.6 Bizonylat megjelenítő (BIZONYLATDISP)

**DFM adatok:**
- Méret: 1067×767px, `bsNone`
- Háttér: `clWhite`
- `blokkfejpanel`: 333×33px, `4210752` (sötétszürke), clYellow szöveg — "Blokk fejek"
- `BLOKKFEJRACS: TDBGrid` (Left=4, Top=40, W=325, H=641) — bal oldali lista
  - Oszlopok: BIZONYLATSZAM, DATUM, IDO, OSSZESFORINTERTEK (BLOKK FT), KEZELESIDIJ (KEZ-DIJ)
- Jobb oldal: részlet panel (nem teljes a DFM excerpt-ben, de következtethető)
- `Panel1`: "NAV NYUGTA" gomb (Color=7829367, Britannic Bold, fehér)

**Rekonstruált layout:**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ Blokk fejek                  │  [NAV NYUGTA]  │ [szűrő gombok] │ [akció panel]     │
│ (sötétszürke, sárga szöveg)  │                │                │                   │
│                              │                │                                     │
│ ┌──────────────────────────┐ │ ┌────────────────────────────────────────────────┐  │
│ │BIZONYLAT│DATUM │IDO │FT  │ │ │                                                │  │
│ │─────────┼──────┼────┼────│ │ │  BIZONYLAT RÉSZLETEI                          │  │
│ │00123456 │04-01 │09:15│125k│ │ │                                                │  │
│ │00123457 │04-01 │10:22│ 45k│ │ │  Típus:      Devizavásárlás                   │  │
│ │00123458 │04-01 │11:05│318k│ │ │  Devizanem:  EUR                              │  │
│ │00123459 │04-01 │11:47│ 82k│ │ │  Összeg:     320 EUR                          │  │
│ │00123460 │04-01 │12:30│201k│ │ │  Árfolyam:   395.50                           │  │
│ │         │      │    │    │ │ │  Kezelési díj: 500 Ft                          │  │
│ │         │      │    │    │ │ │  Fizetendő:  126 560 Ft                        │  │
│ │         │      │    │    │ │ │  Pénztáros:  KOVÁCS ANNA                       │  │
│ │         │      │    │    │ │ │  Ügyfél:     KISS BÉLA                         │  │
│ │         │      │    │    │ │ │                                                │  │
│ └──────────────────────────┘ │ │  [Újranyomtatás] [NAV Nyugta] [Sztornó]       │  │
│                              │ └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A bal oldali grid tömör, sűrű — az `OSSZESFORINTERTEK` és `KEZELESIDIJ` mezőneveket a fejléc felülírja, de az eredeti DB-mezőneveket megőrzi
- A szűrési lehetőségek (dátum, típus, pénztáros, ügyfél) vizuálisan nem kiemelkedők
- Nincs keresés mező — a TDBGrid görgetéssel navigálható
- Nem derül ki a DFM-ből, hogy van-e lapozás nagy adathalmaznál

---

### 4.7 Ügyfél bevitel (UGYFELINPUT)

**DFM adatok:**
- Méret: 781×820px (a legmagasabb form!), `bsNone`, `AlphaBlend = True`
- Háttér: `10526880` (ólomszürkéskék)
- Tartalmaz egy `VIRAG` nevű TImage-t (Left=-2200!) — off-screen, valószínűleg deaktiváltan maradt
- `NaturAdatok` és `JogiAdatok` — két váltható panel

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────────┐
│  ÜGYFÉL ADATBEVITEL                                                  │
│                                                                      │
│  [ Természetes személy ]   [ Jogi személy ]   ← TabControl          │
│                                                                      │
│  TERMÉSZETES SZEMÉLY:                                                │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Név:          [________________________]                       │  │
│  │  Anyja neve:   [________________________]                       │  │
│  │  Szül. hely:   [______________]  Dátum: [____.__.__]           │  │
│  │  Állampolgárság: [__________]                                   │  │
│  │  Lakcím:       [________________________]                       │  │
│  │                [________________________] (irányítószám/város)  │  │
│  │  Okmánytípus:  ( ) Személyi  ( ) Útlevél  ( ) Egyéb            │  │
│  │  Okmányszám:   [______________]  Lejárat: [____.__.__]         │  │
│  │  ( ) Belföldi  ( ) Külföldi                                     │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  JOGI SZEMÉLY:                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Cégnév:       [________________________]                       │  │
│  │  Székhely:     [________________________]                       │  │
│  │  Adószám:      [______________]                                 │  │
│  │  Cégforma:     [______________]   TEÁOR: [______]              │  │
│  │  Megbízott személy adatai (természetes személy panel)           │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│           [ MENTÉS — End ]              [ MÉGSEM — Escape ]         │
└──────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- `AlphaBlend = True` — nem látni a DFM-ben az AlphaBlendValue-t, ha 0 akkor teljesen átlátszó!
- A `VIRAG` TImage `Left=-2200`-nál van — ez szándékos off-screen elhelyezés (valószínűleg eltávolítottak egy háttérképet, de a komponens maradt)
- Az ügyfél-adatbeviteli form 820px magas — 1024×768-as képernyőn is alig fér el
- A 300.000 Ft feletti tranzakcióknál kötelező azonosítás, de nincs vizuális visszajelzés arról, hogy a küszöböt átléptük

---

### 4.8 Pénztáros belépés (PROSBELEP)

**DFM adatok:**
- Méret: 641×316px, `bsNone`, `AlphaBlendValue = 200`
- Háttér: `clBlack`
- `PENZTAROSLISTAPANEL` (Color=10066329): pénztáros lista grid
  - Shape6: lista keret (Left=32, Top=56, W=577, H=201, RoundRect)
  - Shape7: gomb keret (Left=240, Top=264, W=169, H=48, RoundRect)
- `BIZTOSPANEL` (Color=5592405): azonosítás megerősítés
  - ELSONEVPANEL: első megadott név megjelenítés
  - HASNEVPANEL: hasonló nevű személy megjelenítés
  - SAMEPERSONGOMB: "A KÉT NÉV UGYANAZ A SZEMÉLY"
  - MISTAKEGOMB: "ELTÉVESZTETTEM A JELÖLÉST"

**Rekonstruált layout — Login képernyő:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  (clBlack háttér, sötétkék panel)                                   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                                                                │  │
│  │  PÉNZTÁROS NEVE           │ KÓDJA │ ÁLLAPOT                   │  │
│  │  ─────────────────────────┼───────┼───────────────────────── │  │
│  │  KOVÁCS ANNA              │ KA01  │ szabad                    │  │
│  │  NAGY PÉTER               │ NP02  │ szabad                    │  │
│  │  HORVÁTH MÁRIA            │ HM03  │ elfoglalt                 │  │
│  │  TÓTH ZSOLT               │ TZ04  │ szabad                    │  │
│  │                                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                      │
│                    ┌─────────────────┐                               │
│                    │   BELÉPÉS       │                               │
│                    └─────────────────┘                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Rekonstruált layout — Dupla azonosítás megerősítés:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  (5592405 sötétkék panel)                                           │
│                                                                      │
│                   Biztos, hogy                                       │
│                                                                      │
│  KOVÁCSNÉ HERGERÖDER VILMALLE                                        │
│         (előző azonosítás neve)                                      │
│                                                                      │
│                      azonos                                          │
│                                                                      │
│  KOVÁCSNÉ H. ALADÁR LAJOSNÉ-VAL                                     │
│         (hasonló névminta a listából)                                │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │         [ A KÉT NÉV UGYANAZ A SZEMÉLY ]                     │    │
│  │         [ ELTÉVESZTETTEM A JELÖLÉST  ]                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- Az `AlphaBlendValue = 200` (~80% opák) → az alatta lévő tartalom látszik belőle — ez login képernyőn biztonsági kockázat (az előző session adatai látszanak)
- A duplaellenőrzési panel (BIZTOSPANEL) jó UX ötlet, de a szöveg ("A KÉT NÉV UGYANAZ A SZEMÉLY") nagybetűs, zord tónusú
- A pénztáros lista állapota (szabad/elfoglalt) jó funkció — megtartandó

---

### 4.9 Supervisor menü (SUPERVISORFORM)

**DFM adatok:**
- Méret: 610×418px, `bsNone`
- Háttér: `clGray`
- Panel1 (clBlack): teljes leftpanel
  - Shape1 (5592405 sötétkék, Left=160, W=377): a jobb oldali funkciók területe
  - Shape2 (10066329 sötétbarna, Left=24, W=329): a bal oldali gombterület
  - Label2: "SUPERVISOR MENÜJE" — Times New Roman 27pt Bold Italic, clYellow

**Gombok (bal oldali lista):**
1. XTRANZGOMB: "EXTRA TRANZAKCIÓS DÍJAK" (Left=40, Top=120)
2. BitBtn2: "CÍMLETEK BEÁLLÍTÁSA" (Top=152)
3. BitBtn1: "LOGFILE KIOLVASÁSA" (Top=184)
4. checklistgomb: "CHECKLISTA ELLENŐRZÉSE" (Top=248)
5. BitBtn4: "PÉNZTÁRI SZÜNETEK" (Top=280)
6. BitBtn3: "KILÉPÉS A SUPERVISORI MENÜBŐL" (Top=312)

**Rekonstruált layout:**

```
┌──────────────────────────────────────────────────────────────────┐
│  (clGray + clBlack panel)                                        │
│                                                                  │
│  SUPERVISOR MENÜJE                ┌──────────────────────────┐  │
│  (sárga, 27pt Times Bold Italic)  │                          │  │
│                                   │  [tartalom területe]     │  │
│  ╔════════════════════════════╗   │                          │  │
│  ║                            ║   │                          │  │
│  ║ [EXTRA TRANZAKCIÓS DÍJAK]  ║   │                          │  │
│  ║ [CÍMLETEK BEÁLLÍTÁSA    ]  ║   │                          │  │
│  ║ [LOGFILE KIOLVASÁSA     ]  ║   │                          │  │
│  ║ [CHECKLISTA ELLENŐRZÉSE ]  ║   │                          │  │
│  ║ [PÉNZTÁRI SZÜNETEK      ]  ║   │                          │  │
│  ║ [KILÉPÉS                ]  ║   │                          │  │
│  ║                            ║   │                          │  │
│  ╚════════════════════════════╝   └──────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- A supervisor menü 5+1 funkciót tartalmaz — ez elfogadható méret
- Azonban a "SZTORNÓ INDÍTÁSA" nincs itt (az a főmenüből elérhető, de supervisor jelszóval) — az architektúra nem egyértelmű
- A jobb oldali panel (Shape1) üres a DFM-ben — valószínűleg dinamikusan töltődik tartalommal

---

### 4.10 Foglalás (FOGLALO)

**DFM adatok:**
- Méret: 996×764px, `bsNone`
- Háttér: `clMedGray` + `Image1` teljes képernyős JPEG (tengerpart fotó, `alClient`)
- A TImage `alClient` → a háttérkép lefedi a teljes formot

**UX kritika:**
- A devizafoglalás — amely üzleti szempontból kritikus funkcionalitás — tengerpartot ábrázol háttérképként
- A háttérkép JPEG bele van kompilálva a DFM-be (a Picture.Data óriási base64 blob) → a DLL méretét drasztikusan megnöveli
- A `clMedGray` szürke színnel kombinálva a tengerpart fotó nagyon inkonzisztens üzleti megjelenést ad

---

### 4.11 Címletezés (CIMLETEZES)

**DFM adatok:**
- Méret: 1054×798px, `bsNone`
- Háttér: `11599871` (kékeszöld), `clMoneyGreen` keret, Pen.Width=5
- Shape1: jobb fele (Left=480, W=497, H=641) — a tényleges bejegyzési terület
- Shape2..Shape15: 14 soros, egyenként 35px magas deviza-sor (Left=488, W=160) — szélességük: 15% arányban
- KK1..KK15: bal oldali devizanem-jelölők (Left=408, W=26, H=24) — apró négyzetek

**Rekonstruált layout:**

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│  CIMLETEZES   (kékeszöld háttér, arany/moneygreen keret)                          │
│                                                                                   │
│  ╔═══════════════════════════════════════╗  ╔═══════════════════════════════════╗ │
│  ║                                       ║  ║  Devizanem │ 1  │ 2  │ 5  │ 10 │  ║ │
│  ║  [KK]  EUR  [bevitel mező]            ║  ║  ─────────────────────────────── ║ │
│  ║  [KK]  USD  [bevitel mező]            ║  ║  EUR  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  GBP  [bevitel mező]            ║  ║  USD  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  CHF  [bevitel mező]            ║  ║  GBP  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  CZK  [bevitel mező]            ║  ║  CHF  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  PLN  [bevitel mező]            ║  ║  CZK  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  ...  ...                       ║  ║  PLN  │[  ]│[  ]│[  ]│[  ]│    ║ │
│  ║  [KK]  ... (14 devizanem összesen)    ║  ║  ...  │    │    │    │    │    ║ │
│  ║                                       ║  ║       │    │    │    │    │    ║ │
│  ╚═══════════════════════════════════════╝  ╚═══════════════════════════════════╝ │
│                                                                                   │
│       [ MENTÉS ]               [ MÉGSE ]                                          │
└───────────────────────────────────────────────────────────────────────────────────┘
```

**UX kritika:**
- 14 devizanem × több títusi darabszám = nagyon sok mező egyszerre
- A KK1-KK15 komponensek (26×24px kis négyzetek) vizuálisan nehezen értelmezhetők
- A Shape2-Shape15 sorok egységes 35px magasak — ez nagyon tömör a szem számára

---

### 4.12 Bizonylat nyomtatás (BLOKKNYOM)

**DFM adatok:**
- Méret: 272×56px (!) — ez messze a legkisebb form
- Háttér: Shape1 `4539717` (sötétzöld), Pen.Width=3
- Label1: "Nyomtatás" — Times New Roman 32pt Bold Italic, clYellow

**UX értékelés:**
- Ez valójában nem egy valódi UI form, hanem egy átmeneti "nyomtatás folyamatban" indikátor
- A 272×56px-es mini-ablak a képernyő közepén megjelenik és eltűnik
- Semmiféle haladásjelzés, visszaszámlálás vagy állapotinformáció nincs rajta

---




<a name="03_DLL_KATALOGUS"></a>

# 3. DLL modul katalĂłgus

---


---

## S22 GPT_54_ELEMZĂSE


---

## S23 14_TEMATIKUS_DLL_LELTAR

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





---


---

## S24 JUNIOR_ELEMZĂSE


---

## S25 3_TELJES_DLL_MODUL_KATALOGUS_110_MODUL

### 3.1 Valutaváltó üzleti modulok

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **ELADAS** | TEladasForm | **Devizaeladás** — ügyfél devizát ad, pénztáros HUF-ot fizet |
| **VASARLAS** | TVasarlasForm | **Devizavásárlás** — ügyfél HUF-ot ad, devizát kap |
| **ARFVALT** | TARFOLYAMVALTOZTATAS | Árfolyam módosítás (supervisor engedéllyel) |
| **BIGARFVALT** | TForm2 | Nagy árfolyamváltás (speciális összeg felett) |
| **KISARFVALT** | TForm2 | Kis árfolyamváltás |
| **GETARF** | TGetArfolyam | Árfolyam lekérdezés |
| **SETRATE** | TSetRateType | Árfolyamtípus beállítás |
| **STORNO** | TSTORNOFORM | **Sztornó** — tranzakció érvénytelenítés (vétel, eladás, ügyfél, forráskód sztornó) |
| **XTRANZ** | TXTRANZFORM | Szabad tranzakció (egyéb ügylet) |
| **FOGLALO** | TFOGLALO | **Foglalás** — devizafoglalás ügyfélnek, későbbi kifizetés, időpont módosítás |
| **FOGLREND** | TRendeloForm | Foglalásos rendelés form |

### 3.2 Ügyfélkezelés és azonosítás

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **UGYFEL** | TUgyfelinput | **Ügyféladat-bevitel** — természetes és jogi személyek, azonosító okmányok |
| **UGYFELTMK** | TForm2 | Ügyfél-nyilvántartás (TMK adatok) |
| **KISUGYFEL** | TForm2 | Kis ügyfél (300k alatti, azonosítás nélküli) |
| **TERROR** | TTERROR | **Terrorizmus szűrés** — PEP/szankciós lista ellenőrzés, engedélyezés |
| **CONFIDEN** | TForm2 | Bizalmas adat kezelés |
| **SCANNING** | TForm2 | Dokumentum szkennelés |
| **UJSCANNER** | TForm2 | Új szkenner integráció |
| **SENDOKMANY** | TForm2 | Okmány elküldés |
| **TEAOR** | TForm2 | TEÁOR kód kezelés (cégek tevékenységi kódja) |

### 3.3 Pénztár és címletkezelés

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **CIMLET** | TCimletezes | **Címletezés** — deviza címletek bevétel/kiadás rögzítés |
| **CIMLMENU** | TCimletMenu | Címlet menü (pénztárzár címletes bontással) |
| **CIMLCTRL** | TCIMLETCONTROL | Címletellenőrzés |
| **CIMLNYOM** | TCIMLETNYOM | Címletlista nyomtatás |
| **CIMSETUP** | TCIMLETSETUPFORM | Címletbeállítás (supervisor) |
| **KCIMLET** | TForm2 | Címlet kalkulátor |
| **KISCIMLET** | TKISCIMLET | Kis címlet |
| **KELLCIM** | TKELLCIMLET | Szükséges címletek |

### 3.4 Bizonylatok és nyomtatás

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **BLOKNYOM** | TBlokkNyom | **Bizonylat nyomtatás** — vétel/eladás számla, sztornó blokk, reklám, ügyfélnyilatkozat, jogcím-nyilatkozat, közszereplő nyilatkozat, devizastátusz, címletnyomtatás |
| **BIZODISP** | TBIZONYLATDISP | Bizonylat-megjelenítés és keresés (dátum, típus, pénztáros, ügyfél) |
| **NZNYOMT** | TNapzarNyomtatoForm | Napzár nyomtatás |
| **GETNYUGT** | TGETNYUGTA | Nyugta lekérdezés |

### 3.5 Napi és időszaki műveletek

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **NAPIKEZD** | TNAPIKEZD | **Napi kezdet** — nyitó készlet, kezelési költség nyomtatás |
| **NAPZAR** | TNapzarForm | **Napzárás** — zárókészlet számítás, havi gyűjtőkbe másolás, címletátmásolás, WU MTCN ellenőrzés |
| **NAPKONYV** | Tdaybook | **Napi könyv** — naplóbejegyzések, forgalom, nyitó/záró készlet nyomtatás |
| **NAPIFORG** | TNAPIFORGALOMFORM | **Napi forgalom** — forgalomösszesítő, nyomtatás |
| **MAIFORG** | TMAIFORGALOMTABLAFORM | Mai forgalom táblázat |
| **NAPIJEL** | TNapiJelentes | Napi jelentés |
| **HAVIZAR** | THAVIZARAS | **Havi zárás** — havi forgalom gyűjtés, kezelési díj regenerálás, WU ÁFA forgalom, havi zárás nyomtatás |
| **REGIZARO** | TREGIZARASFORM | Régi zárás megtekintés |
| **DEKRUTIN** | TDekadRutin | Dekád rutin (tíznapos időszak) |
| **IDOSZAK** | THONAPKEROFORM | Időszak/hónap választó |
| **FORGOSSZ** | TVALUTAOSSZESITOFORM | Forgalom összesítő (keresett dátumra) |
| **NAVZARO** | TForm2 | NAV zárás / hatósági jelentés |
| **ESTIZAR** | TMakePack | Esti zárás / csomag készítés |

### 3.6 Készletkezelés

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **PTARKESZ** | TPTARKESZ | Pénztár készlet |
| **KESZUP** | TKESZLETBEKULDO | Készlet beküldő |
| **KESZEDIT** | TForm2 | Készlet szerkesztés |
| **PILLALL** | TPillanatnyiForm | Pillanatnyi állapot |
| **PILLKESZ** | TPillkeszForm | Pillanatnyi készlet |
| **KEZDEKAD** | TKEZDDEKAD | Kezdő dekád |
| **KEZDIJ** | TKDADVET | Kezelési díj/költség adatvétel |
| **KEZDKEDV** | TForm2 | Kezelési díj kedvezmény |

### 3.7 Átadás-átvétel

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **ATADOLAP** | TATADOLAPFORM | Átadólap (pénztárak közötti valutamozgás) |
| **ATADVET** | TAtadAtvetForm | Átadás-átvétel vétel |

### 3.8 Külső integrációk

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **WUNION** | TWesternUnionForm | **Western Union** — pénzátutalás küldés/fogadás, WU bizonylatok, MTCN kezelés |
| **OTP** | TOTPTERM | **OTP terminál** — POS terminál integráció (OTP bank) |
| **OTPLOG** | TForm2 | OTP terminál naplózás |
| **TERMINAL** | TTERMINALFORM | POS terminál általános |
| **TESCO** | TTESCOFORM | Tesco integráció |
| **METRO** | TMETROFORM | Metro integráció |
| **COPY2FTP** | TForm2 | **FTP szinkronizáció** — adatok feltöltése központi szerverre |
| **MENTES** | TNAPIMENTES | **Napi mentés** — Firebird .fdb mentés (teljes adatbázis másolás) |
| **VERZFRIS** | — | **Verziófrissítés** — automatikus DLL frissítés |

### 3.9 Adminisztráció és felügyelet

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **SUPER** | TForm2 | Supervisor jelszó ellenőrzés |
| **SUPERTSK** | TSUPERVISORFORM | **Supervisor feladatok** — sztornó indítás, címlet setup, dátum beállítás, logfile mentés, checklist, xtranz |
| **PROSBE** | TPROSBELEP | **Pénztáros belépés** — jelszóellenőrzés, ID kód választás, hardver adatok |
| **PROSKI** | TPROSKILEP | Pénztáros kilépés |
| **PROSTMK** | TPROSFORM | Pénztáros törzskarbantartás |
| **GEPSETUP** | TSETUPFORM | Gép/hardver beállítás |
| **OTHERTSK** | TEGYEBBEALLITASFORM | Egyéb beállítások |
| **CHECKLST** | TTASKCTRL | Ellenőrzési lista |
| **LOGIRO** | TForm2 | Naplóírás |
| **LOGDISP** | TForm2 | Naplómegjelenítés |
| **QUITFORM** | TQUITFORM | Kilépés megerősítés |

### 3.10 Listák és riportok

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **LISTAK** | TLISTAFORM | Listák (árlista, devizalista stb.) |
| **DOCDISP** | TForm2 | Dokumentum megjelenítés |
| **FNYUJSAG** | TFnyUjsag | Friss Nyomtatott Újság |
| **KORLEV** | TKORLEVEL | Körlevél |

### 3.11 Speciális és kiegészítő modulok

| DLL modul | Form neve | Funkció |
|-----------|-----------|---------|
| **_BASEDLL** | — | **Alap DLL** — közös könyvtár, utility függvények |
| **AFATABLA** | — | ÁFA tábla |
| **ARFDISP** | — | Árfolyam megjelenítés |
| **ARFREG** | — | Árfolyam regiszter |
| **ARFTMK** | — | Árfolyam-törzskarbantartás |
| **BIGCTRL** | TForm2 | Nagy összeg kontroll |
| **CONFIRM** | TCONFIRMFORM | Megerősítés |
| **EUAKCIO** | TForm2 | EU akció |
| **FIRSTCTRL** | TForm2 | Első indítás kontroll |
| **GETFIZE** | TGETFIZETOESZKOZ | Fizetőeszköz választás |
| **GETISO** | TForm2 | ISO kód lekérdezés |
| **GETPLOMB** | TGETPLOMBASZAM | Plombaszám lekérdezés |
| **GETPTAR** | TPenztarValasztoForm | Pénztár választás |
| **GETSTATUS** | TForm2 | Státusz lekérdezés |
| **GETWCEG** | TGETWCEG | WU cégnév lekérdezés |
| **GETWUGYF** | TGETWUGYF | WU ügyfél lekérdezés |
| **GONGBACK** | TForm2 | Visszajelzés |
| **HRKATADO** | TFORM2 | HRK (horvát kuna) átadó |
| **HRKZARO** | TForm2 | HRK zárás |
| **MAKTABLAK** | TForm2 | Matrica táblák |
| **MATPTAR** | TMatPenztar | Matrica pénztár |
| **MATREGEN** | TForm2 | Matrica regeneráló |
| **PAUSDISP** | — | Szünet kijelzés |
| **PROCEND** | TProcEndForm | Folyamat vége |
| **PTARTMK** | TPENZTARTMKFORM | Pénztár-törzskarbantartás |
| **QRDEPUTY** | TForm2 | QR kód helyettes |
| **QRGENER** | TForm2 | QR kód generátor |
| **REGEN** | TREGENERALO | Adatregeneráló |
| **SENDOKMANY** | TForm2 | Okmány küldés |

---



---


---

## S26 ESZTER_ELEMZĂSE


---

## S27 45_KESZLETKEZELES_ES_CIMLETEZES

### 4.5.1 Címletezés (CIMLET DLL)

A készlet nem csak összeg, hanem címlet szinten is nyilvántartott:

```pascal
// BLOKNYOM/Unit2.pas — CimletBedolgozas
// Bináris fájlból olvassa a címlet adatokat: c:\valuta\aktcim.dat
function TBlokkNyom.CimletBedolgozas: boolean;
begin
  Assignfile(_binolvas,_cimDataPath);
  Reset(_binolvas);
  Blockread(_binolvas,_bytetomb,1);
  _yValDarab := _byteTomb[1];   // Valutanemek száma
  
  while _cc<=_yValdarab do begin
    // 3 byte XOR-kódolt valutanév:
    _vnev := chr(255-_bytetomb[1])+chr(255-_bytetomb[2])+chr(255-_bytetomb[3]);
    _yNev[_cc] := _vNev;
    
    // Címletek száma:
    _vcdb := _bytetomb[1];
    _yCdb[_cc] := _vcdb;
    
    // Címlet-bankjegy párok:
    _p := 1;
    while _p<=_vcdb do begin
      _yC[_cc,_p] := getword;   // Címlet névérték
      _yB[_cc,_p] := getword;   // Bankjegy darabszám
      inc(_p);
    end;
  end;
end;
```

**Bináris címletfájl formátum (aktcim.dat):**
```
[1 byte: valutanemek száma]
  [3 byte: XOR-kódolt valutanév (255-karakter)]
  [1 byte: címletek száma]
    [2 byte: címlet névérték] [2 byte: darabszám]  × N
  [1 byte: 255 elválasztó]
[2 byte: 255+255 lezáró]
```

### 4.5.2 Készletátadás és plombaszám

Pénztárak közötti átadásnál `PLOMBASZAM` kötelező:

```pascal
// BLOKNYOM/Unit2.pas — AtadBlokkNyomtatas
writeLn(_LFile,'SZALLÍTÓ NEVE: ' + _szallitoNev);
writeLn(_LFile,'PLOMBA SZÁMA : ' + _plombaSzam);
```

A plombaszám a fizikai biztonsági lezárás azonosítója — a szállító dokumentum és a fizikai csomag összekapcsolására szolgál.

### 4.5.3 Napi bizonylat-regisztrálás

Minden tranzakció a VTEMP ideiglenes táblán keresztül kerül a havi BF/BT táblákba:

```pascal
// VASARLAS/Unit2.pas — Folytatas (~sor 1300)
BlokkFejIro;          // → BFyymm táblába
BlokktetelIro;        // → BTyymm táblába
KezdijRogzito;        // → KEZDyymm táblába
```



---


---

## S28 TAMAS_ELEMZĂSE


---

## S29 FUGGELEK_A_DLL_HIVASI_OSSZEFOGLALAS

### Hívási Lánc a Devizavásárlásban

```
TRADE.EXE
  └─► vasarlasrutin()          VASARLAS.DLL
        ├─► logirorutin()       LOGIRO.DLL
        ├─► ugyfelrutin()       UGYFEL.DLL
        │     └─► terrorcontrol()  TERROR.DLL
        │           └─► logirorutin()  LOGIRO.DLL
        ├─► bigarfolyamkedvezmeny() / kisarfolyamkedvezmeny()
        ├─► blokknyomtatas()    BLOKNYOM.DLL
        ├─► copyfiletoftprutin() COPY2FTP.DLL
        ├─► qrdisplayrutin()    QRGENER.DLL
        └─► regeneralorutin()   REGEN.DLL
```

### Hívási Lánc a Napzárásnál

```
TRADE.EXE
  └─► napzarrutin()            NAPZAR.DLL
        ├─► checkcontrol()      CHECKLST.DLL
        ├─► cimletmenurutin()   CIMLMENU.DLL
        ├─► cimletctrlrutin()   CIMLCTRL.DLL
        ├─► forgalomdekad()     DEKAD.DLL
        ├─► getellenorrutin()   GETELLEN.DLL
        ├─► kezelesidijdekad()  KEZDEK.DLL
        ├─► napijelrutin()      NAPIJEL.DLL
        ├─► napzarnyomtatorutin() NZNYOMT.DLL
        ├─► qrdisplayrutin()    QRGENER.DLL
        └─► regeneralorutin()   REGEN.DLL
```

---




<a name="04_UZLETI_LOGIKA"></a>

# 4. Ăśzleti logika Ă©s pĂ©nzĂĽgyi szabĂˇlyok

---


---

## S30 GPT_54_ELEMZĂSE


---

## S31 5_FO_UZLETI_FOLYAMATOK



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






---

## S32 6_PENZTAR_ERTEKTAR_FOERTEKTAR_LOGIKA



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





---


---

## S33 JUNIOR_ELEMZĂSE


---

## S34 4_UZLETI_LOGIKA_RESZLETES_ELEMZES

### 4.1 Devizavásárlás (VASARLAS DLL)

A `TVasarlasForm` kezeli a **devizavásárlás** teljes folyamatát:

1. **Árfolyam betöltés** — devizanemenkénti vételi/eladási árfolyam
2. **Bankjegy és darabszám bevitel** — WA1-WA6 (összegek), WB1-WB6 (bankjegyek), WD1-WD6 (darabszámok)
3. **Újraszámolás** — `Ujraszamolas` eljárás a HUF összeg kiszámításához
4. **Kezelési díj beépítés** — `KezdijBeepites` a díj hozzáadása
5. **Fizetendő kijelzés** — `FizetendoDisplay`
6. **Ügyfél azonosítás** — `UgyfdataVtempbol` (VTEMP tábla átmeneti adatai)
7. **XML generálás** — `MakeXml` (kupon API kommunikáció)
8. **Bizonylat regisztráció** — `Bizregiszter` az adatbázisba írás
9. **Remote lerendezés** — `RemoteLerendezes` (központi szerverre bejelentés)

Kulcs logika:
- **Limit kezelés**: beállítható napi limit (LimitBekeroPanel)
- **Kerekítés**: a forint összeg kerekítése szabályok szerint
- **Ezrelék díj**: jutalék/ezrelék kezelés (EzrelekPanel)
- **Árfolyam módosítás**: supervisor engedéllyel (ArfolyamGomb)
- **Konverzió**: nettó/bruttó átváltás (KonvSumPanel)

### 4.2 Devizaeladás (ELADAS DLL)

Az `TEladasForm` a devizaeladás kezelésére szolgál — tükörképe a vásárlásnak, de fordított irányban. Ugyanazok az input mezők (WA1-WA6, stb.), de az eladási árfolyammal számol.

### 4.3 Sztornó (STORNO DLL)

A `TSTORNOFORM` négy típusú sztornót kezel:

1. **Vétel sztornó** (VR radio) — devizavétel érvénytelenítés
2. **Eladás sztornó** (ER radio) — devizaeladás érvénytelenítés
3. **Ügyfél sztornó** (UR radio) — ügyfélrekord érvénytelenítés
4. **Forráskód sztornó** (FR radio) — forráskód érvénytelenítés

Folyamat:
1. Bizonylat kiválasztás gridből (`BizonylatRacs`)
2. Indoklás bekérés (`INDOKEDIT`)
3. Megerősítés (Igen/Nem gombok)
4. `Surestorno` — "biztosan sztornózza?" dupla megerősítés
5. `Ervenytelenites` — adatbázis szintű érvénytelenítés
6. `EllentranzAkcio` — ellentétes tranzakció rögzítése
7. `ValutaStorno` — valutakészlet visszaállítás
8. `GongyoletVissza` — göngylölet visszavezetés
9. OTP terminál sztornó (`OtpTermStorno`, `OtpAruVisszavet`)

### 4.4 Napzárás (NAPZAR DLL)

A `TNapzarForm` a napi zárás komplex folyamatát vezérli:

1. `NapzarControl` — ellenőrzés (van-e lezáratlan folyamat)
2. `UresPenztarControl` — üres pénztár ellenőrzés
3. `ZarobeolVasas` — záróadatok beolvasása
4. `NyitoMeghatarozas` — nyitókészlet meghatározás
5. `ForgalomBeolvasas` — napi forgalom összegyűjtés
6. `NapiForgalomSzamitas` — forgalom kiszámítás
7. `HavigyujtokbeMasolas` — havi gyűjtő táblákba másolás
8. `CimtarAtmasolas` — címtár átmásolás
9. `CimtipRogzito` — címlet típus rögzítés
10. `UgyfelNullazo` — ügyfélszámláló nullázás
11. `MTCNControl` — Western Union MTCN ellenőrzés
12. `NapzarFeltolt` — záróadatok feltöltés
13. `ZdatumsVtempbe` — záródátum a VTEMP táblába
14. `dekZarCtrl` — dekádzárlat ellenőrzés

### 4.5 Havi zárás (HAVIZAR DLL)

A `THAVIZARAS` a teljes havi zárást végzi:

1. `HaviForgalomGyujtes` — összes devizanem havi forgalma
2. `HaviKezdijRegeneralo` — kezelési díj újraszámolás
3. `GetElszamArfolyamok` — elszámolási árfolyamok
4. `WuAfaForgalom` — Western Union ÁFA forgalom
5. `HaviZarasNyomtatas` — nyomtatás:
   - Fejléc (cég, pénztár adatok)
   - Forgalomírás (devizanemenkénti bontás)
   - Forgalomösszesítés
   - Kezelési költség
   - Záró készlet
   - Western Union
   - ÁFA
   - Pénztár e-ker forgalom
   - Ügyfél forgalom

### 4.6 Foglalás (FOGLALO DLL)

A `TFOGLALO` devizafoglalást kezel:

1. `ValutanemBetoltes` — elérhető devizanemek betöltése
2. Ügyfél kiválasztás (meglévő vagy új)
3. `FoglaloRekordIras` — foglalás rögzítése adatbázisban
4. `EmailekKuldese` — értesítő e-mail
5. `FoglaloKifizetes` — foglalás kifizetése ha eljön az időpont
6. `MasidoPont` — időpont módosítás
7. `VisszaFizetoProcedura` — visszafizetés ha nem veszi át
8. Régi bizonylatok törlése (`RegiBizTorlese`)

---



---


---

## S35 ESZTER_ELEMZĂSE

# Anti Valutaváltó — Üzleti Logika és Minőségi Elemzés


# 1. PÉNZÜGYI ÜZLETI SZABÁLYOK




---

## S36 11_ARFOLYAM_KEZELES_ARCHITEKTURA

### 1.1.1 Árfolyam-adatmodell

A rendszer az `ARFOLYAM` táblában tárolja a devizanemenkénti árfolyamadatokat. Minden devizanemhez minimum 4 árfolyam tartozik:

```pascal
// VASARLAS/Unit2.pas — GetDnemAdatok függvény (sor 2544)
function TVasarlasForm.GetDnemAdatok(_zdnem: string): byte;
begin
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+_ZdNEM+chr(39);
  // ...
  with ValutaQuery do begin
    _aktdnev    := trim(FieldbyNAme('VALUTANEV').asString);
    _aktvarf    := FieldByNAme('VETELIARFOLYAM').asInteger;    // Vételi árfolyam
    _aktelszarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger; // Elszámolási árf.
    _aktshk     := FieldByName('SHKVETARFOLYAM').asInteger;    // SHK vételi árf.
    _aktZaro    := FieldByNAme('ZARO').asInteger;              // Záró készlet
  end;
end;
```

Az árfolyamtípusok:

| Mező | Név | Használat |
|------|-----|-----------|
| `VETELIARFOLYAM` | Vételi árfolyam | Devizavásárlás (ügyfél devizát ad) |
| `ELADASI` (implicit) | Eladási árfolyam | Devizaeladás (ügyfél devizát kap) |
| `ELSZAMOLASIARFOLYAM` | Elszámolási árfolyam | Belső elszámolás, havi zárás |
| `SHKVETARFOLYAM` | SHK vételi árfolyam | Saját hatáskörű kedvezményes árfolyam |

**Kritikus észrevétel:** A vételi és eladási árfolyam közti spread (marzs) a rendszer fő bevételi forrása. Az árfolyamok **integer** típusúak (fillér pontosság nélkül, 100-zal osztva használva), ami a JPY kezelésnél speciális logikát igényel.

### 1.1.2 Árfolyam kiválasztás — Vásárlás vs. Eladás

A vételi és eladási irány eltérő árfolyamot használ:

**Vásárlás** (VASARLAS DLL — ügyfél devizát hoz, pénztáros forintot fizet):
```pascal
// VASARLAS/Unit2.pas — DnemKeyDown (sor ~490)
_aktArfolyam            := _aktVarf;  // VÉTELI árfolyamot használja
_wArfolyam[_aktsor]     := _aktArfolyam;
_wOrigArfolyam[_aktsor] := _aktarfolyam;
_wElszamolasi[_aktsor]  := _aktElszarf;
```

**Eladás** (ELADAS DLL — ügyfél forintot hoz, devizát kap):
```pascal
// ELADAS/Unit2.pas — DnemKeyDown (sor ~520)
_aktArfolyam            := _aktEarf;  // ELADÁSI árfolyamot használja
_wArfolyam[_aktsor]     := _aktArfolyam;
_wOrigArfolyam[_aktsor] := _aktarfolyam;
_wElszamolasi[_aktsor]  := _aktElszarf;
```

### 1.1.3 Árfolyam-kedvezmény típusok

A rendszer háromszintű árfolyam-kedvezmény rendszert implementál:

**1. Kis árfolyamkedvezmény (KISARFVALT DLL)**
- Pénztáros saját hatáskörben adhatja
- F1 gombbal aktiválható
- A `kisarfolyamkedvezmeny` függvény hívása
- Visszatérési érték: `-1` = mégsem, `2` = SHK (saját hatáskörű) kedvezmény

```pascal
// VASARLAS/Unit2.pas — ArfolyamGombClick (sor ~927)
procedure TVasarlasForm.ArfolyamGombClick(Sender: TObject);
begin
  if _kezdijEngedmenyTip>0 then begin
    ShowMessage('KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !');
    exit;
  end;
  _arfback := kisarfolyamkedvezmeny;
  if _arfback = -1 then exit;
  if _arfback =  2 then _voltshk := True;
  Ujraszamolas;
end;
```

**2. Nagy árfolyamkedvezmény (BIGARFVALT DLL)**
- Értéktáros/supervisor szintű döntés
- Adott valutanem-re vonatkozik (a VTEMP `MEGJEGYZES` mezőbe `!` jelölés)
- Dupla kattintás vagy Enter az árfolyam mezőn

```pascal
// VASARLAS/Unit2.pas — ArfolyamotModosit (sor ~950)
procedure TVasarlasForm.ArfolyamotModosit;
begin
  if _sorEngedmeny[_aktSor]>0 then begin
    ShowMessage('Ez már módositott árfolyam !');
    exit;
  end;
  if _kezdijEngedmenyTip>0 then begin
    ShowMessage('KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !');
    exit;
  end;
  // Jelölés VTEMP-ben
  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'!'+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
  ValutaParancs(_pcs);
  // DLL hívás
  _arfback := bigarfolyamkedvezmeny;
  if _arfBack=-1 then exit;
  _voltkedvezmeny := True;
  Ujraszamolas;
end;
```

**3. Saját hatáskörű (SHK) kedvezmény**
- A pénztáros saját hatáskörben napi szinten korlátozott számú kedvezményt adhat
- `GetSajatHataskoru` lekérdezi a még rendelkezésre álló lehetőségek számát
- 5-ből visszafelé számol: `_mShk := 5 - _shk`

```pascal
// VASARLAS/Unit2.pas — FormActivate (sor ~418)
_shk  := GetSajatHataskoru;
_mShk := 5-_shk;
ShkPanel.Caption := inttostr(_mshk);
```

**Üzleti szabály — KIZÁRÓ LOGIKA:**
> Árfolyamkedvezmény ÉS kezelési díj kedvezmény egyszerre NEM adható. Ha már van kezelési díj engedmény (`_kezdijEngedmenyTip > 0`), az árfolyamkedvezmény gombok letiltásra kerülnek.

### 1.1.4 Árfolyam korlátozások devizanemenként

A rendszer devizanem-specifikus korlátozásokat tartalmaz:

```pascal
// VASARLAS — HUF nem vásárolható:
if _aktDnem='HUF' then begin
  ShowMessage('A FORINT NEM VÁLASZTHATÓ VALUTA');
  exit;
end;

// ELADAS — HUF nem eladható:
if _aktDnem='HUF' then begin
  ShowMessage('A FORINT NEM VÁLASZTHATÓ VALUTA');
  exit;
end;

// ELADAS — HRK (horvát kuna) nem eladható:
if _aktDnem='HRK' then begin
  ShowMessage('A KÚNA NEM VÁLASZTHATÓ VALUTA');
  exit;
end;

// ELADAS — Euro érme nem eladható:
if _aktDnem='EUA' then begin
  ShowMessage('EURO ÉRMÉT NEM ADUNK EL');
  exit;
end;

// ELADAS — Konverziónál azonos devizanem nem választható:
if (_ezkonverzio) AND (_aktdnem=_vetdnem) then begin
  Showmessage('AZONOS VALUTANEM NEM KONVERTÁLHATÓ !');
  exit;
end;
```

**Szankciós korlátozás — USD külföldi számára:**
```pascal
// BIGCTRL/Unit2.pas — UsdAdhato (sor 1315)
function TForm2.UsdAdhato: boolean;
begin
  result := true;
  // ... VTEMP-ből ellenőrzi van-e USD tétel ...
  if _recno=0 then exit;
  if (_iso<>'IR') and (_iso<>'KR') and (_iso<>'CU') and
     (_iso<>'SY') and (_iso<>'SS') then exit;
  showmessage('EBBEN AZ ORSZÁGBAN DOLLÁR NEM VÁLTHATÓ');
  result := False;
end;
```

Tiltott országok USD eladásnál: **IR** (Irán), **KR** (Észak-Korea), **CU** (Kuba), **SY** (Szíria), **SS** (Dél-Szudán).

---




---

## S37 12_FORINT_ERTEKSZAMITAS_ES_KEREKITES

### 1.2.1 Forintérték kalkuláció

Az egyes sorok forintértékének kiszámítása a devizanemtől függően:

```pascal
// VASARLAS/Unit2.pas — BankjegyKeyDown (sor ~600)
// Általános formula:
_aktErtek := round((_aktArfolyam/100*_aktBankjegy)+_rounder);

// JPY speciális kezelés (100-as egység):
if _aktDnem='JPY' then _aktertek := round(_aktertek/10);
```

**Matematikai modell:**
- **Általános:** `forintérték = round(árfolyam / 100 × bankjegy + 0.001)`
- **JPY:** `forintérték = round(round(árfolyam / 100 × bankjegy + 0.001) / 10)`

A `_rounder` változó (`0.001`) a kerekítési tűrés — megakadályozza a „banker's rounding" problémát, mindig felfelé kerekít `0.5`-nél.

### 1.2.2 Az 5 forintos kerekítés — Kerekito függvény

A magyar pénzforgalomban az 5 Ft-os kerekítés törvényi kötelezettség. A rendszer ezt implementálja:

```pascal
// VASARLAS/Unit2.pas (sor 2842)
function TVasarlasForm.kerekito(_int: integer): integer;
var _nums: string;
    _utdig,_wnums: Byte;
begin
  result := _int;
  _nums := inttostr(_int);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;    // utolsó számjegy
  if (_utdig<>0) and (_utdig<>5) then begin
    if (_utdig=1) or (_utdig=2) then result := _int-_utdig;     // lefelé 0-ra
    if (_utdig=6) or (_utdig=7) then result := _int-(_utdig-5);  // lefelé 5-re
    if (_utdig=3) or (_utdig=4) then result := _int+(5-_utdig);  // felfelé 5-re
    if (_utdig=8) or (_utdig=9) then result := _int+10-_utdig;   // felfelé 0-ra
  end;
end;
```

**Kerekítési táblázat:**

| Utolsó jegy | Irány | Eredmény | Példa |
|-------------|-------|----------|-------|
| 0 | — | Változatlan | 1230 → 1230 |
| 1 | ↓ | -1 → 0-ra | 1231 → 1230 |
| 2 | ↓ | -2 → 0-ra | 1232 → 1230 |
| 3 | ↑ | +2 → 5-re | 1233 → 1235 |
| 4 | ↑ | +1 → 5-re | 1234 → 1235 |
| 5 | — | Változatlan | 1235 → 1235 |
| 6 | ↓ | -1 → 5-re | 1236 → 1235 |
| 7 | ↓ | -2 → 5-re | 1237 → 1235 |
| 8 | ↑ | +2 → 0-ra | 1238 → 1240 |
| 9 | ↑ | +1 → 0-ra | 1239 → 1240 |

**Kritikus elemzés:**
- A kerekítés string-alapú (integer → string → utolsó karakter), ami nem hatékony, de hibamentes
- A kerekítés MINDIG az 5-ös és 0-ás jegyekhez konvergál, ami megfelel a 2008. évi LXVIII. tv. módosítása szerinti szabálynak
- Negatív számoknál HIBÁS lehet: ha `_int` negatív, az `inttostr` előjelet ír, és az utolsó karakter nem feltétlenül a szám utolsó jegye → **migrációs kockázat**

### 1.2.3 Fizetendő összeg kalkuláció

A teljes fizetendő összeg a nettó, kezelési díj és kerekítés eredménye:

```pascal
// VASARLAS/Unit2.pas — FizetendoDisplay (sor ~960)
procedure TVasarlasform.FizetendoDisplay;
begin
  _netto := 0;
  // Nettó összegzés:
  _z := 1;
  while _z<=_tetel do begin
    _netto := _netto + _wErtek[_z];
    inc(_z);
  end;

  // Kezelési díj kiszámítása:
  _origkezdij := Getkezelesidij(_netto);
  if _fixKezelesiDij=-1 then _kezelesidij := _origkezdij
  else _kezelesidij := _fixkezelesidij;
  if _kezelesidij<0 then _kezelesidij := 0;

  // VÁSÁRLÁSNÁL: bruttó = nettó - kezelési díj (levonás!)
  _brutto    := _netto - _kezelesiDij;
  _fizetendo := Kerekito(_brutto);
  _kerekites := _fizetendo-_brutto;

  // Készletellenőrzés:
  GetdnemAdatok('HUF');
  if _fizetendo>_aktzaro then begin
    ShowMessage('NINCS ENNYI FORINT KÉSZLETÜNK !');
    exit;
  end;
end;
```

**Üzleti formula (vásárlás):**
```
nettó       = Σ (soronkénti forintérték)
kezelési_díj = GetKezelesiDij(nettó)   [ha nincs fix díj]
bruttó      = nettó - kezelési_díj     [VÁSÁRLÁSNÁL: levonás]
fizetendő   = Kerekito(bruttó)         [5 Ft-os kerekítés]
kerekítés   = fizetendő - bruttó       [a kerekítés különbözete]
```

**Eladásnál a kezelési díj HOZZÁADÓDIK** a forint összeghez, amit az ügyfélnek fizetnie kell.

---




---

## S38 13_KEZELESI_DIJ_RENDSZER

### 1.3.1 Kezelési díj típusok

A rendszer háromféle kezelési díj módot támogat:

| `_realEzrelek` érték | Mód | Leírás |
|-----------------------|-----|--------|
| `> 0` | Ezrelék | A nettó összeg ezreléke |
| `= 0` | Nincs díj | Díjmentes tranzakció |
| `< 0` (= -1) | Sávos | Sávos díjtáblázat alapján |

A kijelzés is ennek megfelelő:
```pascal
// VASARLAS/Unit2.pas (sor ~430)
if _realEzrelek>0 then _tranzString := inttostr(_realEzrelek)+' %%';
if _realEzrelek=0 then _tranzString := 'nincs';
if _realEzrelek<0 then _tranzString := 'sávos';
```

### 1.3.2 Ezrelék-alapú kezelési díj

```pascal
// VASARLAS/Unit2.pas — GetKezelesidij (sor 1769)
function TVasarlasForm.GetKezelesidij(_ss: integer): integer;
begin
  result := 0;
  if _realezrelek=0 then exit;

  // Ezrelék mód:
  if (_realEzrelek>0) then begin
    result := Kerekito(trunc(_ss*_realEzrelek/1000));
    if result>_kezdijmax then Result := _kezdijmax;
    exit;
  end;

  // Sávos mód:
  _qq := 1;
  while _qq<=_maxsavdb do begin
    result := _kdij[_qq];
    if _ss<=_tranzsav[_qq] then exit;
    inc(_qq);
  end;
  result := _kezdijmax;
end;
```

**Ezrelék formula:**
```
kezelési_díj = Kerekito(trunc(nettó × ezrelek / 1000))
ha kezelési_díj > maximum → kezelési_díj = maximum
```

A kezelési díj is 5 Ft-ra kerekítődik!

### 1.3.3 Sávos kezelési díj tábla

A `TRANZDIJTABLA` adatbázistáblából töltődik be:

```pascal
// VASARLAS/Unit2.pas — KezdijTablaBeolvasas (sor 2436)
procedure TVasarlasForm.KezdijTablaBeolvasas;
begin
  _pcs := 'SELECT * FROM TRANZDIJTABLA ORDER BY SORSZAM';
  // ...
  while not ValutaQuery.eof do begin
    _srs := FieldByName('SORSZAM').asInteger;
    _trz := FieldByName('TRANZAKCIO').asInteger;    // sávhatár (Ft)
    _kzd := FieldByName('KEZELESIDIJ').asInteger;    // díj (Ft)

    if (_kzd=0) and (_srs>1) then _maxsavdb := _srs-1;
    if _srs<23 then begin
      _tranzsav[_srs] := _trz;
      _kdij[_srs] := _kzd;
    end else begin
      _kezdijmax := _kzd;  // 23. sor = maximum díj
      break;
    end;
  end;
end;
```

**Sávos díj adatstruktúra:**
- Maximum 22 sáv (`_tranzsav[1..22]` és `_kdij[1..22]`)
- A 23. sor tartalmazza a maximum díj plafont (`_kezdijmax`)
- A díj a legkisebb sávhatárnál áll meg, amelyik nagyobb vagy egyenlő a nettó összegnél

Az ELADAS modulban meglévő (kikommentezett) sávos díjtábla mutatja a korábbi fix díjstruktúrát:
```pascal
// ELADAS/Unit2.pas — GetTranzdij — kikommentezett fix sávok:
(*
  result := 50;  if _ss<2001 then exit;     // 0-2000 Ft → 50 Ft díj
  result := 100; if _ss<=10001 then exit;    // 2001-10000 → 100 Ft
  result := 120; if _ss<=20001 then exit;    // 10001-20000 → 120 Ft
  result := 150; if _ss<=30001 then exit;    // 20001-30000 → 150 Ft
  result := 200; if _ss<=50001 then exit;    // 30001-50000 → 200 Ft
  result := 250; if _ss<=60001 then exit;    // 50001-60000 → 250 Ft
  // ... egészen 10M Ft-ig: 2500 Ft
*)
```

### 1.3.4 Kezelési díj kedvezmény

A `KEZDKEDV` DLL kezeli a kezelési díj kedvezményt. Hat típust ismer:

```pascal
// VASARLAS/Unit2.pas — KezdijEngedmenyGombClick (sor ~1000)
_kezdijengedmenytip := kezdijkedvezmeny;
if _kezdijengedmenytip>0 then begin
  SzamlaAlaplap.Enabled       := False;  // Számla letiltva
  KezdijEngedmenyGomb.Enabled := False;  // Gomb letiltva
  // Beolvassa a fix kezelési díjat:
  _fixkezelesidij := FieldByNAme('KEZELESIDIJ').asInteger;
  _kartyaszam := trim(FieldByNAme('KARTYASZAM').asString);
  // Ha típus=6: egyedi kezelési díj
  if _kezdijengedmenytip=6 then _ezegyedikezdij := True;
end;
```

**Egyedi kezelési díj korlátozás:**
- Naponta maximum 3 egyedi kezelési díj kedvezmény adható
- A `NAPIEGYEDIKEZDIJ` mező a HARDWARE táblában számlálja

```pascal
// VASARLAS/Unit2.pas — Folytatas (sor ~1293)
if _ezEgyediKezdij then begin
  inc(_nEgykezdij);
  _pcs := 'UPDATE HARDWARE SET NAPIEGYEDIKEZDIJ='+inttostr(_negykezdij);
  ValutaParancs(_pcs);
  logirorutin(pchar('Egyedi kezdij lehetőség '+inttostr(3-_negykezdij)+' maradt'));
end;
```

### 1.3.5 Kezelési díj az ELADAS modulban — GetTranzdij vs GetKezelesidij

**Kritikus duplikáció!** Az ELADAS modulban KÉT kezelési díj függvény van:
- `GetKezelesidij` — azonos logika mint VASARLAS-ban
- `GetTranzdij` — kibővített verzió, ami figyelembe veszi a kedvezményt is

```pascal
// ELADAS/Unit2.pas — GetTranzdij (sor 1916)
function TeladasForm.GetTranzdij(_ss: integer): integer;
begin
  if _vanKezdijEngedmeny then begin
    result := _kezelesidij;  // Fix kedvezményes díj
    exit;
  end;
  // Ezután azonos az ezrelékes és sávos logika...
end;
```

---




---

## S39 14_KONVERZIO_DEVIZA_DEVIZA

A konverzió egy speciális kétlépéses tranzakció:

1. **Vásárlás**: ügyfél devizát ad → pénztáros forintot ad (de nem fizeti ki!)
2. **Eladás**: a forint értékből devizát kap → forint nem mozog fizikailag

```pascal
// VASARLAS/Unit2.pas — FormActivate
if _ezKonverzio then begin
  Konvcimpanel.Visible    := True;
  KonvsumPanel.Visible    := True;
  logirorutin(pchar('Ez konverziós vásárlás lesz'));
end;

// ELADAS/Unit2.pas — FormActivate — konverziós eladás:
if _ezKonverzio then begin
  logirorutin(pchar('Ez a konverziós vétel eladási része'));
  KonvCimPanel.Visible := True;
  KonvSumPanel.Visible := True;
  _limit  := _konvertIn;     // A beadott deviza forintértéke
  _maradt := _konvertIn;     // Ennyi Ft-nak megfelelő devizát kaphat
end;
```

A konverziónál:
- Az ügyfél-azonosítási küszöb a kombinált összeg: `_fizetendo := _fizetendo + _fizetendo` (kétszerezés)
- Azonos devizanem konverziója tiltott
- A `LIMIT` mező korlátozza, hogy az ügyfél pontosan annyi forintértékű devizát kapjon, amennyit beadott (mínusz díj)

```pascal
// ELADAS/Unit2.pas — az eladásnál limit-kezelés:
if _maradt>0 then begin
  // Automatikusan kiszámítja a maximális bankjegy mennyiséget:
  if _aktdnem<>'JPY' then 
    _bankjegy := trunc(100*_maradt/_aktArfolyam)
  else 
    _bankjegy := trunc(1000*_maradt/_aktArfolyam);
  _wb[_aktsor].Text := inttostr(_bankjegy);
end;
```

---




---

## S40 15_KESZLET_ELLENORZES

### 1.5.1 Valuta-készlet kontroll

Minden tranzakció előtt készlet-ellenőrzés történik:

**Vásárlásnál** (pénztáros forintot fizet):
```pascal
// VASARLAS/Unit2.pas — FizetendoDisplay
GetdnemAdatok('HUF');
if _fizetendo>_aktzaro then begin
  ShowMessage('NINCS ENNYI FORINT KÉSZLETÜNK !');
  exit;
end;
```

**Eladásnál** (pénztáros devizát ad):
```pascal
// ELADAS/Unit2.pas — BankjegyKeyDown
_found := GetDnemAdatok(_aktdnem);
// ...
if _aktbankjegy>_aktzaro then begin
  Showmessage('NINCS ENNYI ' + _aktdnem + ' BANKJEGYÜNK');
  _wb[_aktsor].text := '';
  exit;
end;
```

A készletadatok az `ARFOLYAM` tábla `ZARO` mezőjéből jönnek, ami a záró (aktuális) készletet tartalmazza.

### 1.5.2 Maximum 6 tétel per tranzakció

A rendszer maximum 6 sort (6 különböző devizanemet) enged egyetlen bizonylaton:

```pascal
// VASARLAS/Unit2.pas — BankjegyKeyDown
if _tetel=6 then exit;  // Ha betelt mind a 6 sor
```

Ez a `_wd[1..6]`, `_wa[1..6]`, `_wb[1..6]` tömbök méretéből ered — fix, nem konfigurálható korlát.

---



# 4. NAPI/HAVI ZÁRÁSI ÜZLETI FOLYAMATOK




---

## S41 71_MEGORZENDO_UZLETI_LOGIKA_MUST_KEEP

### 7.1.1 Kritikus algoritmusok — változatlan reprodukálandók

| # | Komponens | Forrás | Indoklás |
|---|-----------|--------|----------|
| 1 | **5 Ft-os kerekítés** | `Kerekito` | Törvényi kötelezettség, pénzügyi pontosság |
| 2 | **Kezelési díj kalkuláció** | `GetKezelesidij` | Bevételi modell, ügyfél-ígérvény |
| 3 | **Sávos díjtábla** | `KezdijTablaBeolvasas` + `TRANZDIJTABLA` | Üzleti konfiguráció |
| 4 | **Forintérték számítás** | `round(arf/100*bjgy+0.001)` + JPY | Pénzügyi pontosság |
| 5 | **Tranzakció-típus meghatározás** | `GetTranztip` | AML jogszabályi megfelelőség |
| 6 | **300k küszöb** | `securlevel` logika | Pmt. követelmény |
| 7 | **Ügyfél-egyeztetés** | `NaturUgyfelKereses` (4 mezőből 2) | Ügyfél-nyilvántartás integritás |
| 8 | **Bizonylat tartalom** | Minden `*Nyomtatas` eljárás | Jogi kötelezettség |
| 9 | **Negyedéves/éves kumuláció** | `GetQuoter` + `_evimax` | AML előírás |
| 10 | **Konverzió logika** | VASARLAS→ELADAS lánc | Üzleti funkció |

### 7.1.2 Üzleti szabályok — teljesen dokumentálandók és portálandók

```
PÉNZÜGYI:
  ├── Árfolyam-típusok (vételi, eladási, elszámolási, SHK)
  ├── Kezelési díj (ezrelékes + sávos + maximum plafon)
  ├── 5 Ft-os kerekítés algoritmusa
  ├── JPY speciális kezelés (/10)
  ├── Maximum 6 tétel per bizonylat
  ├── Árfolyam vs. kezelési díj kedvezmény kizáró logika
  ├── SHK napi korlát (5)
  ├── Egyedi kezdij napi korlát (3)
  └── Készletellenőrzés (HUF + deviza)

AML/KYC:
  ├── 3 szintű ügyfél-azonosítás (<100k / 100-300k / 300k+)
  ├── Jogi személy → mindig teljes azonosítás
  ├── Konverziónál összegduplázás
  ├── Heti kumuláció (7 napos ablak)
  ├── Negyedéves 4×25M szabály
  ├── Éves 2×8M szabály
  ├── PEP (közszereplő) kezelés
  ├── Terrorlista szűrés + engedélyezés + regisztráció
  ├── USD szankciós országok tiltás
  └── Forrás-megjelölési kötelezettség

BIZONYLAT:
  ├── Cégcsoport megkülönböztetés (pénztárkód alapján)
  ├── Kétnyelvű (HU/EN) formátum
  ├── ÁFA-mentesség szöveg
  ├── Jogcím nyilatkozat (300k+)
  ├── Közszereplő nyilatkozat
  ├── Forrás megjelölés
  ├── Ügyfél típusonkénti adatok (natur/jogi/kisügyfél)
  ├── Tulajdonos adatok (jogi személynél max 4)
  └── Másolat kezelés (indokkal)
```



---


---

## S42 GABOR_ELEMZĂSE


---

## S43 6_FELHASZNALOI_FOLYAMATOK_USER_FLOWS_ELEMZESE

### 6.1 Devizavásárlás teljes flow (as-is)

```
[Pénztáros bejelentkezik]
        ↓
[Főmenü megjelenik]
        ↓ (Lista és Zárás gomb → ZARAS.dll)
[Napi listák menü]
        ↓ (Új tranzakció → VASARLAS.dll)
[VASARLASFORM megjelenik]
        ↓
[Devizanem kiválasztás] ← ha ez nincs meg a form betöltésekor, prompt
        ↓
[WA1-WA6 összegek bevitele, WB1-WB6 bankjegyek, WD1-WD6 darabszámok]
        ↓ (Újraszámolás automatikusan)
[Fizetendő összeg megjelenik]
        ↓ (ha > 300 000 Ft)
[UGYFELINPUT megnyílik] ← kötelező azonosítás
        ↓
[Természetes/jogi személy adatok]
        ↓ (TERROR.dll)
[Terror szűrés ellenőrzés]
        ↓ (ha átment)
[BLOKNYOM.dll] ← bizonylat nyomtatás
        ↓
[VASARLASFORM bezárul]
        ↓
[Visszatér a Napi listák menübe]
```

**Teljes flow lépéseinek száma:** 10-15 lépés, ebből 4-6 különböző DLL-ablak
**Becsült idő normál esetben:** 2-4 perc/tranzakció
**Hibakezelési pontok:** Nincs visszavonás, nincs checkpoint

### 6.2 Modern devizavásárlás flow (to-be)

```
[Gyorsbillentyű: F1 = Vásárlás]
        ↓
[Egységes képernyő: devizanem + összeg + árfolyam]
        ↓ (auto-számítás gépelés közben)
[Limit ellenőrzés → banner megjelenik ha > 300k]
        ↓
[Ha szükséges: ügyfél-azonosítás inline panel kinyílik]
        ↓ (End/Enter)
[Megerősítés overlay]
        ↓ (Igen)
[Bizonylat nyomtatás auto + PDF mentés]
        ↓
[Visszatér az üres beviteli képernyőre]
```

**Lépéseinek száma:** 4-6 lépés
**Becsült idő:** 1-2 perc/tranzakció
**Hibakezelési pontok:** Undo az utolsó 30 másodpercben, auto-mentett draft

---

### 6.3 Napzárás flow (as-is)

```
[Supervisor engedélyezi a napzárást]
        ↓
[NAPZAR.dll ShowModal]
        ↓
[ELLENORPANEL felvillan (Visible→True)]
        ↓
[E1: MTCN ellenőrzés (async WU query)]
        ↓
[E2: Pénztárzárás címletezése (CIMLMENU.dll hívás)]
        ↓
[E3: Kezelési díj ellenőrzés]
        ↓
[E4: WU. címletezése]
        ↓
[E5: ÁFA pénztár címletezése]
        ↓
[Adatok feltöltés szerverre (COPY2FTP.dll)]
        ↓
[Nyomtatás (NZNYOMT.dll)]
```

**Probléma:** Ha az E1 MTCN ellenőrzés megakad (pl. WU szerver nem elérhető), az egész napzárás blokkolódik. Nincs "kihagyom ezt a lépést" opció, nincs részleges zárás.

---




<a name="05_AML_KYC"></a>

# 5. AML/KYC, ĂĽgyfĂ©lkezelĂ©s Ă©s compliance

---


---

## S44 GPT_54_ELEMZĂSE


---

## S45 11_UGYFEL_COMPLIANCE_ENGEDELYEZES



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





---


---

## S46 JUNIOR_ELEMZĂSE


---

## S47 6_UGYFELKEZELES_ES_AMLTMK

### 6.1 Ügyfél bevitel (UGYFEL DLL)

A `TUgyfelinput` kétféle ügyfelet kezel:

**Természetes személy** (NaturAdatok):
- Név, anyja neve
- Születési hely, dátum
- Állampolgárság, lakcím
- Okmánytípus (személyi, útlevél stb.)
- Okmányszám, lejárat
- Belföldi / Külföldi megkülönböztetés

**Jogi személy** (JogiAdatok):
- Cégnév
- Székhely
- Adószám
- Cégforma
- TEÁOR kód
- Megbízott természetes személy adatai

### 6.2 Terrorizmus szűrés (TERROR DLL)

A `TTERROR` modul:
- Betű-kiemeléssel (`Betukiemelo`) hasonlítja az ügyfélnevet a szankciós listához
- Engedélyezési folyamat: az engedélyező személy kódjával
- Regisztráció: ha a szűrés pozitív, a tranzakció regisztrálódik

### 6.3 Közszereplő (PEP) nyilatkozat

A `KozszerepNyilatkozat` a politikai közszereplők nyilatkozatát nyomtatja — ez jogszabályi kötelezettség 300.000 Ft feletti tranzakcióknál.

---



---


---

## S48 ESZTER_ELEMZĂSE

# 2. AML/KYC SZABÁLYOK




---

## S49 21_UGYFEL_AZONOSITASI_KUSZOBOK

### 2.1.1 Háromszintű azonosítási rendszer

A rendszer három szintet különböztet meg az összeg alapján:

```pascal
// UGYFEL/Unit2.pas — FormActivate (sor ~540)
_securlevel := 0;
if _konverzio=1 then _fizetendo := _fizetendo + _fizetendo; // Konverziónál duplázás!

if _fizetendo>=100000 then 
  NemAzonositoGomb.Enabled := False;  // 100k felett: kötelező legalább kisügyfél

if (_fizetendo>=300000) then begin
  _securlevel := 1;
  _kotelezo   := True;
  Kisugyfelgomb.Enabled := False;     // 300k felett: TELJES azonosítás kötelező
end;
```

| Összeg | Szint | Azonosítás | Lehetőségek |
|--------|-------|------------|-------------|
| < 100.000 Ft | 0 | Nem kötelező | Azonosítás / Kisügyfél / Nem azonosít |
| 100.000 – 299.999 Ft | 0 | Részben kötelező | Azonosítás / Kisügyfél (nem azonosít letiltva) |
| ≥ 300.000 Ft | 1 (securlevel) | Teljes azonosítás | Kizárólag teljes azonosítás |

### 2.1.2 Kisügyfél rendszer

A 100.000–300.000 Ft közötti sávban használható „kisügyfél" mechanizmus:

- A `KISUGYFEL` DLL kezeli
- Minimális adatrögzítés (név, nem feltétlenül okmány)
- A `kisugyfel.fdb` szerveren tárolt adatbázisban keresés
- Input/output VTEMP-en keresztül

Visszatérési kódok:
```
-1 = Tranzakció STOP ! Nem folytatható !
 1 = Kisügyfél rögzítve (adatok VTEMP-ben)
 2 = Kötelező a teljes azonosítás
 3 = Nincs internet vagy szerverkapcsolat vagy 100ezer alatt
```

Ha a kisügyfél-rutin `2`-vel tér vissza (teljes azonosítás szükséges):
```pascal
// UGYFEL/Unit2.pas — KisugyfelGombClick
if _mresult=2 then begin
  _mess := 'Kisügyfélrutin üzeni -> teljes azonosítás szükséges';
  _securlevel := 1;
  _kotelezo := True;
  Azonositogombclick(Nil);  // Automatikusan teljes azonosítás
end;
```

### 2.1.3 Jogi személy — mindig teljes azonosítás

```pascal
// UGYFEL/Unit2.pas — JogiRadioClick
procedure TUgyfelinput.JOGIRADIOClick(Sender: TObject);
begin
  _kotelezo := true;
  _securlevel := 1;
  _pcs := 'UPDATE VTEMP SET SECURLEVEL=1';
  ValutaParancs(_pcs);
  Kisugyfelgomb.Enabled := False;
end;
```

Jogi személyek esetén **MINDIG** `securlevel=1` → teljes azonosítás kötelező, összeghatártól függetlenül.




---

## S50 22_TERMESZETES_SZEMELY_AZONOSITAS

### 2.2.1 Rögzített adatmezők

A természetes személynél az alábbi adatok kerülnek rögzítésre:

```pascal
// UGYFEL/Unit2.pas — deklarációk
_nev, _elozo, _leany, _anyja: string;        // Nevek
_szulhely, _szulido: string;                   // Születési adatok
_irszam, _varos, _utca, _lakcim: string;      // Lakcím
_azonosito, _okmanytipus: string;              // Okmány
_allampolgar, _tarthely: string;               // Állampolgárság, tartózkodási hely
_iso: string;                                   // Országkód
_kulfoldi: byte;                               // Belföldi/külföldi flag
_kozszereplo: byte;                            // Közszereplő flag
_lakcimcard: string;                           // Lakcímkártya szám
```

Okmánytípusok (fix tömb):
```pascal
_okmtiptomb: array[0..2] of string = ('SZIG','JOGOSITVANY','UTLEVEL');
```

### 2.2.2 Ügyfél-keresés a központi szerveren

A `BIGCTRL` DLL a központi szerveren (`UGYFELYY.FDB`) keresi az ügyfelet:

```pascal
// BIGCTRL/Unit2.pas — NaturUgyfelKereses (sor 408)
function TForm2.NaturUgyfelKereses: integer;
begin
  // Névtábla meghatározása a kezdőbetű alapján:
  _kezdoBetu := leftstr(_ugyfelnev,1);
  _nevtabla  := _kezdoBetu + 'NEV';     // pl. 'ANEV', 'BNEV', ...
  _biztabla  := _kezdobetu + 'BIZ';     // pl. 'ABIZ', 'BBIZ', ...
  
  // Keresés NÉV alapján:
  _pcs := 'SELECT * FROM ' + _nevtabla +
    ' WHERE NEV=' + chr(39) + _ugyfelnev + chr(39);
  
  // Ha találat van — 4 adatból 2 egyezés kell:
  while not RemoteQuery.eof do begin
    _rAnyjaneve     := trim(RemoteQuery.fieldByNAme('ANYJANEVE').asString);
    _rSzuletesihely := trim(Remotequery.FieldByNAme('SZULETESIHELY').asString);
    _rSzuletesiido  := trim(RemoteQuery.FieldByNAme('SZULETESIIDO').asString);
    _rAzonosito     := trim(RemoteQuery.FieldByNAme('AZONOSITO').AsString);
    
    _pont := 0;
    if _ranyjaneve=_anyjaneve then _pont := 1;
    if _rszuletesiido=_szuletesiido then inc(_pont);
    if _rszuletesihely=_szuletesihely then inc(_pont);
    if _razonosito=_azonosito then inc(_pont);
    
    if _pont>1 then begin   // 2+ egyezés = azonosítva
      _megvan := True;
      break;
    end;
    RemoteQuery.next;
  end;
end;
```

**Azonosítási algoritmus — 4 mezőből 2 egyezés:**
1. Anyja neve
2. Születési idő
3. Születési hely
4. Okmányszám

Ha legalább 2 egyezik → az ügyfél azonosítva van.

**Kockázat:** Ez a fuzzy matching hibás pozitívot adhat (két különböző ember azonos névre + 2 egyező adatra), és hamis negatívot is (elgépelt anyja neve + eltérő okmány → új ügyfél létrehozása).

### 2.2.3 Névtábla rendszer

Az ügyfélnyilvántartás a szerveren **betűnkénti névtáblákba** szervezett:

```
ANEV, ABIZ — 'A'-val kezdődő ügyfélnevek
BNEV, BBIZ — 'B'-vel kezdődő ügyfélnevek
...
ZNEV, ZBIZ — 'Z'-vel kezdődő ügyfélnevek
JOGI, JOGIBIZ — Jogi személyek
```

A `NEVTABLA` a keresés/regisztrálás helye, a `BIZTABLA` a bizonylat-nyilvántartás.

### 2.2.4 Ügyfél-tiltás

A szerveren `TILTVA` mező jelöli a tiltott ügyfeleket:

```pascal
// BIGCTRL/Unit2.pas — NaturUgyfelKereses
if _tiltva=1 then begin
  ShowMessage('AZ ÜGYFÉL LE VAN TILTVA !');
  result := -1;
  exit;
end;

if _tiltva=2 then begin
  ShowMessage('AZ ÜGYFÉL CSAK FORRÁS MEGJELÖLÉSSEL VÁLTHAT !');
  _spk := supervisorjelszo(0);
  if _spk=1 then result :=1 else result := -1;
  exit;
end;
```

| `TILTVA` | Jelentés | Művelet |
|----------|----------|---------|
| 0 | Normál | Nincs korlátozás |
| 1 | Tiltott | Tranzakció NEM engedélyezhető |
| 2 | Forrás szükséges | Supervisor jelszóval + forrás megjelöléssel válthat |




---

## S51 23_JOGI_SZEMELY_AZONOSITAS

### 2.3.1 Jogi személy adatmezők

```pascal
// UGYFEL/Unit2.pas — jogi személyes változók
_jNev: string;          // Jogiszemély neve
_jTelephely: string;    // Telephely címe
_jOkirat: string;       // Okirat száma
_jAdoszam: string;      // Adószám
_jKepvisnev: string;    // Képviselő neve
_jTeaor: string;        // TEÁOR kód
_jOrszag: string;       // Ország
_jIso: string;          // ISO kód
```

### 2.3.2 Jogi személy keresés

```pascal
// BIGCTRL/Unit2.pas — JogiUgyfelKereses (sor 612)
function TForm2.JogiUgyfelKereses: integer;
begin
  _nevtabla := 'JOGI';
  _BIZTABLA := 'JOGIBIZ';
  
  // A jogiszemélynév első 7 karaktere alapján:
  _jugynev := leftstr(_jogiugyfelnev,7);
  _pcs := 'SELECT * FROM JOGI WHERE JOGISZEMELYNEV LIKE ' + 
    chr(39) + _Jugynev +'%'+ chr(39);
  
  // Egyeztetés: telephelycím + okiratszám
  while not RemoteQuery.eof do begin
    _rThcim := trim(RemoteQuery.FieldByNAme('TELEPHELYCIM').asString);
    _rokir  := trim(RemoteQuery.FieldByName('OKIRATSZAM').AsString);
    _rThCim := leftstr(withoutIrszam(_rThCim),7);
    _rOkir  := withoutLetter(_rOkir);
    
    IF _rthCim=_jTelep then _found := 1;
    if _rokir=_jOkirat then inc(_found);
    
    if _found>0 then begin    // 1+ egyezés = azonosítva
      _megvan := true;
      break;
    end;
  end;
end;
```

**Jogi személy azonosítás algoritmusa:**
- Név: első 7 karakter LIKE keresés
- Cím: irányítószám nélkül, első 7 karakter
- Okirat: betűk nélkül (csak számok)
- **1 egyezés elég** (szemben a természetes személy 2-es küszöbével)

### 2.3.3 Tényleges tulajdonosok (Beneficial Owners)

Jogi személyek esetén a tényleges tulajdonosok (max. 4) is rögzítésre kerülnek:

```pascal
// UGYFEL/Unit2.pas — tulajdonos változók
_tulajnevedit  : array[1..4] of TEdit;
_ttKozszereplo : array[1..4] of byte;
_ttNev, _ttElozonev, _tTlakcim: array[1..4] of string;
_ttSzulhely, _ttSzulido: array[1..4] of string;
_ttAllampolgar, _ttTarthely: array[1..4] of string;
_tTerdJelleg, _ttErdMertek: array[1..4] of string;  // Érdekeltség jellege, mértéke
```

A bizonylaton megjelenő adatok:
```pascal
// BLOKNYOM/Unit2.pas — Ugyfelnyomtatas
writeLn(_lFile,'Tényleges tulajdonosok adatai:');
while _qq<=_tuldarab do begin
  writeLn(_lFile,_tnev[_qq]);        // Tulajdonos neve
  writeLn(_lFile,_tcim[_qq]);        // Címe
  writeLn(_lFile,_tszuldata[_qq]);   // Születési hely + idő
  writeLn(_lFile,_tallamp[_qq]);     // Állampolgárság
  writeLn(_lFile,_ttarthely[_qq]);   // Tartózkodási hely
  writeLn(_lFile,_tjelleg[_qq]);     // Érdekeltség jellege
  writeLn(_lFile,_tmertek[_qq]);     // Érdekeltség mértéke
  // Közszereplő státusz:
  if _tk=0 then writeLn('Nem közszereplő')
  else writeLn('A tulaj közszereplő');
end;
```




---

## S52 24_TERRORIZMUS_SZURES

### 2.4.1 Terrorlista ellenőrzés (TERROR DLL)

```pascal
// TERROR/Unit2.pas — a szűrés folyamata

// 1. Betűkiemelés — csak nagybetűk maradnak:
function TTerror.Betukiemelo(_s: string): string;
var _ws,_pp,_betu: byte;
begin
  _s := trim(_s);
  _ws := length(_s);
  result := '';
  _pp := 1;
  while _pp<=_ws do begin
    _betu := ord(_s[_pp]);
    if (_betu>64) and (_betu<91) then result := result + chr(_betu);
    inc(_pp);
  end;
end;
```

A szűrés folyamata:
1. Az ügyfél neve betűkiemelésre kerül (csak A-Z nagybetűk maradnak)
2. Összehasonlítás a terrorlistával
3. Találat esetén a pénztáros dönthet: **STOP** (tiltás) vagy **ENGEDÉLYEZÉS** (supervisor)

### 2.4.2 Engedélyezési folyamat

```pascal
// TERROR/Unit2.pas — StopGombClick
procedure TTERROR.STOPGOMBClick(Sender: TObject);
begin
  logirorutin(pchar('A terrorlistán szereplés miatt a tranzakció letiltva !'));
  Regisztracio;
  _mResult := -1;
end;

// TERROR/Unit2.pas — EngedelyezoGombClick
procedure TTERROR.ENGEDELYEZOGOMBClick(Sender: TObject);
begin
  _engedelyezve := 'IGEN';
  logirorutin(pchar('A terrorlista ellenére engedélyezték a tranzakciót'));
  logirorutin(pchar('Engedélyező: ' + _engedelyezo));
  regisztracio;
  _mResult := 1;
end;
```

### 2.4.3 Terror-regisztráció

Minden terrorlista-találat — akár engedélyezett, akár tiltott — regisztrálódik a JOURNAL táblába:

```pascal
// TERROR/Unit2.pas — Regisztracio
procedure TTerror.Regisztracio;
begin
  _pcs := 'INSERT INTO JOURNAL (DATUM,IDO,PENZTARKOD,PENZTARNEV,' +
    'UGYFELNEV,ENGEDELYEZVE,ENGEDELYEZO) VALUES (...)';
  // remoteDbase → szerverre ír!
end;
```




---

## S53 25_TRANZAKCIO_TIPUS_MEGHATAROZAS_AML_GYANUS_MINTAZATOK

### 2.5.1 GetTranztip — a gyanús tranzakciók kategorizálása

A `BIGCTRL` DLL `GetTranztip` függvénye osztályozza a tranzakciókat:

```pascal
// BIGCTRL/Unit2.pas — GetTranztip (sor 1260)
function TForm2.GetTranztip: integer;
var _hasforint, _diff: integer;
begin
  _hasforint := _virtualFizetendo;
  _diff := Napidiff(_lastdatum,_megnyitottnap);
  if _diff<8 then _hasforint := _hasforint + _hetiforint;  // Heti kumuláció!
  
  // 6: 50 millió Ft felett
  result := 6;
  if _hasforint>=50000000 then exit;
  
  // 5: 10 millió Ft felett
  result := 5;
  if _hasforint>=10000000 then exit;
  
  // 4: Negyedév alatt 4× 25 millió felett
  result := 4;
  if (_tranzdarab=4) then begin
    _negyedevFt := Getquoter;
    if _negyedevft>=25000000 then exit;
  end;
  
  // 3: 2× éven belül 8 millió felett
  result := 3;
  if (_evimax>=8000000) and (_hasforint>=8000000) then exit;
  
  // 2: Külföldi (kockázatos)
  result := 2;
  if _kulfoldi=1 then begin
    if not usdadhato then result := -1;  // Szankcionált ország → teljes tiltás
    exit;
  end;
  
  // 1: Belföldi közszereplő
  result := 1;
  if _rKozszerep=1 then exit;
  
  // 0: Nincs korlát
  result := 0;
end;
```

**Tranzakció-típus táblázat:**

| Kód | Feltétel | Jelentés | Szükséges engedély |
|-----|----------|----------|---------------------|
| 0 | Minden más | Normál — nincs korlátozás | Nincs |
| 1 | Közszereplő (PEP) | Kiemelt közszereplő | Engedélyezés szükséges |
| 2 | Külföldi | Kérdőjeles nemzetiségű külföldi | Engedélyezés szükséges |
| 3 | 2× 8M Ft éven belül | Ismételt nagy összegű tranzakció | Engedélyezés szükséges |
| 4 | 4× 25M Ft negyedévben | Strukturált tranzakciók gyanúja | Engedélyezés szükséges |
| 5 | ≥ 10M Ft | Nagy összegű tranzakció | Engedélyezés szükséges |
| 6 | ≥ 50M Ft | Kiemelt nagy összegű | Engedélyezés szükséges |
| -1 | Szankcionált ország + USD | Tiltott | Tranzakció nem végezhető |

### 2.5.2 Heti kumuláció

A rendszer 7 napos csúszóablakot alkalmaz:
```pascal
_diff := Napidiff(_lastdatum,_megnyitottnap);
if _diff<8 then _hasforint := _hasforint + _hetiforint;
```

Ha az utolsó tranzakció 7 napon belül volt, a heti összeget hozzáadja az aktuális összeghez → kumulált ellenőrzés.

### 2.5.3 Negyedéves ellenőrzés

A `GetQuoter` függvény a negyedéves forgalmat számolja ki a bizonylattáblából:

```pascal
// BIGCTRL/Unit2.pas — GetQuoter (sor 1341)
function TForm2.GetQuoter: integer;
begin
  result := 0;
  // A negyedév kezdő hónapjának meghatározása:
  _nyev := trunc((_aktho-1)/3);
  _tho := 1+trunc(_nyev*3);
  _iho := _tho + 3;
  _tol := leftstr(_megnyitottnap,5)+nulele(_tho)+'.01';
  _ig  := leftstr(_tol,5)+nulele(_iho)+'.01';
  
  // Szerveren a BIZTABLA-ból lekérdezi a negyedéves forgalmat:
  _pcs := 'SELECT * FROM ' + _biztabla +
    ' WHERE (SORSZAM='+inttostr(_sorszam)+') AND (' +
    'DATUM>='''+_tol+''') AND (DATUM<='''+_ig+''')';
  
  while not RemoteQuery.eof do begin
    _aktft := RemoteQuery.FieldByNAme('FIZETENDO').asInteger;
    result := result + _aktft;
    Remotequery.next;
  end;
end;
```




---

## S54 26_PEP_KOZSZEREPLO_KEZELES

### 2.6.1 Közszereplő nyilatkozat

A bizonylaton kötelezően megjelenik a közszereplő státusz:

```pascal
// BLOKNYOM/Unit2.pas — KozszerepNyilatkozat
procedure TBlokkNyom.KozszerepNyilatkozat(_ksz: integer);
begin
  if _ksz=0 then writeLn('Nem közszereplő')
  else writeLn('Az ügyfél kiemelt közszereplő');
end;
```

### 2.6.2 Kiemelt státusz lekérdezés

A `GETSTATUS` DLL (`getkiemeltstatusz`) a központi szerveren ellenőrzi az ügyfél kiemelt státuszát.




---

## S55 27_FORRAS_MEGJELOLES

300.000 Ft feletti tranzakcióknál (`securlevel=1`) a bizonylaton a pénzeszköz forrása is megjelenik:

```pascal
// BLOKNYOM/Unit2.pas — Jogcimnyilatkozat
if _forras<>'' then
  writeLn(_LFile,'Pénzeszközöm forrása: '+ _forras);
```

Az `_engedelyezo` mező tartalmazza az engedélyező személy nevét, aki a felettes/supervisor szinten jóváhagyta a tranzakciót.



---


---

## S56 TAMAS_ELEMZĂSE


---

## S57 4_ALLAPOTKEZELES_ES_ADATARAMLAS

### 4.1 VTEMP — A Rendszer „Üzenőfala"

A VTEMP (Value TEMP) tábla egy egyedi inter-process communication megoldás. Ez nem valódi IPC — hanem egy adatbázis táblán keresztüli adatcsere szimulációja. A DLL-ek között nincs közvetlen memória-megosztás (shared memory), nincs Named Pipe, nincs COM/DCOM — kizárólag VTEMP.

#### 4.1.1 VTEMP Életciklus

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         VTEMP ÉLETCIKLUS                                │
│                                                                         │
│  1. TÖRLÉS (bármelyik DLL start előtt)                                  │
│     'DELETE FROM VTEMP'                                                 │
│                                                                         │
│  2. FELTÖLTÉS (hívó DLL)                                                │
│     INSERT INTO VTEMP (UGYFELNEV, ...) VALUES (...)                     │
│                                                                         │
│  3. FELDOLGOZÁS (hívott DLL)                                            │
│     SELECT * FROM VTEMP → beolvassa az adatokat                        │
│     → elvégzi a munkát                                                  │
│     → visszaír VTEMP-be (UPDATE/INSERT)                                │
│                                                                         │
│  4. EREDMÉNY OLVASÁS (hívó DLL)                                         │
│     SELECT * FROM VTEMP → eredmény visszaolvasása                      │
│                                                                         │
│  5. TÖRLÉS (következő ciklusra)                                         │
│     'DELETE FROM VTEMP'                                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 4.1.2 VTEMP Adatáramlás — Vasárlás Példa

```pascal
// 1. VASARLAS.DLL: VTEMP törlés induláskor
ValutaParancs('DELETE FROM VTEMP');

// 2. VASARLAS.DLL: Ügyfél adatok írása VTEMP-be
procedure TVasarlasForm.SorBeirasVTempbe(_y: byte);
// INSERT INTO VTEMP (VALUTANEM, ARFOLYAM, BANKJEGY, FORINTERTEK, ELOJEL)
// VALUES (...) — devizasoronként

// 3. VASARLAS.DLL: BIGCTRL.DLL hívása VTEMP-en keresztül
// BIGCTRL bement: ugyfeltipus, ugyfelszam, fizetendo, konverzio, bizonylatszam
// BIGCTRL kimenet: gongyolt, sorszam, nevtabla, forras, engedelyezo, plombaszam

// 4. VASARLAS.DLL: VTEMP-ből visszaolvasás
procedure TVasarlasForm.UgyfdataVtempbol;
// SELECT * FROM VTEMP → ügyfél adatok, sorszám, plombaszám

// 5. VASARLAS.DLL: bizonylat nyomtatáshoz BLOKNYOM.DLL hívás
// BLOKNYOM a VTEMP-ből olvassa a nyomtatáshoz szükséges adatokat
```

#### 4.1.3 VTEMP Speciális Rekordtípusok (NEVTABLA mező)

```
NEVTABLA érték   → Jelentés
─────────────────────────────────────────
'NAPI'           → Napi mentés rekord
'ZARDATUM'       → Napzárás dátuma
'KONV'           → Konverziós tranzakció
'UGYFEL'         → Ügyfél adatok
```

#### 4.1.4 ZdatumsVtempbe (NAPZAR.DLL)

```pascal
procedure TNapzarForm.ZdatumsVtempbe;
// INSERT INTO VTEMP (DATUM, NEVTABLA) VALUES ('[zárás dátuma]', 'ZARDATUM')
// Ezt a HAVIKEZD.DLL olvassa ki, hogy megtudhassa a legutolsó napzárás dátumát
```

### 4.2 Globális Változók — Singletonok

Az alkalmazás töméntelen globális változót használ (`var` szekció). Ezek a Delphi `var` szekcióban deklarált unit-szintű változók — valójában process-szintű szingleton állapotok.

#### 4.2.1 TRADE.EXE Kritikus Globális Változók

```pascal
// Rendszer-szintű azonosítók
_terminalid       : string;   // 4 karakteres terminal azonosító
_username         : string;   // rendszer username (PARAMETERS táblából)
_password         : string;   // rendszer jelszó

// Pénztár adatok
_homePenztarszam  : string;   // pénztár száma
_homePenztarnev   : string;   // pénztár neve
_homePenztarcim   : string;   // pénztár cipme
_penztarszam      : word;     // pénztár numerikus kódja
_adoszam          : string;   // számított adószám (penztarszam alapján)
_cegnev           : string;   // számított cégnév

// Pénztáros
_proskod          : integer;  // bejelentkezett pénztáros kódja
_prosnev          : string;   // bejelentkezett pénztáros neve

// Bizonylat sorszámok
_lastMatrica      : integer;
_lastTelefon      : integer;
_lastUgyfel       : integer;
_bizonylatszam    : string;

// Hálózat
_host             : string = '185.43.207.99'; // FTP host (hardcoded)
_ipcim            : string = '193.68.57.146'; // kupon szerver IP

// Dátum/Idő
_aktev            : word;
_aktho            : word;
_aktnap           : word;
_aktdatumido      : string;

// Nyomtató
_printer          : byte;     // 0=LPT1, 1=USB Windows nyomtató

// Cikktörzs cache
_ctAzonosito      : array[1..1024] of integer;
_ctEgysegar       : array[1..1024] of integer;
_ctCikknev        : array[1..1024] of string;
_ctDarab          : word;
```

### 4.3 Tranzakció Életciklusa

#### 4.3.1 Devizavásárlás Teljes Folyamata

```
1. FORM INIT (FormActivate)
   ├── AlapadatBeolvasas        → VTEMP + HARDWARE + PENZTAR olvasás
   ├── ValtozokNullazasa        → összes változó nullázása
   ├── ValutaParancs('DELETE FROM VTEMP')
   ├── TombBeToltes             → UI tömb referenciák beállítása
   ├── TablaNullazas            → UI mezők törlése
   ├── KezdijTablaBeolvasas     → kezelési díj tábla cache-be töltése
   └── GetBizonylatSzam(False)  → előzetes bizonylat szám

2. ADATBEVITEL (felhasználói interakció)
   ├── DnemKeyDown  → valutanem megadása (DK1-WD6 edit mezők)
   ├── BankjegyKeyDown → bankjegy összeg
   └── Ujraszamolas    → HUF összeg újraszámolása minden változásnál

3. ÜGYFÉL AZONOSÍTÁS
   ├── ugyfelrutin    → UGYFEL.DLL ShowModal
   │   └── Adatok VTEMP-be kerülnek
   └── UgyfdataVtempbol → VTEMP visszaolvasása

4. KONTROLL (BIGCTRL.DLL)
   ├── Bement VTEMP-be: ugyfeltipus, ugyfelszam, fizetendo, konverzio, bizonylatszam
   └── Kimenet VTEMP-ből: gongyolt, sorszam, nevtabla, forras, engedelyezo, plombaszam

5. XML GENERÁLÁS ÉS KUPON HÍVÁS
   ├── MakeXml        → request.xml fájl írása
   ├── CsomagKuldes   → Coupon.exe futtatása (WinExecAndWait32)
   └── XMLBemasolas   → reply.xml beolvasása _reprow[] tömbbe

6. BIZONYLAT REGISZTRÁCIÓ
   ├── Bizregiszter   → INSERT INTO havifejtabla + haviteteltabla
   ├── KezdijRogzito  → kezelési díj bejegyzése
   └── GetBizonylatSzam(True) → bizonylat szám véglegesítése + INCREMENT

7. REMOTE LERENDEZÉS
   ├── RemoteLerendezes      → natural személy adatok a remote DB-be
   └── RemoteJogiLerendezes  → jogi személy adatok a remote DB-be

8. NYOMTATÁS
   ├── blokknyomtatas(...)  → BLOKNYOM.DLL
   │   └── VTEMP-ből olvassa az adatokat
   └── StartNyomtatas       → fájl LPT1-re / Windows nyomtatóra

9. ZÁRÁS
   ├── ValutaParancs('DELETE FROM VTEMP')
   └── ModalResult := 1
```

### 4.4 Kezelési Díj Számítási Logika

```pascal
// VASARLAS.DLL — GetKezelesiDij()
// Sávos kezelési díj számítás:
// _kdij[1..23] tömb tartalmazza a díjtételeket
// _tranzsav[1..23] tömb tartalmazza a sávhatárokat
// A GetKezelesiDij(_ss) megkeresi azt a sávot amelybe az összeg esik

// KezdijBeepites(_kk: integer)
// Beépíti a kezelési díjat a fizetendő összegbe
// _fizetendo := _netto + _kezelesidij

// Kedvezmény típusok:
// _kezdijengedmenytip = 0: nincs kedvezmény
// _kezdijengedmenytip = 1: fix összegű kedvezmény
// _kezdijengedmenytip = 2: százalékos kedvezmény
// _saját hatáskörű kedvezmény (_shk): pénztáros saját hatáskörű kedvezmény
//   _shk := GetSajatHataskoru  →  max 5 db/nap
```

### 4.5 Kerekítési Logika

```pascal
// VASARLAS.DLL — Kerekito()
function TVasarlasForm.Kerekito(_int: integer): integer;
// A forint összeg kerekítése az érvényes Magyar Nemzeti Bank szabályok szerint
// 1-2 Ft: lefelé kerekítés
// 3-7 Ft: 5 Ft-ra kerekítés
// 8-9 Ft: felfelé kerekítés
// _rounder: real = 0.001 — széchenység konstans a lebegőpontos kerekítéshez
```

---




<a name="06_ADATBAZIS"></a>

# 6. AdatbĂˇzis architektĂşra Ă©s sĂ©ma

---


---

## S58 GPT_54_ELEMZĂSE


---

## S59 7_ADATBAZIS_ES_SZERVEROLDALI_MUKODES



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





---


---

## S60 JUNIOR_ELEMZĂSE


---

## S61 7_ADATBAZIS_SEMA

### 7.1 VALUTA.FDB táblák (kód alapján rekonstruálva)

| Tábla | Mezők | Cél |
|-------|-------|-----|
| **PENZTAR** | PENZTARNEV, PENZTARCIM, PENZTARKOD | Pénztár törzsadat |
| **HARDWARE** | PRINTER, ... | Hardver beállítások |
| **UTOLSOBLOKKOK** | UTOLSOUGYFELSZAM | Utolsó sorszámok |
| **ARFOLYAM** | devizanemenkénti sorok | Árfolyamok |
| **UGYFEL** | azonosítási adatok | Ügyfélnyilvántartás |
| **DEVIZANEM** | kód, név, ISO | Devizanem törzs |
| **KESZLET** | deviza, mennyiség, címletek | Készletállomány |
| **CIMLET** | deviza, névérték, darab | Címletek |
| **PENZTAROS** | név, jelszó, kód | Pénztáros törzs |

### 7.2 TRADE.FDB táblák

| Tábla | Mezők | Cél |
|-------|-------|-----|
| **PARAMETERS** | ELESITVE, ELESITESIDEJE, LASTMATRICA, LASTTELEFON, TERMINALID, USERNAME, JELSZO | Rendszerparaméterek |
| **CIKKTORZS** | AZONOSITO, CIKKNEV, EGYSEGAR | Cikktörzs (kuponok, matricák) |
| **TRADyymm** (dinamikus) | lásd lentebb | Havi tranzakciók |

### 7.3 TRADyymm tábla (tranzakciós napló — havonta létrehozva)

```sql
CREATE TABLE TRADyymm (
  TIPUS        CHAR(1),        -- M=matrica, T=T-Mobile, N=Telenor, V=Vodafone
  BIZONYLATSZAM CHAR(8),
  KATEGORIA    CHAR(33),       -- cikknév/kategória
  STARTDATUM   CHAR(10),
  ENDDATUM     CHAR(10),
  TELEFONSZAM  CHAR(12),
  RENDSZAM     CHAR(10),
  COUNTRYNAME  CHAR(30),
  REFERENCEID  CHAR(25),
  TRANZAKCIO   CHAR(12),       -- kupon tranzakció azonosító
  FIZETENDO    INTEGER,         -- forint összeg
  PENZTAROSNEV CHAR(25),
  DATUM        CHAR(10),
  IDO          CHAR(8),
  SZOLGALTATO  CHAR(10),
  SZOLGALTATAS CHAR(30),
  UGYFELSZAM   INTEGER,
  UGYFELNEV    CHAR(25),
  UGYFELCIM    CHAR(40),
  TARSPENZTAR  CHAR(4),        -- társpénztár kód
  STORNO       SMALLINT,        -- 0=normál, 1=sztornózva
  ELKULDVE     SMALLINT         -- 0=nem küldve, 1=elküldve szerverre
)
```

### 7.4 Western Union (MySQL szerver)

Külön MySQL adatbázis a WU tranzakciókhoz:
- `exclusiveuser` tábla — felhasználók jelszóval
- Szinkronizáció a központi szerverrel

### 7.5 CitySim SQL séma

SIM kártya értékesítés:
- `sim_cards` (telefonszám, termékazonosító)
- `sim_card_products` (ID, név, ár)
- `charge_products` (feltöltési csomagok: 10€, 25€, 50€, 100€)
- `deliveries` (szállítmányok)
- `delivery_cancellations` (sztornózott szállítmányok)
- `transactions` (tranzakciók)
- `passwords` (titkosított jelszavak)

---



---


---

## S62 ESZTER_ELEMZĂSE


---

## S63 D_ADATBAZIS_SEMA_OSSZEFOGLALO

### D.1 Fő adatbázis (valuta.fdb) — lokális

| Tábla | Funkció |
|-------|---------|
| `ARFOLYAM` | Devizanem árfolyamok + készlet |
| `BLOKKFEJ` | Bizonylat fejlécek (napi) |
| `BLOKKTETEL` | Bizonylat tételsorok (napi) |
| `HARDWARE` | Pénztárgép konfiguráció + státusz |
| `PARAMETERS` | Rendszerbeállítások + jelszavak |
| `PENZTAR` | Pénztár törzsadatok |
| `TRANZDIJTABLA` | Sávos kezelési díj tábla |
| `UGYFEL` | Természetes személy ügyfélnyilvántartás (lokális) |
| `JOGISZEMELY` | Jogi személy nyilvántartás (lokális) |
| `UTOLSOBLOKKOK` | Bizonylat sorszám számlálók |
| `VTEMP` | Átmeneti adatcsere tábla (DLL IPC) |
| `QRPARAMS` | NAV pénztárgép QR paraméterek |

### D.2 Trade adatbázis (trade.fdb) — lokális

| Tábla minta | Funkció |
|-------------|---------|
| `TRADyymm` | Havi tranzakciók |
| `BFyymm` | Havi blokkfejek |
| `BTyymm` | Havi blokktételek |
| `KEZDyymm` | Havi kezelési díjak |
| `HZyymm` | Havi záró készletek |
| `NARFyymm` | Napi árfolyamok (havi) |
| `WCIMTARyymm` | Western Union címtár |
| `CIMTARyymm` | Címletezés havi |

### D.3 Remote adatbázis (193.68.57.146) — központi szerver

| Adatbázis | Funkció |
|-----------|---------|
| `UGYFELyy.FDB` | Központi ügyfél-nyilvántartás (éves) |
| `kisugyfel.fdb` | Egyszerűsített ügyfél adatbázis |
| `remotedbase` | Szinkronizációs kapcsolat |

### D.4 Központi szerver táblaszerkezet

| Tábla | Funkció |
|-------|---------|
| `ANEV..ZNEV` | Természetes személyek betű szerint |
| `ABIZ..ZBIZ` | Bizonylatok betű szerint |
| `JOGI` | Jogi személyek |
| `JOGIBIZ` | Jogi személy bizonylatok |
| `JOURNAL` | Terrorlista-szűrési napló |




<a name="07_BIZONYLAT_NYOMTATAS"></a>

# 7. Bizonylatok, nyomtatĂˇs Ă©s dokumentumok

---


---

## S64 GPT_54_ELEMZĂSE


---

## S65 9_BIZONYLATOK_NYOMTATAS_DOKUMENTUMTIPUSOK



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





---


---

## S66 JUNIOR_ELEMZĂSE


---

## S67 5_BIZONYLATOK_RESZLETES_ELEMZES

### 5.1 Bizonylattípusok (BLOKNYOM DLL)

A `TBlokkNyom` modul az alábbi bizonylattípusokat nyomtatja:

| Eljárás | Bizonylat | Leírás |
|---------|-----------|--------|
| `VetelSzamlaNyomtatas` | Vételi számla | Devizavétel bizonylat |
| `EladasSzamlaNyomtatas` | Eladási számla | Devizaeladás bizonylat |
| `AtadBlokkNyomtatas` | Átadóblokk | Pénztárak közötti átadás |
| `AtveszBlokkNyomtatas` | Átvételi blokk | Pénztárak közötti átvétel |
| `StornoBlokknyomtatas` | Sztornó blokk | Sztornó bizonylat |
| `ArfModNyomtatas` | Árfolyam módosítás | Árfolyamváltás bizonylat |
| `CimletNyomtatas` | Címletlista | Címletenkénti bontás |
| `ReklamNyomtatas` | Reklám nyomtatás | Promóciós bizonylat |
| `Ugyfelnyomtatas` | Ügyfél nyomtatás | Ügyfél adatlap |
| `Jogcimnyilatkozat` | Jogcím nyilatkozat | Jogi nyilatkozat |
| `sajatnyil` | Saját nyilatkozat | — |
| `KozszerepNyilatkozat` | Közszereplő nyilatkozat | PEP nyilatkozat |
| `DevizsStatuszNyomtatas` | Deviza státusz | Devizaállapot nyomtatás |

### 5.2 Bizonylat fejléc formátum

Minden bizonylat egységes fejlécet kap (`BlokkFocimIro`):

```
Kupon Portfolio es Kereskedelmi Kft.
     2161 Csomad, Liget utca 40.
            12896127-2-44

     EXCLUSIVE BEST CHANGE ZRT.      (vagy EXPRESSZ EKSZERHAZ ES MINIBANK KFT)

     [Pénztár neve]
     [Pénztár címe]

     Adoszam       : [32313332-2-02 vagy 14040535-2-02]
     Terminál ID   : [4 karakter]
     Bizonylatszam : [8 jegyű szám]

     NUSZ call center: +36 1-587-500
```

A pénztárszám alapján dönt (< 151 = Exclusive Best Change Zrt, ≥ 151 = Expressz Ékszerház):
```pascal
if _penztarszam<151 then begin
  _adoszam := '32313332-2-02';
  _cegnev := 'Exclusive Best Change Zrt';
end else begin
  _cegnev  := 'EXPRESSZ EKSZERHAZ';
  _adoszam := '14040535-2-02';
end;
```

### 5.3 ÁFÁs számla (TRADE EXE)

Két ÁFÁs számla típus közvetlenül a fő EXE-ben:

**Autópálya matrica ÁFÁs számla** (`AfasSzamla`):
```
EGYSZERUSITETT SZAMLA
 elektromos autopalya matrica vetelerol

Szamlaszam: AM-[6 jegy]   Keszult: 2 pld-ban
                           1. peldany

[Fejléc]

Vevo: [ügyfélnév]
Cime: [ügyfélcím]
Adoszam: [ügyfél adószám]

Cikk megnevezese: [kategória]
      Egysegara: [forint]
     Mennyisege: 1 db
      Fizetendo: [forint]

A számla vegosszege 21,26 % AFA-t tartalmaz
```

**Telefon feltöltés ÁFÁs számla** (`TelAfasSzamla`):
- Számlaszám: `TE-[6 jegy]`
- Szállító: cég neve
- 21,26% ÁFA tartalom

### 5.4 Telefon feltöltés bizonylatok (TRADE EXE)

Szolgáltatónként eltérő formátum:

| Szolgáltató | Eljárás | Speciális mezők |
|-------------|---------|-----------------|
| T-Mobile | `TMobilBizonylat` | Magyar Telekom Nyrt, 1777-es szám |
| Telenor | `TelenorBizonylat` | 2045 Törökbálint, 1220-as szám |
| Vodafone | `VodaBizonylat` | 1096 Budapest, 1270-es szám |
| T-Com (Kontroll/Barangoló) | `TcomBizonylat` | TCom típus szerinti |
| Tesco | `TmobilBizonylat` | (azonos formátum) |

### 5.5 E-matrica bizonylatok (TRADE EXE)

Két példány nyomtatása:

**Eladói példány** (`MatricaSellerCopy`):
```
e-matrica ellenorzo szelveny / e-vignette control slip
Eladoi peldany / Seller's copy
Nem adougyi bizonylat ! / No taxation document !

[Fejléc]
Vasarlas idopontja / Date of purchase: [dátum idő]
Rendszam / License plate number: [rendszám]
Felsegjelzes / Country code: [ország]
Kategoria / Category: [kategória]
Tipus / Type: [típus magyar + angol]
Ervenyesseg kezdete / Start of validity: [dátum]
Ervenyesseg vege / End of validity: [dátum]
Ar / Price: [összeg] HUF

Ugyfel alairasa / Customer's signature
```

**Vevői példány** (`MatricaCustomerCopy`):
- Matricaazonosító (Vignette unique ID)
- Termék azonosító (Product ID)
- 30 perces módosítási lehetőség
- 2 éves megőrzési kötelezettség

---



---


---

## S68 ESZTER_ELEMZĂSE

# 3. BIZONYLAT-RENDSZER




---

## S69 31_BIZONYLATTIPUSOK_OSSZESITO

A `BLOKNYOM` DLL (`blokknyomtatas`) a bizonylat típusát az `_nyomtipus` paraméterből kapja. A FormActivate-ben:

```pascal
// BLOKNYOM/Unit2.pas — FormActivate (sor ~295)
if _nyomtipus>10 then _copyblokk := true;  // >10 = MÁSOLAT

if _storno=3 then begin
  StornoBlokknyomtatas;
  exit;
end;

if _tipus='V' then VetelSzamlaNyomtatas;    // Vételi számla
if _tipus='E' then EladasSzamlaNyomtatas;    // Eladási számla
if _tipus='F' then AtadBlokkNyomtatas;       // Átadó blokk
if _tipus='U' then AtveszBlokkNyomtatas;     // Átvételi blokk
```

### 3.1.1 Teljes bizonylattípus katalógus

| # | Típus | Eljárás | Leírás |
|---|-------|---------|--------|
| 1 | Vételi számla (V) | `VetelSzamlaNyomtatas` | Devizavétel → HUF kifizetés |
| 2 | Eladási számla (E) | `EladasSzamlaNyomtatas` | HUF bevétel → deviza kiadás |
| 3 | Átadó blokk (F) | `AtadBlokkNyomtatas` | Pénztárak közötti deviza átadás |
| 4 | Átvételi blokk (U) | `AtveszBlokkNyomtatas` | Pénztárak közötti deviza átvétel |
| 5 | Sztornó blokk | `StornoBlokknyomtatas` | Tranzakció érvénytelenítés |
| 6 | Árfolyam módosítás | `ArfModNyomtatas` | Kedvezményes árfolyam dokumentálás |
| 7 | Címletlista | `CimletNyomtatas` | Deviza-címlet bontás |
| 8 | Ügyfél-nyomtatás | `Ugyfelnyomtatas` | Ügyfél adatlap a bizonylaton |
| 9 | Jogcím nyilatkozat | `Jogcimnyilatkozat` | 300k+ tranzakciók jogi nyilatkozat |
| 10 | Közszereplő nyilatkozat | `KozszerepNyilatkozat` | PEP státusz dokumentálás |
| 11 | Saját nyilatkozat | `sajatnyil` | Kisügyfél saját nevében nyilatkozat |
| 12 | Reklám szekció | `ReklamNyomtatas` | Promóciós blokk |
| 13 | Deviza státusz | `DevizsStatuszNyomtatas` | Belföldi/külföldi deviza státusz |
| 14 | Orosz nyilatkozat | `OroszNyilatkozat` | Orosz ügyfeleknek speciális szöveg |
| 15 | ÁFÁs számla (matrica) | `AfasSzamla` | Autópálya matrica ÁFÁs számla |
| 16 | ÁFÁs számla (telefon) | `TelAfasSzamla` | Telefon-feltöltés ÁFÁs számla |




---

## S70 32_BIZONYLAT_FEJLEC_ES_CEGCSOPORT

### 3.2.1 Cégcsoport felépítés — kódból rekonstruálva

A rendszer pénztárszám-alapján dönt a cégadatokról:

```pascal
// BLOKNYOM/Unit2.pas — GetPenztarData (sor ~430)
If _aktpenztarszam<151 then begin
  _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
  _aktadoszam := '32313332-2-02';
end else begin
  _cegnev := 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT';
  _aktadoszam:= '14040535-2-02';
end;
```

| Pénztárkód | Cég | Adószám |
|------------|-----|---------|
| 1–150 | Exclusive Best Change Zrt. | 32313332-2-02 |
| 151+ | Expressz Ékszerház és Minibank Kft. | 14040535-2-02 |

A fejlécben továbbá megjelenik:
- **Kupon Portfolio és Kereskedelmi Kft.** (2161 Csomád, Liget utca 40.) — a fő holding/csoportcég
- A konkrét pénztár neve és címe
- Telefon
- Terminál ID (4 karakter)

### 3.2.2 Bizonylat fejléc felépítés

```
   ┌─────────────────────────────────────────┐
   │            N Y U G T A                   │
   │                                          │
   │    EXCLUSIVE BEST CHANGE ZRT             │
   │    [Pénztár neve]                        │
   │    [Pénztár címe]                        │
   │    Telefon: [szám]                       │
   │    Adoszam: [32313332-2-02]              │
   │                                          │
   │    [Konverziós valuta vétel/eladás]      │
   │    EXCHANGE (PURCHASE/SELLING)           │
   ├──────────────────────────────────────────┤
   │ Sorszam (INVOICE NR): [12345678]         │
   │ Datum   (DATE)      : [2026.04.02]       │
   │ Ido     (TIME)      : [14:35]            │
   │       (Nyugtaszam: X/Y)                  │
   ├──────────────────────────────────────────┤
   │ Adómentes           Szj - 67.13.10.0    │
   │ M.A.A.  a szolgaltatas nyujtasa a 2007  │
   │ evi CXVII tv. 86 § e) alapjan mentes    │
   │ az ado alol                              │
   ├──────────────────────────────────────────┤
```




---

## S71 33_AFA_KEZELES

### 3.3.1 Valutaváltás — ÁFA mentes

A valutaváltási tevékenység ÁFA-mentes, ezt minden bizonylaton kötelezően feltüntetik:

```pascal
// BLOKNYOM/Unit2.pas — VetelSzamlaNyomtatas
writeLn(_LFile,'Adómentes               Szj - 67.13.10.0');
writeLn(_LFile,'M.A.A.    a szolgaltatas nyujtasa a 2007');
writeLn(_LFile,'evi CXVII tv. 86 § e) alapjan mentes az');
writeLn(_LFile,'             ado alol');
```

**Jogszabályi hivatkozás:** 2007. évi CXVII. tv. (ÁFA törvény) 86. § e) pont — pénzváltási tevékenység ÁFA mentessége.
**SZJ kód:** 67.13.10.0 — pénzügyi közvetítés segédtevékenysége

### 3.3.2 Matrica értékesítés — ÁFÁ-s

```pascal
// TRADE.EXE — AfasSzamla
writeLn(_LFile,'A számla végösszege 21,26 % AFA-t tartalmaz');
```

Az autópálya matrica értékesítés NEM ÁFA-mentes — 21,26% ÁFA tartalmat mutat. (Ez a bruttó összegből visszaszámolt ÁFA tartalom 27%-os kulcs esetén: 27/127 ≈ 21,26%.)

### 3.3.3 Western Union ÁFA

A havi zárásban külön WU ÁFA forgalom szekció:
```pascal
// HAVIZAR/Unit2.pas — deklarált változók:
_haviKezdij: integer;           // A havi kezelési díj
_haviKezdijAtadas: integer;     // Átadásból származó kezelési díj
_haviKezdijAtvet: integer;      // Átvételből származó kezelési díj
```




---

## S72 34_BIZONYLAT_TARTALOM_RESZLETES_ELEMZES

### 3.4.1 Vételi számla (V) — tétel szekció

```
   V.nem   Arfolyam    B.jegy       Forint
   CURR.    RATE        CASH        VALUE
   ──────────────────────────────────────────
   EUR       410.50      500       205250
   USD       378.20      200        75640
   ──────────────────────────────────────────
   Kerekites (ROUNDING)    :          -2
   Netto Ft  (SUM TOTAL)  :     280890
   Kez. kltsg (HANDLING FEE):      1405
   Kifizetve:(PAID):         279485
```

A vételi számla tartalmazza:
- Devizanemenként: valutanem, árfolyam, bankjegy darab, forint érték
- Kerekítés előjellel (+/-)
- Nettó összeg
- Kezelési költség
- Kifizetve (bruttó = nettó - kezelési díj, kerekítve)

### 3.4.2 Eladási számla (E) — kiegészítő elemek

Eladásnál (ügyfél devizát kap) a fizetőeszköz is megjelenik:

```pascal
// BLOKNYOM/Unit2.pas — EladasSzamlaNyomtatas
if _fizetoeszkoz=1 then kozepreir('Az ugyletet keszpenzben teljesitjuk');
if _fizetoeszkoz=2 then begin
  Kozepreir('Az ugylet bankkartyaval tortent');
  // Bankkártyával és 300k alatt és jogi személy → extra adatok:
  if (_fiz<300000) and (_ugyfeltipus='J') then begin
    writeLN(_LFile,'Ugyfel: '+_joginev);
    writeLN(_LFile,'Telephely: '+_jogihely);
    writeLN(_LFile,'Adoszam: '+_adoszam);
  end;
end;
```

Fizetőeszköz típusok:
| Kód | Fizetőeszköz |
|-----|-------------|
| 1 | Készpénz |
| 2 | Bankkártya (OTP terminál) |

### 3.4.3 Átadó-átvételi blokk tartalma

A pénztárak közötti devizamozgásnál büntetőjogi nyilatkozat kötelező:

```pascal
// BLOKNYOM/Unit2.pas — AtadBlokkNyomtatas
writeLn(_LFIle,'Büntető felelősségem tudatában kijelen-');
writeLn(_LFIle,'tem, hogy a fentiekben felsorolt pénz-');
writeLn(_LFIle,'készletet a szállítóknak átadtam, azt');
writeLn(_LFIle,'        tételesen átszámoltam.');
// ... aláírás mezők: átadó + átvevő
```




---

## S73 35_JOGCIM_NYILATKOZAT_TELJES_SZOVEG

```pascal
// BLOKNYOM/Unit2.pas — Jogcimnyilatkozat (sor ~1440)
WriteLn('JOGCÍM NYILATKOZAT');
WriteLn('Büntetőjogi felelősségem tudatában nyi-');
WriteLn('latkozom, hogy a fenti tranzakciót');

// Jogi személynél:
kozepreir(_joginev);
kozepreir('nevében bonyolítom,');
KozszerepNyilatkozat(_kozszereplo);

// Természetes személynél:
if _megbizoszam=0 then begin
  writeLn('természetes személyenként, saját magam');
  write('nevében bonyolítom, ');
end else begin
  kozepreir(_megbizonev);
  kozepreir('megbízásából bonyolítom, ');
end;

// Kötelezettség szöveg:
WriteLn('Tudomásom van arról, hogy 5 (öt) munka-');
WriteLn('napon belül köteles vagyok bejelenteni a');
WriteLn('szolgáltatónak a fenti adatokban, vagy a');
WriteLn('saját adataimban bekövetkező esetleges');
WriteLn('változásokat, és e kötelezettség elmu-');
WriteLn('   lasztásából eredő kár engem terhel');

// Forrás megjelölés:
if _forras<>'' then
  writeLn('Pénzeszközöm forrása: '+ _forras);

// Aláírás mező:
writeLn('.......................................'); 
writeLn('             ügyfél aláírása');
```




---

## S74 36_BIZONYLAT_SORSZAMOZAS

```pascal
// VASARLAS/Unit2.pas — GetBizonylatszam (sor 2795)
function TVasarlasForm.GetBizonylatszam(_write: boolean): string;
// _write=False → csak olvasás (előzetes)
// _write=True  → végleges sorszám kiadás és léptetés
```

A bizonylat sorszám 8 jegyű, pénztáranként szekvenciális. Konvenciók:
- Előzetes bizonylatszám: a folyamat elején kiosztásra kerül (read-only)
- Végleges bizonylatszám: a tranzakció engedélyezése után véglegesítődik (`_write=True`)




---

## S75 37_BIZONYLAT_MASOLAT

A `_nyomtipus > 10` paraméter jelöli a másolatot:

```pascal
if _copyBlokk then begin
  WriteLn(_Lfile,'M  A  S  O  L  A  T');
  if _reprintIndok<>'' then
    KozepreIr('(Indoka: '+ trim(_reprintIndok)+')');
end;
```

A másolat mindig tartalmazza az újranyomtatás indokát.

---



---


---

## S76 TAMAS_ELEMZĂSE


---

## S77 5_NYOMTATASI_ALRENDSZER

### 5.1 Nyomtatási Architektúra

```
┌────────────────────────────────────────────────────────────────────┐
│                    NYOMTATÁSI ALRENDSZER                           │
│                                                                    │
│  ┌──────────────────┐      ┌──────────────────┐                   │
│  │  Blokk Nyomtatás │      │  Lapnyomtatás    │                   │
│  │  (ESC/POS)       │      │  (Windows API)   │                   │
│  └────────┬─────────┘      └────────┬─────────┘                   │
│           │                         │                              │
│  ┌────────▼─────────────────────────▼─────────┐                   │
│  │              c:\valuta\aktlst.txt           │                   │
│  │         (ideiglenes nyomtatási buffer)      │                   │
│  └────────────────────┬───────────────────────┘                   │
│                       │                                            │
│           ┌───────────┴───────────┐                               │
│           ▼                       ▼                               │
│  _PRINTER = 0             _PRINTER = 1                            │
│  AssignFile(LPT1)         AssignPrn()                             │
│  (Parallel port)          (Windows spooler)                       │
└────────────────────────────────────────────────────────────────────┘
```

### 5.2 ESC/POS Parancsok

```pascal
// BLOKNYOM.DLL és TRADE.EXE Unit1.pas — ESC/POS konstansok

// Inicializálás
_inic    : string = #27#64;     // ESC @ = printer reset

// Félkövér szöveg
_kemeny  : string = chr(27)+chr(71);   // ESC G = bold ON
_puha    : string = chr(27)+chr(72);   // ESC H = bold OFF

// Dupla szélesség
_wideon  : string = #14;        // SO = dupla szélesség BE
_wideoff : string = #20;        // DC4 = dupla szélesség KI

// Vágás (papír elvágás)
_Lf5     : string = #27#97#5;   // ESC a 5 = vágás + néhány sor előtolás

// Papír előtolás (form feed szimulálva)
chr(26)  // ^Z = papír vége jel (záró jel a szövegfájl után)
```

### 5.3 Nyomtatási Folyamat

```pascal
// TRADE.EXE — Teljes nyomtatási folyamat
procedure TForm1.Blokknyitas;
begin
  assignFile(_LFile, 'C:\valuta\aktlst.txt');
  Rewrite(_LFile);
  write(_LFile, #27#64);  // ESC @ = printer inicializálás
end;

procedure TForm1.StartNyomtatas;
begin
  Writeln(_LFile, #27#97#5);  // ESC a 5 = vágás parancs
  WriteLn(_LFile, chr(26));   // ^Z = fájlzáró jel
  CloseFile(_LFile);
  TextKiiro;                  // Fájl tartalmának nyomtatóra küldése
end;

procedure TForm1.TextKiiro;
var _mondat: string;
    _nyomtat, _olvas: textFile;
begin
  IF _PRINTER <> 1 THEN
    AssignFile(_nyomtat, 'LPT1')
  else
    AssignPrn(_nyomtat);

  Rewrite(_nyomtat);
  AssignFile(_olvas, 'c:\valuta\aktlst.txt');
  Reset(_olvas);
  while not eof(_olvas) do begin
    readln(_olvas, _mondat);
    writeln(_nyomtat, _mondat);
  end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;
```

### 5.4 Blokknyomtató Formátumok

#### 5.4.1 39 Karakter Széles Layout

```
123456789012345678901234567890123456789
─────────────────────────────────────
 Kupon Portfolio es Kereskedelmi Kft.
      2161 Csomad, Liget utca 40.
             12896127-2-44

    EXCLUSIVE BEST CHANGE ZRT.      ← dupla szélesség (14 karakter-sor)

      [Pénztár neve 39 karakter]
      [Pénztár cím 39 karakter]

     Adoszam       : 32313332-2-02
     Terminal ID   : XXXX
     Bizonylatszam : 12345678

  NUSZ call center: +36 1-587-500
─────────────────────────────────────
```

#### 5.4.2 Bizonylat Tételes Rész (BLOKNYOM.DLL)

```pascal
procedure TBlokkNyom.BlokkTetelIro;
// Devizanemenkénti sorok nyomtatása:
// Format: [ELOJEL][VALUTANEM] [BANKJEGY] x [ARFOLYAM] = [FORINTERTEK] Ft
// Példa: +EUR    100 x 390 =  39.000 Ft
//        +USD    200 x 360 =  72.000 Ft
//                   Netto: 111.000 Ft
//          Kezelesidij:      1.500 Ft
//                Fizet: 112.500 Ft
```

#### 5.4.3 Kétpéldányos E-matrica Bizonylat

```pascal
// TRADE.EXE — MatricaSellerCopy + MatricaCustomerCopy
// Eladói példány tartalmazza: rendszám, kategória, típus, érvényesség, ár
// Vevői példány tartalmazza: matrica azonosító, termékazonosító
//   + "30 perces módosítási lehetőség"
//   + "2 éves megőrzési kötelezettség"
// Mindkét példány azonos nyomtatóra kerül, csak tartalma különbözik
```

### 5.5 Havi Zárás Nyomtatása (HAVIZAR.DLL)

A HAVIZAR.DLL közvetlenül `TTextFile` típussal nyomtat a Windows nyomtatóra (nem ESC/POS formátumban, hanem lapnyomtatón):

```pascal
// HAVIZAR.DLL
_LFile, _nyomtat, _olvas: Textfile;

procedure THAVIZARAS.HavizarasNyomtatas;
// Szekvenciális nyomtatás:
//   FejlecIras           → cég és pénztár fejléc
//   Forgalomiras         → devizanemenkénti forgalom
//   ForgalomOsszesitesIras → összesítők
//   KezkoltsegIras       → kezelési költségek
//   ZarokeszletIras      → záró készlet
//   WesternIras          → WU forgalom (ha van)
//   Afairas              → ÁFA tartalom
//   UgyfelforgalomIras   → ügyfél forgalom bontás
```

### 5.6 Forint Formázás

```pascal
// TRADE.EXE — FtForm() függvény
function TForm1.FtForm(_ar: integer): string;
var _lenars: integer;
begin
  result  := inttostr(_ar);
  _lenars := length(result);
  case _lenars of
    4: result := leftstr(result,1) + '.' + midstr(result,2,3);  // 1.234
    5: result := leftstr(result,2) + '.' + midstr(result,3,3);  // 12.345
    6: result := leftstr(result,3) + '.' + midstr(result,4,3);  // 123.456
    7: result := leftstr(result,1) + '.' + midstr(result,2,3) + '.' + midstr(result,5,3); // 1.234.567
  end;
  result := result + ' Ft';
end;
```

---



---


---

## S78 GABOR_ELEMZĂSE


---

## S79 15_KIEGESZITO_BIZONYLAT_FORMATUMOK_VIZUALIS_TERVEZESE

### 15.1 A jelenlegi blokknyomtató bizonylat struktúra

A `TBlokkNyom` modul 39 karakteres sorokba rendezi a tartalmat. Rekonstruált fejléc:

```
---------------------------------------
Kupon Portfolio es Kereskedelmi Kft.
  2161 Csomad, Liget utca 40.
       12896127-2-44

    EXCLUSIVE BEST CHANGE ZRT.

    [Pénztár neve]
    [Pénztár címe]

Adoszam       : 32313332-2-02
Terminal ID   : A1B2
Bizonylatszam : 00123456

NUSZ call center: +36 1-587-500
---------------------------------------
DEVIZAVASARLAS BIZONYLATJA
Datum: 2026.04.02.    Ido: 09:15:33
Penztaros: KOVACS ANNA

Devizanem    : EUR
Osszeg       :      320.00 EUR
Arfolyam     :      395.50
Fizetendo    :  126 560 Ft
Kezeles dij  :      500 Ft
Netto        :  126 060 Ft

Ugyfelnev    : KISS BELA
Szul.datum   : 1965.03.12
Okmanyszam   : 123456AB

      Penztar alairasa:

      ________________

      Ugyfel alairasa:

      ________________
---------------------------------------
```

**Elemzés:**
- 39 karakteres sor = a klasszikus 80mm thermal nyomtató formátuma
- Nincs grafikus elem (csak szöveges)
- ESC/POS parancsokkal félkövér és dupla-szélesség formázás
- Magyar ékezetes karakterek problémásak (WIN1250 → ESC/POS kódlap fordítás)

### 15.2 Modern bizonylat design javaslat

A modern rendszerben a bizonylat HTML/CSS template-en alapuljon, amelyet runtime konvertál ESC/POS-ra:

```
┌───────────────────────────────────────────┐
│                                           │
│         EXCLUSIVE BEST CHANGE ZRT.        │
│                                           │
│  ════════════════════════════════════    │
│  DEVIZAVÁSÁRLÁS BIZONYLATA               │
│  ════════════════════════════════════    │
│                                           │
│  Dátum:       2026.04.02.                │
│  Idő:         09:15:33                   │
│  Bizonylat:   00123456                   │
│  Terminál:    A1B2                       │
│  Pénztáros:   KOVÁCS ANNA                │
│                                           │
│  ──────────────────────────────────────  │
│  TRANZAKCIÓ                              │
│  ──────────────────────────────────────  │
│  Devizanem:   EUR (euró)                 │
│  Összeg:               320.00 EUR        │
│  Árfolyam:             395.50 Ft/EUR     │
│  Fizetendő:        126 560 Ft            │
│  Kezelési díj:          500 Ft           │
│  Nettó kifizetés:   126 060 Ft           │
│                                           │
│  ──────────────────────────────────────  │
│  ÜGYFÉL ADATAI                           │
│  ──────────────────────────────────────  │
│  Név:         KISS BÉLA                  │
│  Születési d: 1965.03.12.                │
│  Okmányazon:  123456AB                   │
│  Állampolgár: Magyar                     │
│                                           │
│  Adószám (EBC): 32313332-2-02            │
│  Pénztár:       PÉCS-01                  │
│  NUSZ: +36 1 587-500                     │
│                                           │
│  Pénztáros aláírása:  . . . . . . .      │
│  Ügyfél aláírása:     . . . . . . .      │
│                                           │
│  Ez a bizonylat 2 példányban készült.    │
│  ÁFA mentes (Pénzügyi szolgáltatás)      │
│                                           │
└───────────────────────────────────────────┘
```

### 15.3 E-matrica bizonylat modern verziója

Az eredeti `MatricaSellerCopy` és `MatricaCustomerCopy` kétnyelvű (magyar + angol) formátumának megtartása kötelező, de a formázás javítható:

```
┌───────────────────────────────────────────┐
│  e-matrica ellenőrző szelvény             │
│  e-vignette control slip                  │
│  ════════════════════════════════════    │
│                                           │
│  ELADÓI / SELLER'S COPY                  │
│  Nem adóügyi bizonylat / Non-tax doc.     │
│                                           │
│  Vásárlás / Purchase: 2026.04.02. 09:22  │
│  Rendszám / Plate:    ABC-123            │
│  Ország / Country:    HU                 │
│  Kategória / Cat.:    D1 (személyautó)   │
│  Típus / Type:        éves / annual      │
│  Érvényesség / Valid: 2026.04.01-2027.03.31│
│  Ár / Price:          50 140 Ft          │
│                                           │
│  Matricaazonosító:    VIG-2026-123456789  │
│  Termék ID:           HU-D1-2026-ANN     │
│                                           │
│  ⓘ  30 perces módosítási lehetőség       │
│     Az okmányt 2 évig megőrizni!          │
│                                           │
│  Ügyfél aláírása:     . . . . . . .      │
└───────────────────────────────────────────┘
```

---




<a name="08_ZARAS"></a>

# 8. Napi Ă©s havi zĂˇrĂˇsok, kĂ©szletkezelĂ©s

---


---

## S80 ESZTER_ELEMZĂSE


---

## S81 41_NAPNYITAS

### 4.1.1 Indulási szekvencia

A rendszer nem ismeri külön a „napnyitás" fogalmát — a nap megnyitása a pénztáros belépésekor történik:

1. **Trade.EXE** → `FormActivate` → `InditoTimer`
2. **Internet ellenőrzés** → internet nélkül a program NEM indul
3. **Alapadat beolvasás** → pénztár név, cím, utolsó ügyfél
4. **Havi TRADE tábla** → `HaviTradeControl` — aktuális havi `TRADyymm` tábla létrehozása
5. **Logfájl** → `SetLogFile` — XOR-kódolt napi napló inicializálás
6. **Pénztáros belépés** → `GetPenztaros.ShowModal` — jelszóval
7. **Megnyitott nap** → `HARDWARE.MEGNYITOTTNAP` mező frissítése

A `HARDWARE` tábla két kulcsmezője:
- `MEGNYITOTTNAP` — az aktuálisan megnyitott nap dátuma
- `LEZARTNAP` — az utoljára lezárt nap dátuma

### 4.1.2 Napi kezelési díj nyomtatás (NAPIKEZD DLL)

A `NAPIKEZD` DLL feladata a korábbi napok kezelési díj/költség nyomtatása. Nem a nap megnyitása, hanem a VISSZAMENŐLEGES riport generálás.

```pascal
// NAPIKEZD/Unit2.pas — FormActivate
_gepfunkcio    := FieldByName('GEPFUNKCIO').asInteger;
_megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
_lezartnap     := trim(FieldByName('LEZARTNAP').AsString);

// Csak értéktár (gepfunkcio=2) használhatja:
if _gepFunkcio<>2 then begin
  _Mresult := 2;
  exit;
end;
```

A nyomtatás naptár-alapú — a felhasználó kiválasztja a napot, és a rendszer az adott nap kezelési díjait nyomtatja ki a havi KEZD táblából.




---

## S82 42_NAPZARAS_NAPZAR_DLL

### 4.2.1 Napzárás teljes folyamata

A napzárás a nap legfontosabb adminisztratív eseménye:

```pascal
// NAPZAR/Unit2.pas — InditoTimer (sor ~290)

// 1. Alapadatok ellenőrzése:
_gepfunkcio   := FieldByNAme('GEPFUNKCIO').asInteger;
_lezartnap    := trim(FieldByName('LEZARTNAP').asstring);
_kellforgalom := FieldByNAme('KELLFORGALOM').asInteger;
_kellwestern  := FieldByName('KELLWESTERN').asInteger;
_kellMetro    := FieldByName('KELLMETROAFA').asInteger;
_kelltesco    := FieldByName('KELLTESCOAFA').asInteger;
_kellmatrica  := FieldByNAme('KELLMATRICA').asInteger;
_otp          := FieldByName('POSTTERM').asInteger;
_otpopen      := FieldByName('OTPOPEN').asInteger;
_megnyitottnap:= trim(FieldByNAme('MEGNYITOTTNAP').asstring);

// 2. Dátum validáció:
if _zDatums='' then begin
  ShowMessage('NINCS BELÉPÉSI DÁTUM A HARDWARE-BEN');
  ModalResult := 2;
  exit;
end;

if _zDatums>_megnyitottnap then begin
  Showmessage('A zárandó nap a jövőben lesz !');
  Modalresult := 2;
  exit;
end;

// 3. Adatregeneráció:
regeneralorutin(0);

// 4. Előellenőrzés:
_errorcode := Napzarcontrol;
```

### 4.2.2 Napzár ellenőrzés — errorcode rendszer

```pascal
// NAPZAR/Unit2.pas — NapzarControl
{
  errorcode=  0: hibátlan
              1: hiányos MTCN szám
              2: esti címletezés hibás
              3: kezelési díj címletezés hibás
              4: western union címletezés hibás
              5: afa címletezés hibás
              6: foglaló címletezés hibás
              7: elektromos kereskedés címletezés hibás
              8: axa címletezés hibás
              9: moneygram címletezés hibás
}
```

| Kód | Hiba | Következmény |
|-----|------|-------------|
| 0 | Hibátlan | Napzárás folytatható |
| 1 | Hiányos MTCN szám | **BLOKKOLÓ** — nem zárható |
| 2-9 | Címletezési hiba | Címletmenü megnyitása, javítás szükséges |

### 4.2.3 Napzárás lépések

```pascal
// NAPZAR/Unit2.pas — a zárás tényleges végrehajtása (sor ~400)

// 1. HRK (horvát kuna) zárás:
_hrkOke := horvatkunazaro;

// 2. Pénztárgép QR kód:
qrdisplayrutin;

// 3. NAV kontroll:
_navoke := navzarocontrol;

// 4. Havi gyűjtőkbe másolás:
HavigyujtokbeMasolas;

// 5. Napi forgalom számítás:
Napiforgalomszamitas;

// 6. Napi árfolyamtáblák feltöltése:
NarfolyamFeliras;

// 7. Napi jelentés:
napijelrutin;

// 8. Dekádjelentés:
DekzarCtrl(_zDatums);

// 9. Napzár nyomtatás:
napzarnyomtatorutin;

// 10. Záródátum rögzítése:
_pcs := 'UPDATE HARDWARE SET LEZARTNAP='+chr(39)+_zDatums+chr(39);
ValutaParancs(_pcs);

// 11. Üres pénztár kontroll:
UresPenztarControl;
```

### 4.2.4 Üres pénztár kontroll

Ha a HUF záró készlet nulla, speciális kezelés:

```pascal
// NAPZAR/Unit2.pas — UresPenztarControl
procedure TNapZarForm.UresPenztarControl;
begin
  // HUF záró lekérdezés:
  _hufzaro := FieldByNAme('ZARO').asInteger;
  if _hufzaro<>0 then exit;
  
  // Ha nulla: a címlet-fájlba 0 értéket ír:
  _pcs := 'INSERT INTO ' + _cimfilenev + 
    ' (DATUM,VALUTANEM,OSSZESFORINTERTEK) VALUES (..., ''HUF'', 0)';
end;
```




---

## S83 43_DEKAD_TIZNAPOS_IDOSZAK

### 4.3.1 Dekádjelentés

A `DEKRUTIN` DLL kezeli a dekád (10 napos) beszámolókat. A `DekzarCtrl` a napzárásban hívódik meg és ellenőrzi/generálja a dekád-adatokat.

A dekád az `_aktdek` változóban:
```pascal
// VASARLAS/Unit2.pas
_aktdek := yearof(Date)-2000;  // Az aktuális évtized (pl. 26 a 2026-hoz)
```

**Megjegyzés:** Ez a változó a Firebird adatbázis fájl elnevezéshez is használatos: `ugyfel26.fdb`.




---

## S84 44_HAVI_ZARAS_HAVIZAR_DLL

### 4.4.1 Havi zárás teljes folyamata

```pascal
// HAVIZAR/Unit2.pas — HookEGombClick (sor ~320)

// A kért hónap meghatározása:
_kertev := _maiev;
_kertho := 1 + _hoindex;

// Táblák elnevezése:
_bfTablaNev   := 'BF' + _farok;      // BF2604 = Blokkfej 2026-április
_btTablanev   := 'BT' + _farok;      // BT2604 = Blokktétel 2026-április
_kezdTablaNev := 'KEZD' + _farok;    // KEZD2604 = Kezelési díj 2026-ápr.
_eHzaroTablaNev := 'HZ' + _eFarok;  // HZ2603 = Havi záró előző hónap
_ujHzTablanev := 'HZ' + _farok;     // HZ2604 = Havi záró aktuális hónap
```

### 4.4.2 Havi táblák dinamikus elnevezése

| Prefix | Struktúra | Tartalom |
|--------|-----------|----------|
| `BF` | BFyymm | Blokkfej (bizonylat fejlécek) |
| `BT` | BTyymm | Blokktétel (bizonylat sorok) |
| `KEZD` | KEZDyymm | Kezelési díj adatok |
| `HZ` | HZyymm | Havi záró készlet |
| `NARF` | NARFyymm | Napi árfolyamok |
| `TRAD` | TRADyymm | Tranzakciók (Trade.fdb-ben) |
| `WCIMTAR` | WCIMTARyymm | Western Union címtár |

### 4.4.3 Havi záró riport tartalma

A havi zárás nyomtatás szekciói (HAVIZAR modulból):
1. **Fejléc** — cég, pénztár adatok
2. **Valuta forgalom** — devizanemenkénti bontás (be/ki/nyitó/záró)
3. **HUF forgalom** — forint be/ki/nyitó/záró
4. **Kezelési költség** — havi kezelési díj összesítő
5. **Western Union** — WU tranzakciók összesítője
6. **ÁFA** — külön ÁFÁ-s tételek (Metro, Tesco)
7. **Matrica** — autópálya matrica értékesítés
8. **E-ker** — elektromos kereskedelmi forgalom
9. **OTP terminál** — POS tranzakciók




---

## S85 46_REGENERACIO

### 4.6.1 A REGEN modul feladata

A `regeneralorutin` az adatbázis konzisztenciáját állítja helyre — készletek, forgalmi adatok újraszámolása:

```pascal
// VASARLAS/Unit2.pas
regeneralorutin(0);  // 0 = teljes regeneráció
```

Ez kritikus pl. napzárásnál és a nap elején, hogy a készletadatok konzisztensek legyenek.

---




<a name="09_BIZTONSAG"></a>

# 9. BiztonsĂˇgi architektĂşra Ă©s kockĂˇzatok

---


---

## S86 JUNIOR_ELEMZĂSE


---

## S87 9_BIZTONSAGI_MECHANIZMUSOK

### 9.1 Pénztáros belépés (PROSBE DLL)

- Pénztáros lista gridből választás
- Jelszó ellenőrzés: `JelszoKodolo` titkosítás + összehasonlítás
- ID kód választás (személyi igazolványra)
- `Evaulate` — hex jelszó kiértékelés
- Internet ellenőrzés (`Vaninternet`)

### 9.2 Supervisor jelszó (SUPER DLL)

Védett műveletek előtt kötelező supervisor jelszó:
- Tanúsítvány szerkesztés
- Log megtekintés
- Sztornó
- Címlet setup
- Egyéb admin funkciók

### 9.3 XOR naplózás

A logfájlok XOR kódolásúak (`Kodxor`):
```pascal
function TForm1.Kodxor(_s: string): string;
begin
  result := '';
  for _y := 1 to length(_s) do begin
    _asc := 255 - ord(_s[_y]);
    result := result + chr(_asc);
  end;
end;
```
Ez egyszerű karakter-invertálás (255-karakter), NEM valódi titkosítás.

---



---


---

## S88 ESZTER_ELEMZĂSE


---

## S89 53_BIZTONSAGI_GYENGESEGEK

### 5.3.1 XOR „titkosítás" — NEM valódi védelem

```pascal
// TRADE.EXE — Kodxor
function TForm1.Kodxor(_s: string): string;
begin
  result := '';
  for _y := 1 to length(_s) do begin
    _asc := 255 - ord(_s[_y]);
    result := result + chr(_asc);
  end;
end;
```

Ez egyszerű karakter-invertálás (`255 - c`). Önmagára alkalmazva visszaadja az eredetit → szimmetrikus. **NEM titkosítás**, hanem obfuszkáció. A logfájlok bárki által visszafejthetők.

### 5.3.2 Hardcoded jelszavak és IP címek

```pascal
// A kódban közvetlenül megtalálható:
_host     := '185.43.207.99';      // FTP szerver IP
_ftpPort  := 21100;                 // FTP port
_userid   := 'ebc-10%';            // FTP user
_ftpPass  := 'klc+45%';            // FTP jelszó
_ipcim    := '193.68.57.146';      // Központi szerver IP

// E-mail címek:
'fabulyazsuzsa.eec@gmail.com'
'kosa.zoltan.ebc@gmail.com'
'nagyannamaria.ebc@gmail.com'
'batori.monika.ebc@gmail.com'
```

### 5.3.3 SQL injection sebezhetőség

A kód SEHOL nem használ paraméteres lekérdezést:

```pascal
// Tipikus minta (több száz helyen):
_pcs := 'SELECT * FROM UGYFEL WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

// String értékeknél:
_pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'!'+chr(39);
// ...WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
```

A `chr(39)` = aposztróf. Ha bármely felhasználói input aposztrófot tartalmaz, az SQL injection lehetséges. **A jelenlegi fenyegetettség alacsony**, mert:
- Helyi Firebird adatbázis (nem hálózaton)
- A beviteli mezők többsége korlátozva van (combo box, szűrt input)
- De: az ügyfélnév, cím, megjegyzés mezők szabadszövegesek

### 5.3.4 Jelszó-kezelés

```pascal
// PROSBE DLL — pénztáros jelszó:
_jelszo := FieldByName('JELSZO').asString;
// Összehasonlítás: JelszoKodolo + Evaulate (hex)
```

A jelszavak a TRADE.FDB `PARAMETERS.JELSZO` mezőben vannak tárolva — nem plaintext, de a „kódolás" feltehetően egyszerű (hex → összehasonlítás), nem bcrypt/PBKDF2 szintű hash.

### 5.3.5 Fix útvonalak

Minden DLL hardcoded `c:\valuta\` útvonalon keresi a fájlokat:

```pascal
function arfolyamkijelzes(_para:string): integer;stdcall; 
  external 'c:\valuta\bin\Arfdisp.dll';
function blokknyomtatas(_para: integer):integer; stdcall; 
  external 'c:\valuta\bin\bloknyom.dll';
// ... minden DLL hivatkozás c:\valuta\bin\*.dll
```

Ez lehetetlenné teszi:
- Többpéldányos telepítést
- Tesztkörnyezet futtatását
- UAC-kompatibilis modern Windows telepítést



---


---

## S90 TAMAS_ELEMZĂSE


---

## S91 FUGGELEK_D_BIZTONSAGI_LELETJEGYZEK

### Kritikus Sebezhetőségek (P0)

1. **Backdoor jelszó:** `'628'` bármely pénztáros azonosítón beléptetéshez használható
2. **Plaintext FTP jelszó:** `'klc+45%'` minden DLL forrásban megtalálható
3. **XOR-only jelszóvédelem:** Trivialisan visszafejthető
4. **Supply chain:** `valto.exe` aláírás-ellenőrzés nélkül fut

### Magas Kockázatú Sebezhetőségek (P1)

5. **Titkosítatlan Firebird kapcsolat:** Wire protocol plain text
6. **Self-signed HTTPS:** Kupon API tanúsítvány-ellenőrzés gyenge
7. **IP-alapú kapcsolat:** DNS poisoning lehetséges
8. **Inkonzisztens biztonsági másolat:** Élő DB fájl másolása `gbak` nélkül

### Közepes Kockázatú Sebezhetőségek (P2)

9. **XOR napló:** Log manipulálható (write-then-XOR)
10. **VTEMP race condition:** Elméleti versenyfeltétel (bár single-thread)
11. **Devizanem array injection:** Ha a DNEM tábla módosítható, a tömb-index felborulhat

---




<a name="10_UI_UX"></a>

# 10. UI/UX design, wireframe-ek Ă©s modernizĂˇciĂł

---


---

## S92 GABOR_ELEMZĂSE


---

## S93 5_UIUX_ANTIPATTERNAK_RESZLETES_KRITIKAI_ELEMZES

### 5.1 A "minden szín más" antipattern

**Probléma:** A rendszerben legalább 15 különböző háttérszín van azonosítva. Néhány példa a DFM-ekből:
- `clTeal` (STORNO) — türkiz
- `3289650` (NAPZAR) — sötétzöld
- `10526880` (UGYFEL) — szürkéskék
- `clMedGray` (FOGLALO)
- `6324288` (VASARLAS) — sötétkékeszöld
- `16756991` (ELADAS) — halvány kék
- `clMoneyGreen` (TRADE főmenü)
- `clWhite` (BIZONYLATDISP)
- `clGray` (SUPERVISOR)
- `clBlack` (PROSBELEP)
- `11599871` (CIMLET) — kékeszöld
- `clBtnFace` (BLOKNYOM)

**Következmény:** A felhasználó minden új form megnyitásakor vizuálisan "újraorientálódik". Nincs brand identity, nincs vizuális hierarchia a rendszer egészén belül.

**Modern megoldás:** 3-5 szem-barát, kontrasztos szín az egész rendszerre + tokenzált design system.

### 5.2 A "font-káosz" antipattern

**Probléma:** 8+ különböző fontcsalád, 5+ méret, random stílus-kombinációk (Bold, Italic, BoldItalic, BoldItalic együtt).

Legszélsőségesebb példa: `Elephant` font a STORNO főcímén — egy kalandregény borítón talán elfogadható, de pénztári rendszerben professzionalizmus-hiány.

**Modern megoldás:** 1 fontcsalád (Inter vagy Roboto), 3 méret (body/heading/display), 2 súly (Regular/Bold).

### 5.3 A "modal-pokol" antipattern

**Probléma:** 110+ DLL mind `ShowModal`-lal hívódik. Ez azt jelenti:
- Párhuzamos munkavégzés lehetetlen
- Nincs "vissza" gomb — Escape az egyetlen out
- Ha egy belső DLL hibát dob, az egész lánc leszakad
- A felhasználó nem látja a breadcrumb-ot (hol tart a folyamatban)

**Legrosszabb eset:** VASARLAS → UGYFEL → TERROR → (TERROR feltételesen) → BLOKNYOM
Ez 4 egymásba ágyazott modális ablak, mindegyik blokkol.

**Modern megoldás:** Wizard-alapú step-by-step flow egyetlen oldalon, state machine-nel.

### 5.4 A "hardkódolt koordináták" antipattern

**Probléma:** Minden elem abszolút pixel-pozícióban van (Left=, Top=, Width=, Height=). Nincs layout manager, nincs flexbox ekvivalens, nincs responsive.

Következmény:
- 1024×768 under → egyes elemek kilógnak
- 4K felett → az egész UI egyötöd méretben jelenik meg
- Betűméret-növelés (accessibility) → törések

**Modern megoldás:** CSS Flexbox/Grid, relative units (rem/%), media query-k.

### 5.5 A "láthatatlan elsődleges funkció" antipattern

**Probléma:** A rendszer elsődleges üzleti funkciója (devizaváltás) nem szerepel a főmenün. A pénztáros a "Lista és Zárás" menüponton keresztül jut el hozzá.

Ez valószínűleg egy "lista → napi forgalom → új tranzakció" workflow-ból eredő tervezési döntés, amely az idők során megváltozott, de a menüstruktúra nem követte a változást.

**Modern megoldás:** A főképernyőn a devizaváltás prominens helyzetben — quick-access gombok (Vétel, Eladás, Sztornó).

### 5.6 A "beágyazott JPEG háttérkép" antipattern

**Probléma:** A FOGLALO és UGYFEL formok fotográfiákat tartalmaznak base64-kódoltan beágyazva a DFM-be. Ez:
- Megnöveli a DLL fájl méretét (a FOGLALO DFM-ben látható óriási Picture.Data blob)
- A fotók nem kapcsolódnak az üzleti funkcióhoz
- Beágyazott fotó módosításhoz a forráskódot kell újrafordítani

**Modern megoldás:** Külső asset (SVG vagy PNG), CSS background, teljes grafikamentesség lehetséges és javasolt.

### 5.7 A "kriptikus mezőnevek" antipattern

**Probléma:** `WA1..WA6`, `WB1..WB6`, `WD1..WD6`, `VR`, `ER`, `UR`, `FR` — ezek mind belső kódneveket használnak a felhasználói felületen.

A WA/WB/WD prefix valószínűleg: W=Window, A=Amount/Összeg, B=Banknote, D=Darab. Ez fejlesztői naming convention, ami kiszivárg a UI-ba.

**Modern megoldás:** Magyar nyelvű, leíró mezőcímkék: "Összeg (EUR)", "Bankjegy típus", "Darabszám".

### 5.8 A "35 karakter wide nyomtató" legacy antipattern

**Probléma:** A blokknyomtató formátum 39 karakteres sorokban gondolkodik, ESC/POS parancsokkal. Ez LPT1-es párhuzamos portos nyomtatót feltételez.

A `VetelSzamlaNyomtatas`, `EladasSzamlaNyomtatas` stb. eljárások fix szélességű szöveges sorokba "formatálnak" — nem valódi dokumentum-renderelés.

**Modern megoldás:** HTML/CSS nyomtatási template, ESC/POS megtartása hardveres kompatibilitáshoz de logika szétválasztva a megjelenítéstől.

### 5.9 A "XOR titkosítás" biztonsági antipattern

**Probléma:** A logfájlok `chr(255 - ord(karakter))` invertálással "titkosítottak" — ez nem titkosítás, csak invertálás. Bármilyen szövegszerkesztő ANSI dekódolással olvassa a logokat.

Ez egy UI/UX szempontból releváns pont: az "XOR-kódolt napló" megjelenítéshez egy LOGDISP.dll van, ami vizuálisan "visszatérít" — a felhasználó nem tudja közvetlenül olvasni a logokat.

**Modern megoldás:** Strukturált JSON logging, valódi titkosítás (AES), log viewer UI-jal.

### 5.10 A "hardkódolt FTP credentials" antipattern

**Probléma:** A COPY2FTP DLL-ben:
```
_userid := 'ebc-10%';
_ftpPassword := 'klc+45%';
```
Ez a UI/UX szempontból azért releváns, mert a hibakezelési dialógokban ezek megjelenhetnek (pl. "FTP kapcsolódási hiba: ebc-10%@185.43.207.99").

---




---

## S94 7_KOGNITIV_TERHELES_ES_ERGONOMIA

### 7.1 Miller-törvény alkalmazása

A Miller-törvény szerint az emberi rövid távú memória 7±2 elemet képes egyszerre kezelni. A VASARLAS form beviteli területe:
- 6 összegmező + 6 bankjegymező + 6 darabszámmező = **18 mező egyszerre**

Ez háromszorosa az optimálisnak. A pénztáros valójában ritkán tölt ki mind a 6 sort — legtöbbször 1-2 devizanem-sor elegendő. Az összes többi mező vizuális zaj.

**Modern megoldás:** Dinamikus sorkezelés — alapesetben 1-2 sor látható, "+" gombbal bővíthető.

### 7.2 Hick-törvény alkalmazása

A Hick-törvény szerint a döntési idő logaritmikusan nő a lehetőségek számával. A főmenü 4+2 gombja (6 opció) jó. A ZARAS DLL-en belüli almenü azonban (ha megnyílik) valószínűleg 10+ lehetőséget tartalmaz.

### 7.3 Fitts-törvény alkalmazása

A Fitts-törvény szerint a kattintás ideje függ a célterülettől és annak távolságától. A SUPERTSK form gombok:
- Gomb szélességek: mind 297px — ez nagyon bőséges, jó
- Gomb magasságok: 25px — ez **nagyon alacsony** — ujjal nem kattintható, egérrel is nehéz

**Modern megoldás:** Minimum 44px gombmagasság (Apple HIG iránya), touch-kompatibilis méretek.

### 7.4 Billentyűzet-navigáció értékelés

**Pozitív:** End/Escape billentyűk következetesen alkalmazva — ez profi pénztárosi munkamódot segít.

**Negatív:**
- Nincs Tab-sorrend dokumentáció a DFM-ekben
- A `FormKeyDown` eseménykezelők custom logikát implementálnak — ez debug-ban nehézkes
- Nincs keyboard shortcut rendszer (pl. F2=Vásárlás, F3=Eladás, F4=Sztornó)

### 7.5 Error prevention

A jelenlegi rendszer error prevention stratégiái:
- `Surestorno` dupla megerősítés sztornónál ✓
- `UresPenztarControl` üres pénztár ellenőrzés napzárnál ✓
- `MTCNControl` WU ellenőrzés napzár előtt ✓
- TERROR szűrés 300k felett ✓

**Hiányok:**
- Nincs valós idejű összeg-érvényesítés bevitel közben
- Nincs árfolyam-frissítési figyelmeztetés (ha régi árfolyammal dolgozik)
- Nincs "nem mentett adatok" figyelmezetés kilépéskor

---




---

## S95 9_KOMPONENS_KONYVTAR_ES_DESIGN_TOKEN_EK

### 9.1 Tranzakció-összeg kijelző komponens

Ez a legkritikusabb vizuális elem. A pénztárosnak 1 másodperc alatt el kell tudnia olvasni a fizetendő összeget.

```
╔══════════════════════════════════════════════╗
║  FIZETENDŐ                                   ║
║                                              ║
║     125 480 Ft                               ║
║     (48px, Inter Bold, --color-text-primary) ║
║                                              ║
║  Kezelési díj: 500 Ft      Nettó: 124 980 Ft ║
║  (14px, Inter Regular, --color-text-secondary)║
╚══════════════════════════════════════════════╝
```

### 9.2 Devizanem-választó komponens

```
┌────────────────────────────────────────────────────────────┐
│  Devizanem                                                 │
│                                                            │
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐          │
│  │ 🇪🇺 │  │ 🇺🇸 │  │ 🇬🇧 │  │ 🇨🇭 │  │ 🇨🇿 │  │ 🇵🇱 │ ...    │
│  │ EUR│  │ USD│  │ GBP│  │ CHF│  │ CZK│  │ PLN│          │
│  └────┘  └────┘  └────┘  └────┘  └────┘  └────┘          │
│  [KIVÁLASZTVA: EUR]  ──  Aktuális árfolyam: 395.50 Ft/EUR  │
└────────────────────────────────────────────────────────────┘
```

### 9.3 Ügyfél-azonosítás inline banner

```
┌────────────────────────────────────────────────────────────┐
│  ⚠️  AML FIGYELMEZTETÉS                                    │
│                                                            │
│  Az összeg (318 000 Ft) meghaladja a 300 000 Ft limitet.   │
│  Kötelező ügyfél-azonosítás szükséges.                     │
│                                                            │
│  [ AZONOSÍTÁS MEGKEZDÉSE ]   [ Árfolyam módosítás ]        │
└────────────────────────────────────────────────────────────┘
```

### 9.4 Napzárás haladásjelző komponens

```
╔══════════════════════════════════════════════════════════════╗
║  NAPI PÉNZTÁRZÁRÁS — 2026.04.02.                            ║
║                                                             ║
║  Folyamat: 3 / 5                                            ║
║  ████████████████░░░░░░░░░░░░░░░░░  60%                    ║
║                                                             ║
║  ✓  MTCN számok ellenőrzése         OK                      ║
║  ✓  Pénztárzárás címletezése        OK                      ║
║  ⟳  Kezelési díj ellenőrzése        folyamatban...          ║
║  ○  W.U. címletezése                várakozik               ║
║  ○  ÁFA pénztár címletezése         várakozik               ║
║                                                             ║
╚══════════════════════════════════════════════════════════════╝
```

### 9.5 Billentyűzetes navigáció chip-ek

```
[ End = Rögzít ]   [ Esc = Mégse ]   [ F2 = Vásárlás ]   [ F3 = Eladás ]
```

Ezeket a keyboard shortcut-okat a képernyő állandó alap-sávjában kell megjeleníteni (status bar), hogy mindig láthatók legyenek.

---




---

## S96 16_KIEGESZITO_ACCESSIBILITY_ES_WCAG_MEGFELELOSEG

### 16.1 Jelenlegi accessibility állapot

A Delphi 7 Win32 rendszer accessibility szempontból:
- **Screen reader:** Microsoft Active Accessibility (MSAA) minimális szintű, TControl alapú automatikus
- **Keyboard navigation:** Tab sorrend nem dokumentált, de Win32 natívan kezel alapszintű Tab-ot
- **Colour contrast:** A DFM-ekben mért kontrast-arányok:
  - `clYellow` szöveg `clBlack` háttéren: ~19:1 ✓ (kiváló)
  - `clYellow` szöveg `clGray` háttéren: ~5.2:1 ✓ (AA megfelelő)
  - `clWhite` szöveg `clTeal` háttéren: ~4.6:1 ✓ (AA megfelelő)
  - `clNavy` szöveg `16756991` (halvány kék) háttéren: ~8.1:1 ✓ (AA megfelelő)
  - `clSilver` árnyék szöveg bármilyen háttéren: nagyon alacsony kontraszt ✗

### 16.2 WCAG 2.1 AA követelmények a modern rendszerben

| Kritérium | Kategória | Modern rendszer implementáció |
|-----------|-----------|------------------------------|
| 1.1.1 Non-text content | A | Minden ikon alt szöveggel |
| 1.3.1 Info and relationships | A | Szemantikus HTML (label, fieldset) |
| 1.4.3 Contrast (minimum) | AA | 4.5:1 normál szöveg, 3:1 nagy szöveg |
| 1.4.4 Resize text | AA | 200%-ig skálázható layout-törés nélkül |
| 2.1.1 Keyboard | A | Minden funkció billentyűzetről elérhető |
| 2.1.2 No keyboard trap | A | Minden modal Escape-pel bezárható |
| 2.4.3 Focus order | A | Logikus Tab sorrend minden formon |
| 2.4.6 Headings and labels | AA | Leíró mezőcímkék (nem WA1-WA6) |
| 3.3.1 Error identification | A | Valós idejű validáció és hibaüzenet |
| 3.3.2 Labels or instructions | A | Minden mező mellé instrukció |
| 4.1.2 Name, role, value | A | ARIA szerepkörök ahol szükséges |

### 16.3 Kritikus accessibility problémák a DFM-ekben

**Shape-alapú layout → nem hozzáférhető:**
A Delphi `TShape` komponensek vizuális elemek, nem interaktív UI elemek. Ha a layout megjelenítéséhez `TShape` kell (pl. keretek, panelek), azok nem rendelkeznek MSAA megfelelőként, és screen reader-ek számára láthatatlanok.

**Megoldás a modern rendszerben:**
- React komponensek natívan ARIA-kompatibilisek
- Minden `<input>` mező `<label>` párral
- Minden `<button>` önleíró `aria-label`-lel
- Dialog modalok `role="dialog"` és `aria-modal="true"` attribútummal

---




---

## S97 17_KIEGESZITO_MOBIL_ES_ERINTOKEPERNYOS_UX_MEGFONTOLASOK

### 17.1 Jelenlegi rendszer touch-kompatibilitása

Az Anti Valutaváltó rendszer kizárólag egér + billentyűzet interakcióra tervezett. Érintőképernyős eszközön:
- A 25px magas gombok (SUPERTSK) érintővel használhatatlanok
- A TDBGrid kétujjas görgetése nem működik Win32-ben
- Az abszolút pozicionált elemek 4K érintőképernyőn eltörnek

### 17.2 Electron + React érintőképernyős lehetőségek

Az Electron alkalmazás futhat Windows érintőképernyős kioszkon is. Ez lehetővé teszi:
- Tabletes pénztár (pl. iPad Pro + keyboard case)
- Ügyfél-felé fordított érintőképernyős panel
- Remote access (VPN-en keresztüli tablet kapcsolat)

**Minimum touch target méretek:**
- Apple HIG: 44×44pt minimum
- Google Material: 48×48dp minimum
- WCAG 2.5.5 (AAA): 44×44 CSS pixel minimum
- **Javasolt:** 48×48px minden interaktív elem

### 17.3 Érintőképernyős bizonylat-aláírás

Az ügyfél-aláíráshoz jelenleg papír bizonylatot nyomtat és fizikailag aláíratja. Modern alternatíva:

```
┌──────────────────────────────────────────────────────────────────┐
│  ÜGYFÉL ALÁÍRÁSA                                                 │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │                                                            │  │
│  │         [aláírási terület — érintőképernyőn]               │  │
│  │                                                            │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  [ TÖRLÉS ]                             [ ELFOGADOM ✓ ]         │
└──────────────────────────────────────────────────────────────────┘
```

Az elektronikus aláírás JPEG/PNG formátumban menthető a bizonylat adatai mellé az adatbázisba.

**Megjegyzés:** Jogszabályi ellenőrzés szükséges, hogy az elektronikus aláírás elegendő-e a vonatkozó (Kúria, NAV) előírásoknak.

---




---

## S98 18_KIEGESZITO_ADATMEGJELENITESI_MINTAK_ES_TABLAZATOK

### 18.1 Napi forgalom összesítő modern layout

A `TNAPIFORGALOMFORM` (NAPIFORG DLL) a napi devizaforgalmat összesíti. Modern verziója:

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  NAPI FORGALOM ÖSSZESÍTŐ — 2026.04.02.                         [PÉCS-01 pénztár]   │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │ DEVIZA  │ NYITÓKÉSZLET │  VÁSÁROLT  │    ELADOTT  │  EGYÉB     │ ZÁRÓKÉSZLET  │  │
│  │─────────┼──────────────┼────────────┼─────────────┼────────────┼──────────────│  │
│  │ EUR     │   5 000.00   │ +1 280.00  │  -  840.00  │     0.00   │   5 440.00   │  │
│  │ USD     │   2 000.00   │ +  350.00  │  -  200.00  │     0.00   │   2 150.00   │  │
│  │ GBP     │   1 000.00   │ +  100.00  │  -   50.00  │     0.00   │   1 050.00   │  │
│  │ CHF     │     800.00   │      0.00  │  -  100.00  │     0.00   │     700.00   │  │
│  │ CZK     │  50 000.00   │ +5 000.00  │      0.00   │     0.00   │  55 000.00   │  │
│  │ PLN     │   3 000.00   │ +  500.00  │  -  300.00  │     0.00   │   3 200.00   │  │
│  └─────────┴──────────────┴────────────┴─────────────┴────────────┴──────────────┘  │
│                                                                                      │
│  FORINT FORGALOM:                                                                    │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │  Vásárolt devizáért fizetett:    1 850 630 Ft                                  │  │
│  │  Eladott devizáért kapott:         942 180 Ft                                  │  │
│  │  Kezelési díj bevétel:              12 500 Ft                                  │  │
│  │  Nettó pénztárhatás:             +  920 950 Ft  (vásárlás > eladás)            │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  [ Nyomtatás ]    [ Excel export ]    [ PDF mentés ]    [ Bezárás ]                 │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 18.2 Bizonylat keresési képernyő bővített verziója

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  BIZONYLAT KERESŐ                                                                    │
│                                                                                      │
│  ╔═ SZŰRŐK ═══════════════════════════════════════════════════════════════════════╗  │
│  ║                                                                               ║  │
│  ║  Dátum:  [ 2026.04.01 ]  –  [ 2026.04.02 ]    Típus:  [ Minden ▼ ]           ║  │
│  ║  Deviza: [ Minden ▼ ]     Pénztáros: [ Minden ▼ ]                             ║  │
│  ║  Ügyfél: [________________________________]     Összeg min/max: [____] – [____]║  │
│  ║                                                                               ║  │
│  ║              [ KERESÉS ▶ ]    [ Szűrők törlése ]                              ║  │
│  ╚═══════════════════════════════════════════════════════════════════════════════╝  │
│                                                                                      │
│  Találatok: 47 bizonylat                                                            │
│                                                                                      │
│  ┌────────────┬──────────┬────────────┬──────────┬──────────┬──────────┬──────────┐ │
│  │ BIZONYLAT  │ DÁTUM    │    IDŐ     │ TÍPUS    │ DEVIZA   │  ÖSSZEG  │ÜGYFÉL    │ │
│  ├────────────┼──────────┼────────────┼──────────┼──────────┼──────────┼──────────┤ │
│  │ 00123456   │ 04.02.   │ 09:15      │ VÉTEL    │ EUR      │ 126 560  │KISS BÉLA │ │
│  │ 00123457   │ 04.02.   │ 10:22      │ ELADÁS   │ USD      │  45 200  │ —        │ │
│  │ 00123458   │ 04.02.   │ 11:05      │ VÉTEL    │ GBP      │ 201 300  │NAGY MÁRIA│ │
│  │ 00123459   │ 04.02.   │ 11:47      │ WU FOG.  │ USD      │  82 400  │TÓTH PÉTر│ │
│  └────────────┴──────────┴────────────┴──────────┴──────────┴──────────┴──────────┘ │
│                                                                                      │
│  [◀ Előző]   Oldal 1 / 3   [Következő ▶]         [ Export ]   [ Nyomtatás ]        │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---




---

## S99 19_KIEGESZITO_VERZIOKOVETES_ES_AUDIT_TRAIL_UX

### 19.1 Jelenlegi napló rendszer

A legacy rendszer XOR-kódolt naplófájlokat (`TRADELOG\`) és a `LOGDISP.dll` megjelenítőt használja. A naplózás esemény-szintű, de nem kereshető és nem exportálható közvetlenül.

### 19.2 Modern audit trail UX javaslat

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  RENDSZERNAPLÓ ÉS AUDIT TRAIL                                                        │
│                                                                                      │
│  Keresés: [_______________________]   Szint: [Minden ▼]   Dátum: [Ma ▼]            │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │  IDŐ     │ SZINT     │ ESEMÉNY                            │ FELHASZNÁLÓ        │  │
│  │──────────┼───────────┼────────────────────────────────────┼────────────────────│  │
│  │ 09:00:12 │ INFO      │ Pénztár nyitás — KOVÁCS ANNA       │ KOVÁCS ANNA        │  │
│  │ 09:15:33 │ INFO      │ Devizavétel — 320 EUR, 126 560 Ft  │ KOVÁCS ANNA        │  │
│  │ 09:15:35 │ INFO      │ Bizonylat nyomtatva: 00123456      │ KOVÁCS ANNA        │  │
│  │ 10:05:11 │ WARN      │ Árfolyam módosítás: EUR 395.50→393 │ SUPERVISOR         │  │
│  │ 11:22:44 │ INFO      │ Devizavétel — 500 USD, 201 300 Ft  │ KOVÁCS ANNA        │  │
│  │ 11:47:09 │ WARN      │ AML küszöb átlépve — 318 000 Ft    │ KOVÁCS ANNA        │  │
│  │ 11:47:22 │ INFO      │ Ügyfél azonosítás rögzítve         │ KOVÁCS ANNA        │  │
│  │ 13:30:01 │ ERROR     │ WU API kapcsolat megszakadt         │ RENDSZER           │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  [ CSV export ]   [ PDF export ]   [ E-mail küldés ]   [ Bezárás ]                 │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 19.3 Változáskövetés az árfolyamoknál

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  ÁRFOLYAM MÓDOSÍTÁSOK — 2026.04.02.                                                 │
│                                                                                      │
│  ┌──────────┬──────────┬───────────┬───────────┬────────────┬─────────────────────┐ │
│  │ IDŐ      │ DEVIZA   │ ELŐZŐ VÉT.│ ÚJ VÉTELI │ SUPERVISOR │ INDOKLÁS            │ │
│  ├──────────┼──────────┼───────────┼───────────┼────────────┼─────────────────────┤ │
│  │ 08:30:00 │ EUR      │   393.00  │   395.50  │ NAGY PÉTER │ MNB reggeli árfolyam│ │
│  │ 10:05:11 │ EUR      │   395.50  │   393.00  │ NAGY PÉTER │ Piaci korrekcó      │ │
│  │ 14:00:00 │ USD      │   362.00  │   364.50  │ NAGY PÉTER │ Délutáni frissítés  │ │
│  └──────────┴──────────┴───────────┴───────────┴────────────┴─────────────────────┘ │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---




---

## S100 21_KIEGESZITO_RESZLETES_KOMPONENS_SPEC

### 21.1 TransactionAmountDisplay komponens spec

```
Komponens: TransactionAmountDisplay
Props:
  - amount: number           // forint összeg
  - currency: string         // devizanem (pl. "EUR")
  - rate: number             // árfolyam
  - fee: number              // kezelési díj
  - transactionType: 'buy' | 'sell'
  
Megjelenítés:
  - Háttér: transactionType === 'buy' ? --color-buy-light : --color-sell-light
  - Főösszeg: --text-display (48px), --font-bold
  - Mellékletek: --text-sm, --color-text-secondary
  
States:
  - idle: alapállapot
  - calculating: spinner (ha async számítás folyik)
  - warning: ha közel van a 300k limithez (sárga keret)
  - limit-exceeded: ha átlépi a limitet (piros banner)
```

### 21.2 CurrencySelector komponens spec

```
Komponens: CurrencySelector
Props:
  - availableCurrencies: Currency[]    // [{code: 'EUR', name: 'euró', flag: '🇪🇺'}]
  - selectedCurrency: string
  - buyRate: number
  - sellRate: number
  - onSelect: (currency: string) => void
  
Megjelenítés:
  - Grid layout: 4 oszlop, automatikus törés
  - Minden deviza-kártya: 80×60px minimum (touch-compatible)
  - Kiválasztott: --color-primary-light keret, pipa ikon
  - Árfolyam: a kiválasztott deviza alatt azonnal látható

States:
  - default: normál lista
  - selected: kiemelés
  - rate-changed: sárga villanás (ha az árfolyam megváltozott az utolsó 5 percben)
```

### 21.3 DenominationInput komponens spec

```
Komponens: DenominationInput
Props:
  - currency: string
  - denominations: number[]    // [500, 200, 100, 50, 20, 10, 5, 1]
  - onChange: (lines: DenomLine[]) => void

DenomLine:
  - denomination: number    // bankjegy értéke
  - count: number           // darabszám
  - subtotal: number        // számított összrészeg

Megjelenítés:
  - Dinamikus sorok: kezdetben 1-2 sor, "+" gombbal bővíthető
  - Darabszám mező: numeric keyboard, auto-fokusz
  - Részösszeg: automatikusan számolja
  - Összesen sor: vizuálisan kiemelve (bold, larger text)
  
Shortcut:
  - Tab: következő sor darabszám mezőjére ugrik
  - Enter: sor lezárása és következő sor megnyitása
  - Delete: aktuális sor törlése
```

---




<a name="11_KOMMUNIKACIO"></a>

# 11. KommunikĂˇciĂł, integrĂˇciĂłk Ă©s kĂĽlsĹ‘ rendszerek

---


---

## S101 GPT_54_ELEMZĂSE


---

## S102 13_KAMERA_ES_JAVA_ALAPU_ALRENDSZEREK





---


---

## S103 JUNIOR_ELEMZĂSE


---

## S104 8_SZERVER_KOMMUNIKACIO_ES_SZINKRONIZACIO

### 8.1 Központi szerver

- **IP**: `193.68.57.146` (a kódban hardcoded)
- **URL**: `https://193.68.57.146/kupon/as.php`
- Kommunikáció: XML request/reply fájlokon keresztül

### 8.2 FTP szinkronizáció (COPY2FTP DLL)

- **Host**: `185.43.207.99`
- **Port**: `21100`
- **User**: `ebc-10%`
- **Password**: `klc+45%`

A `CsomagKuldes` eljárás:
1. XML request fájl írása (`c:\valuta\temp\request.xml`)
2. Coupon.exe futtatása (XML feldolgozó)
3. Reply XML beolvasása (`c:\valuta\temp\REPLY.XML`)
4. Válasz feldolgozása

### 8.3 Napi mentés (MENTES DLL)

A `TNAPIMENTES` a Firebird .fdb fájlok teljes másolatát készíti:
- `ValutaFdbMentes` — a teljes VALUTA.FDB mentése

---




---

## S105 10_HARDVER_INTEGRACIO

### 10.1 Nyomtatás

- **LPT1 port**: közvetlen parallel port nyomtatás (`AssignFile(_nyomtat,'LPT1')`)
- **Windows nyomtató**: `AssignPrn` (alternatív, PRINTER=1 esetén)
- **ESC/POS parancsok**: `chr(27)+chr(71)` (félkövér), `chr(14)` (dupla szélesség), `chr(27)+chr(97)+chr(5)` (vágás)
- 39 karakter széles blokknyomtató formátum

### 10.2 Szkenner

- SCANNING és UJSCANNER DLL-ek
- Okmány szkennelés és küldés

### 10.3 POS terminál

- OTP DLL: OTP bank POS terminál
- TERMINAL DLL: általános POS kezelés

### 10.4 VFD kijelző

- `_VFD` változó: vevőoldali kijelző támogatás

---



---


---

## S106 ESZTER_ELEMZĂSE


---

## S107 28_E_MAIL_ERTESITES_ENGEDELYEZETT_TRANZAKCIOKNAL

Ha egy tranzakcióhoz engedélyező kellett, az XML e-mail küldés aktiválódik:

```pascal
// VASARLAS/Unit2.pas — Folytatas (~sor 1320)
if _engedelyezo<>'' then begin
  logirorutin(pchar('Mivel volt engedélyező, ezt e-mailben jelzi'));
  MakeXML;
  XMLBemasolas;
end;
```

A címzettek a pénztárkód alapján döntöttek:
```pascal
// VASARLAS/Unit2.pas — MakeXml (~sor 1598)
// Mindig megy:
_mailstring += 'fabulyazsuzsa.eec@gmail.com';

// EBC pénztáraknál (<151) még megy:
_mailstring += 'kosa.zoltan.ebc@gmail.com';
_mailstring += 'nagyannamaria.ebc@gmail.com';

// Expressz pénztáraknál (≥151):
_mailstring += 'batori.monika.ebc@gmail.com';
```

**GDPR kockázat:** E-mail címek hardcoded a forráskódban!

---



---


---

## S108 TAMAS_ELEMZĂSE


---

## S109 3_KOMMUNIKACIOS_PROTOKOLLOK

### 3.1 Kupon XML API (Coupon.exe)

A telefon feltöltés és e-matrica vásárlás kétlépéses XML kommunikációval zajlik:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       KUPON API KOMMUNIKÁCIÓ                            │
│                                                                         │
│  TRADE.EXE / VASARLAS.DLL                                              │
│         │                                                               │
│         │ 1. XML fájl írás                                             │
│         ▼                                                               │
│  c:\valuta\temp\request.xml                                            │
│         │                                                               │
│         │ 2. WinExecAndWait32('c:\valuta\bin\Coupon.exe', sw_normal)   │
│         ▼                                                               │
│  Coupon.exe (Java/külső process)                                        │
│         │                                                               │
│         │ 3. HTTPS POST → https://193.68.57.146/kupon/as.php          │
│         │    (önhitelesített cert, no-verify valószínű)                │
│         ▼                                                               │
│  c:\valuta\temp\REPLY.XML                                              │
│         │                                                               │
│         │ 4. XML reply olvasás                                         │
│         ▼                                                               │
│  CsomagKuldes() → Getmezo() → _reprow[] tömb feldolgozás               │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 3.1.1 Request XML Felépítés

A request XML soronkénti beolvasással töltődik fel `_reqrow[]` tömbbe, majd a `Getmezo()` függvény XML-path nélküli egyszerű keresést végez:

```pascal
// Getmezo() implementáció (TRADE.EXE Unit1.pas)
function TForm1.Getmezo(_mezonev: string): string;
var _wHossz: integer;
    _aktmezo: string;
begin
  result  := '';
  _whossz := length(_mezonev);
  _z      := 1;
  while _z <= _reppieces do begin
    _aktreprow := _reprow[_z];
    _aktMezo   := midstr(_aktreprow, 2, _whossz);  // '<' utáni rész
    if _aktmezo = _mezonev then begin
      _p := 3 + _whossz;
      while _p < 200 do begin
        _asc := ord(_aktreprow[_p]);
        if _asc = 60 then exit;  // '<' záró tag = vége
        result := result + chr(_asc);
        inc(_p);
      end;
      exit;
    end;
    inc(_z);
  end;
end;
```

**Architekturális probléma:** Ez nem valódi XML parser — soronkénti karakteres keresés. Feltételezi, hogy minden XML tag egy sorban van, nincs whitespace tolerancia, nincs namespace kezelés.

#### 3.1.2 Reply XML Mezőnevek (Topup szolgáltatásnál)

A reply feldolgozásából rekonstruált mezőnevek:
```
_xrStatusId             → StatusId
_xrStatusDescription    → StatusDescription
_xrMessageType          → MessageType
_xrAmount               → Amount
_xrPhoneNumber          → PhoneNumber
_xrTransactionId        → TransactionId
_xrTransactionDate      → TransactionDate
_xrOutletAddress        → OutletAddress
_xrProductId            → ProductId
_xrOutletTaxNo          → OutletTaxNo
_xrProductName          → ProductName
_xrOperatorId           → OperatorId
_xrOutletName           → OutletName
_xrReceiptNumber        → ReceiptNumber
_xrCategory             → Category
_xrDurationHUN          → DurationHUN
_xrDurationEng          → DurationEng
_xrRegistrationNumber   → RegistrationNumber
_xrVFD                  → VFD
_xrVTD                  → VTD
_xrCountryName          → CountryName
_xrReferenceId          → ReferenceId
```

### 3.2 FTP Szinkronizáció (WinInet API)

A `COPY2FTP.DLL` és a `PROSBE.DLL` WinInet API-t használ FTP kommunikációra:

```pascal
// COPY2FTP.DLL — teljes FTP feltöltési folyamat
procedure TForm2.FormActivate(Sender: TObject);
begin
  // 1. Adatbázisból beolvassa a célinformációkat
  sql.Add('SELECT * FROM MEDIA');
  _remotedir  := FieldByName('REMOTEDIR').asString;
  _remoteFile := FieldByName('REMOTEFILE').asString;
  _localPath  := FieldByName('LOCALPATH').asString;
  sql.Add('SELECT * FROM HARDWARE');
  _host := FieldByName('HOST').AsString;

  // 2. WinInet kapcsolat felépítése
  _hNet := InternetOpen('Szerverbe',
                        INTERNET_OPEN_TYPE_PRECONFIG,
                        nil, nil, 0);

  // 3. FTP autentikáció
  _hFTP := InternetConnect(_hNet,
                           Pchar(_host),
                           _ftpPort,          // 21100
                           pchar(_userId),    // 'ebc-10%'
                           Pchar(_ftpPassword), // 'klc+45%'
                           INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

  // 4. Könyvtár beállítás
  _siker := FTPSetCurrentDirectory(_hFTP, pchar('\' + _remoteDir));

  // 5. Fájl feltöltés
  _siker := FtpPutFile(_hFTP,
                       pChar(_localPath),
                       pChar(_remoteFile),
                       FTP_TRANSFER_TYPE_BINARY,
                       0);

  // 6. Kapcsolat zárás
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  // 7. Sikeres feltöltés esetén helyi fájl törlése
  if _siker then begin
    SysUtils.DeleteFile(_localpath);
    _mResult := 1;
  end;
end;
```

**Biztonsági problémák:**
- A jelszó (`klc+45%`) plaintext a forrásban és a memóriában
- Nincs TLS/FTPS (INTERNET_FLAG_PASSIVE = egyszerű FTP)
- Port 21100 nem szabványos, tűzfalon speciálisan kell kezelni

### 3.3 Remote Firebird TCP Kapcsolat

```pascal
// VASARLAS.DLL — remote adatbázis kapcsolat felépítése
_remotePath := _host + ':c:\receptor\database\ugyfel' + inttostr(_aktdek) + '.fdb';
// Példa: '193.68.57.146:c:\receptor\database\ugyfel2.fdb'

// A Firebird kliens ezt a formátumot értelmezi:
// <host>:<szerver_oldali_elérési_út>
// Protokoll: Firebird Wire Protocol (port 3050 alapértelmezetten)
```

**Connection string format elemzés:**
```
193.68.57.146:c:\receptor\database\ugyfel2.fdb
│             │
│             └── Szerver oldali abszolút path (Windows)
└── IP cím (nem hostname, nem DNS)
```

A Firebird kliens a 3050-es TCP porton kommunikál alapértelmezetten. Nincs titkosítás, nincs SSL wrapper.

### 3.4 Internet Ellenőrzés

```pascal
// TRADE.EXE — Vaninternet() implementáció
function TForm1.Vaninternet: boolean;
begin
  result := InternetCheckConnection(
    'https://193.68.57.146/kupon/as.php',  // URL
    FLAG_ICC_FORCE_CONNECTION,              // kényszer ellenőrzés
    0
  );
end;
```

**Kritikus architektúrális függőség:** Az alkalmazás egyáltalán nem indul el internet kapcsolat nélkül. Ha a `193.68.57.146` szerver nem elérhető, `Application.Terminate` hívódik.

```pascal
if not Vaninternet then begin
  ShowMessage('NINCS INTERNET !');
  Application.Terminate;
  exit;
end;
```

### 3.5 Terror Szűrés — Remote Firebird Kapcsolat

```pascal
// TERROR.DLL — terrorista szűrési folyamat
_remoteFdbPath := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';

// Csatlakozási kísérlet try-except blokkban
TRY
  Remotedbase.connected := true;
  _vaninternet := True;
EXCEPT
  _vanInternet := False;
end;

// Keresés az UNOLIST táblában
_pcs := 'SELECT * FROM UNOLIST WHERE TERROR_NAME LIKE ' +
        chr(39) + _ugyfelnev + '%' + chr(39);
```

**Betű-kiemelő transzformáció:**
```pascal
function TTERROR.BetuKiemelo(_s: string): string;
// Ékezetes karakterek konvertálása alapbetűre (Á→A, É→E, stb.)
// A terrorizmus lista nem tartalmaz ékezetes neveket
```

### 3.6 Közvetlen Szerver Kommunikáció (RemoteLerendezes)

A VASARLAS.DLL közvetlenül kommunikál a remote Firebird adatbázissal a tranzakció bejelentéséhez:

```pascal
// RemoteLerendezes, RemoteJogiLerendezes, RemoteParancs eljárások
procedure TVasarlasForm.RemoteParancs(_ukaz: string);
begin
  RemoteDbase.Connected := true;
  // ... SQL végrehajtás a remote adatbázison
  RemoteDbase.close;
end;
```

### 3.7 E-Mail Küldés (FOGLALO.DLL)

A FOGLALO.DLL MAPI-t használ e-mail értesítőkhöz:

```pascal
// FOGLALO.DLL uses deklarációban: mapi
procedure TFOGLALO.EmailekKuldese;
// MAPI SimpleMailMessage → Outlook/default email kliens
```

---




---

## S110 FUGGELEK_F_WESTERN_UNION_INTEGRACIO_RESZLETEI

### F.1 WUNION.DLL Adatmodell

```pascal
// Western Union mozgás adatok táblája
WumozgasTabla : TIBTable;
WumozgasDbase : TIBDatabase;

// WUMOZGAS tábla (rekonstruált):
// TIPUS           - 'K'=küldés, 'F'=fogadás
// MTCN            - Money Transfer Control Number (10 jegyű)
// OSSZEG          - összeg (küldött deviza)
// DEVIZANEM       - deviza ISO kód
// HUFOSSZEG       - forintban kifejezett érték
// PLOMBASZAM      - plomba azonosító
// PARTNERFONEV    - partner keresztneve
// PARTNERNEV      - partner vezetékneve
// UGYFELNEV       - ügyfél neve
// DATUM           - tranzakció dátuma
// PENZTAROSNEV    - pénztáros neve
// PENZTAR         - pénztár kódja
// STORNO          - 0=normál, 1=sztornózva
```

### F.2 WU MTCN Ellenőrzés (NAPZAR.DLL)

```pascal
// Napzáráskor kötelező MTCN ellenőrzés:
function TNapzarForm.MTCNControl: boolean;
// Ellenőrzi, hogy minden WU tranzakció MTCN számmal rendelkezik-e
// Hiányzó MTCN esetén a napzárás nem engedélyezett
// Visszatérési érték: True = minden OK, False = van hiányzó MTCN
```

### F.3 WU ÁFA Kezelés (HAVIZAR.DLL)

```pascal
procedure THAVIZARAS.WuAfaforgalom;
// Western Union tranzakciók ÁFA forgalmának összesítése havi záráshoz
// A WU jutalékra ÁFA kötelező (nem mentes mint a devizacsere)
// _kellWestern flag alapján aktiválódik

procedure THAVIZARAS.WesternIras;
// WU rész nyomtatása a havi zárási dokumentumba:
// - Küldési és fogadási forgalom devizanemenkénti bontásban
// - Nettó jutalék + ÁFA
// - MTCN összesítő
```

---



---


---

## S111 GABOR_ELEMZĂSE


---

## S112 14_KIEGESZITO_WESTERN_UNION_ES_OTP_TERMINAL_UX

### 14.1 Western Union integráció felhasználói élmény (as-is)

A `WUNION` DLL (`TWesternUnionForm`) a WU pénzátutalási szolgáltatást kezeli. Jellemzői a DFM és kódelemzés alapján:

**Jelenlegi flow:**
1. WU menüpont → WUNION.dll ShowModal
2. Küldés vagy fogadás kiválasztása
3. MTCN szám bevitele (fogadásnál)
4. Összeg és devizanem
5. Küldőnél: kedvezményezett neve, ország, összeg
6. WU bizonylat nyomtatás
7. Napzárnál kötelező MTCN ellenőrzés (`MTCNControl`)

**UX problémák:**
- A WU flow teljesen elszigetelt a devizaváltástól — a felhasználó nem látja egyszerre a napi WU és devizaforgalmat
- Az MTCN számok kézi bevitele hibalehetőség (12 karakteres szám)
- Nincs keresés a korábbi WU tranzakciókban a pénztáros képernyőjéről

**Modern javaslat:**

```
┌──────────────────────────────────────────────────────────────────┐
│  WESTERN UNION UTALÁS                        [WU logo]           │
│                                                                  │
│  Típus:  ( ●) Pénz küldés    ( ) Pénz fogadás                   │
│                                                                  │
│  ──── FOGADÁS ESETÉN ────────────────────────────────────────    │
│                                                                  │
│  MTCN szám: [ _ _ _ _ _ _ _ _ _ _ _ _ ]                        │
│              (automatikus formázás: ####-####-####)              │
│                                                                  │
│  [ KERESÉS ▶ ]                                                   │
│                                                                  │
│  Eredmény (WU API visszajelzés):                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Küldő:         JOHN SMITH (USA)                         │   │
│  │  Összeg:        USD 500.00                               │   │
│  │  HUF egyenérték: 194 750 Ft (395.50 árfolyamon)         │   │
│  │  Állapot:       ✓ Fizethető                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Kedvezményezett neve: [______________________]                  │
│  Okmányszám:           [______________________]                  │
│                                                                  │
│         [ KIFIZETÉS ✓ ]              [ MÉGSE ✗ ]                │
└──────────────────────────────────────────────────────────────────┘
```

**Javítások:**
- MTCN szám automatikus formázása (4-4-4 blokkok) → kevesebb begépelési hiba
- WU API azonnali visszajelzés (nem szükséges külön lépés)
- Kedvezményezett adatai kitöltve az API válaszból (ha elérhető)

### 14.2 OTP terminál integráció UX

Az `OTP` DLL (`TOTPTERM`) az OTP POS terminál integrációját kezeli. A rendszer `OtpTermStorno` és `OtpAruVisszavet` eljárásokkal is rendelkezik — ezek a kártyás tranzakciók sztornójához szükségesek.

**UX kihívás:** A POS terminál fizikailag különálló eszköz, de logikailag a szoftverrel szinkronban kell lennie. Ha a terminál "elfogad", de a szoftver "elutasít" (pl. Firebird írás hiba), inkonzisztens állapot keletkezik.

**Modern javaslat:**
- POS terminál státusz-indikátor a status bar-ban (zöld: online, piros: offline)
- Sikeres kártyás tranzakció után automatikus bizonylat-rögzítés (nem kézi)
- Inkonzisztencia esetén automatikus sztornó-ajánlat

```
[●  OTP Terminál: ONLINE]   [Utolsó tranzakció: 09:15 — 45 200 Ft — ELFOGADVA]
```

---




<a name="12_TELEPITES"></a>

# 12. TelepĂ­tĂ©s, ĂĽzemeltetĂ©s Ă©s konfigurĂˇciĂł

---


---

## S113 GPT_54_ELEMZĂSE


---

## S114 8_MENTES_ARCHIVALAS_FRISSITES



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





---


---

## S115 JUNIOR_ELEMZĂSE


---

## S116 11_KONFIGURACIO

### 11.1 Hardcoded értékek

```pascal
_host            := '185.43.207.99';     // FTP szerver
_ftpPort         := 21100;
_userid          := 'ebc-10%';
_ftpPassword     := 'klc+45%';
_requestPath     := 'c:\valuta\temp\request.xml';
_replyPath       := 'c:\valuta\temp\REPLY.XML';
_javaprog        := 'c:\valuta\bin\Coupon.exe';
_tradeLogDir     := 'C:\VALUTA\TRADELOG';
_ipcim           := '193.68.57.146';
_url             := 'https://193.68.57.146/kupon/as.php';
```

### 11.2 INI fájlok

A CIMLET modul `CiminiBeolvasas` / `SaveCimini` — címletbeállítások INI-ben

### 11.3 Adatbázis-alapú konfiguráció

- PARAMETERS tábla: terminálID, username, jelszó, utolsó sorszámok
- HARDWARE tábla: nyomtató típus
- PENZTAR tábla: pénztárnév, cím, kód

---



---


---

## S117 TAMAS_ELEMZĂSE


---

## S118 7_TELEPITESI_ES_UZEMELTETESI_MODELL

### 7.1 Könyvtárstruktúra (Telepített Rendszer)

```
C:\
└── VALUTA\
    ├── bin\                    ← Futtatható fájlok és DLL-ek
    │   ├── TRADE.EXE           ← Fő alkalmazás
    │   ├── Coupon.exe          ← Kupon API kommunikátor (Java?)
    │   ├── valto.exe           ← Verziófrissítő
    │   ├── ELADAS.dll          ← Deviza eladás
    │   ├── VASARLAS.dll        ← Deviza vásárlás
    │   ├── STORNO.dll          ← Sztornó
    │   ├── NAPZAR.dll          ← Napi zárás
    │   ├── HAVIZAR.dll         ← Havi zárás
    │   ├── BLOKNYOM.dll        ← Nyomtatás
    │   ├── TERROR.dll          ← Terror szűrés
    │   ├── ... (+100 DLL)      ← Összes üzleti modul
    │   └── Super.dll           ← Supervisor hitelesítés
    │
    ├── database\               ← Adatbázisok
    │   ├── valuta.fdb          ← Firebird törzsadatok
    │   └── trade.fdb           ← Firebird tranzakciók
    │
    ├── temp\                   ← XML kommunikáció
    │   ├── request.xml         ← Kupon API kérés (dinamikus)
    │   └── REPLY.XML           ← Kupon API válasz (dinamikus)
    │
    ├── TRADELOG\               ← XOR kódolt naplók
    │   ├── LOG2601.dat         ← Napi logfájlok (LOGYYYYMMDD.dat)
    │   └── ...
    │
    ├── mentes\                 ← Mentések
    │   └── lastgood\
    │       └── valuta.fdb      ← Utolsó sikeres mentés
    │
    └── aktlst.txt              ← Nyomtatási buffer (dinamikus)

C:\
└── receptor\
    └── database\
        ├── TERRORISTS.FDB      ← Terror szankciós lista
        ├── ugyfel2.fdb         ← Ügyfél adatbázis (2020-as évtized)
        └── kisugyfel.fdb       ← Kis ügyfelek
```

### 7.2 Verziófrissítés (VERZFRIS.DLL)

```pascal
// VERZFRIS.DLL — automatikus frissítési folyamat
procedure TVFriss.FormActivate(Sender: TObject);
begin
  AlapadatBeolvasas;  // HARDWARE tábla → _host, _penztarkod

  // 1. FTP-ről letöltött frissítő futtatása szinkron módon
  _PCS := 'c:\valuta\bin\valto.exe';
  _pacs := pchar(_pcs);
  WinExecAndWait32(_pacs, sw_normal);

  // 2. Regisztráció a szerverre (időbélyeg + pénztár kód)
  FrissitoIdoBekuldes;

  // 3. Verzió rögzítése az adatbázisban
  _pcs := 'UPDATE HARDWARE SET VERZIO=' + _aktVerzio;
  ValutaParancs(_pcs);

  // 4. NAV sorszám beállítás
  NavSorszamBeiro;
end;
```

A `valto.exe` feltehetőleg FTP-ről letölti az új DLL-eket és a `c:\valuta\bin\` alá másolja. Ez a folyamat nincs kriptográfiai ellenőrzéssel (signature, hash) védve — supply chain attack vektor.

### 7.3 Napi Mentés (MENTES.DLL)

```pascal
// MENTES.DLL — ValutaFdbMentes()
procedure TNapiMentes.ValutaFdbMentes;
begin
  _valpath  := 'c:\valuta\database\valuta.fdb';
  _savePath := 'c:\valuta\mentes\lastgood\valuta.fdb';

  if fileExists(_savePath) then sysutils.DeleteFile(_savepath);
  copyfileto(_valpath, _savepath);  // Egyszerű fájl másolás (nem Firebird backup!)
end;
```

**Kritikus probléma:** Ez nem Firebird `gbak` backup — hanem az élő adatbázisfájl közvetlen másolása. Ha tranzakció közben fut, az adatbázis inkonzisztens lehet. A helyes módszer: `gbak -b` (Firebird backup utility).

#### Mentés utáni VTEMP bejegyzés:
```pascal
_pcs := 'DELETE FROM VTEMP';
ValutaParancs(_pcs);

_pcs := 'INSERT INTO VTEMP (DATUM, NEVTABLA) VALUES (' +
        chr(39) + _MAINAP + chr(39) + ',' +
        chr(39) + 'NAPI' + chr(39) + ')';
ValutaParancs(_pcs);

sendokmanyrutin;  // Okmány küldés a mentés után
```

### 7.4 Archivális Logika

```pascal
// TRADE.EXE — Archivalo()
// Törli az előző év TRADyymm tábláit
// Például 2026-ban: TRAD2501, TRAD2502, ..., TRAD2512 kerülnek törlésre
// Implementáció: DROP TABLE TRAD[előző_év][01..12]
```

### 7.5 HaviTradeControl — Dinamikus Tábla Létrehozás

```pascal
// TRADE.EXE — HaviTradeControl()
// Aktuális hónap tábla neve: 'TRAD' + rightstr(inttostr(_aktev),2) + nulele(_aktho)
// Például 2026 február: 'TRAD2602'
// Ha nem létezik → MakeTradeTabla()

procedure TForm1.MakeTradeTabla;
// CREATE TABLE TRAD[yymm] (
//   TIPUS CHAR(1), BIZONYLATSZAM CHAR(8), ...
// )
```

### 7.6 Konfigurációs Modell

```
Konfiguráció forrásai (prioritás sorrendben):
1. Hardcoded konstansok (legmagasabb prioritás - NEM felülírható)
   - FTP host, port, user, password
   - Coupon.exe elérési út
   - Adatbázis elérési utak
   
2. TRADE.FDB / PARAMETERS tábla
   - TERMINALID, USERNAME, JELSZO
   - LASTMATRICA, LASTTELEFON, LASTTELEFON
   
3. VALUTA.FDB / HARDWARE tábla
   - HOST (remote szerver IP)
   - PRINTER típus
   - MEGNYITOTTNAP
   - Modul kapcsolók (KELLMATRICA, KELLWESTERN, stb.)
   
4. VALUTA.FDB / PENZTAR tábla
   - Pénztár neve, cím, kód, szám
   
5. INI fájlok (opcionális)
   - CIMLET.ini (CiminiBeolvasas/SaveCimini — CIMLET.DLL)
```

---




<a name="13_TESZTELES"></a>

# 13. TesztelhetĹ‘sĂ©g Ă©s tesztstratĂ©gia

---


---

## S119 ESZTER_ELEMZĂSE


---

## S120 54_TESZTELHETOSEG

### 5.4.1 Automatizált tesztek hiánya

A teljes kódbázisban **EGYETLEN** automatizált teszt sincs. Nincs:
- Unit test
- Integrációs teszt
- Regressziós teszt
- UI teszt

### 5.4.2 Tesztelhetőségi akadályok

| Akadály | Leírás | Hatás |
|---------|--------|-------|
| Globális állapot | 150+ globális változó per DLL | Izolált tesztelés lehetetlen |
| Adatbázis-függőség | Minden logika Firebird lekérdezésen alapul | Mock-olás komplex |
| UI-logika összefonódás | Üzleti logika a Form event handlerekben | Headless tesztelés lehetetlen |
| `ShowModal` DLL hívás | Minden DLL modális ablakot nyit | Automatizált futtatás nehéz |
| Fix fájl útvonalak | `c:\valuta\*` hardcoded | Párhuzamos tesztelés lehetetlen |
| Remote szerver függőség | Központi Firebird szerver szükséges | Offline tesztelés lehetetlen |

### 5.4.3 A legtesztelhetőbb komponensek

| Komponens | Tisztaság | Tesztelhetőség |
|-----------|-----------|----------------|
| `Kerekito` | Tiszta függvény (int → int) | ★★★★★ — triviálisan tesztelhető |
| `Betukiemelo` | Tiszta függvény (string → string) | ★★★★★ |
| `ForintForm` | Tiszta függvény (int → string) | ★★★★★ |
| `Elokieg` | Tiszta függvény (string, int → string) | ★★★★★ |
| `GetKezelesidij` | Adatbázis-függő | ★★☆☆☆ |
| `GetTranztip` | Adatbázis + remote | ★☆☆☆☆ |
| Teljes tranzakció | DB + DLL + szerver + nyomtató | ☆☆☆☆☆ |



---


---

## S121 TAMAS_ELEMZĂSE


---

## S122 8_TESZTELHETOSEGI_ELEMZES

### 8.1 Jelenlegi Tesztelhetőségi Állapot

Az alkalmazás **rendkívül nehezen tesztelhető** a következő okok miatt:

#### 8.1.1 Architektúrális Tesztelési Akadályok

```
1. NINCS DEPENDENCY INJECTION
   - Minden DLL közvetlen adatbázis-kapcsolatot nyit
   - Nincs service layer, nincs interface
   - Mock adatbázis létrehozása lehetetlen az interfész nélkül

2. NINCS SZÉTVÁLASZTÁS (Separation of Concerns)
   - UI, üzleti logika és adatbázis hozzáférés egyetlen Form osztályban
   - BizRegiszter() = DB write + bizonylat logika + VTEMP manip
   - TestUnit2.FormActivate() esetenként 50+ oldal üzleti logikát tartalmaz

3. VTEMP GLOBÁLIS ÁLLAPOT
   - Nem szálbiztos
   - Singleton anti-pattern
   - Párhuzamos tesztelés lehetetlen

4. HARDCODED FÁJL ÚTVONALAK
   - 'c:\valuta\' mindenhol
   - Nem konfigurálható tesztkörnyezet
   - LPT1 nyomtató megléte szükséges (vagy Windows spooler)

5. GLOBÁLIS VÁLTOZÓK
   - 200+ globális változó (unit-szintű singleton state)
   - Teszt után nehéz visszaállítani az állapotot
   - Race condition kockázat (bár single-thread Win32)

6. INTERNET KÖTELEZŐ
   - Vaninternet() fail → Application.Terminate
   - Mock internet kapcsolat nem lehetséges
   - Integration test kizárólag live szerveren
```

#### 8.1.2 UI-Tesztelési Akadályok

```
1. SHOWMODAL ANTI-PATTERN
   - Minden DLL ShowModal()-lal hívódik
   - UI teszt (Playwright/Selenium) nem tudja kezelni a modális dialógusokat
   - Win32 API UIAutomation szükséges (pl. WinAppDriver)

2. HARDCODED ABLAKMÉRET
   - Form1.Height = 768, Width = 1024
   - Monitor mérettől függő pozicionálás
   - CI/CD headless teszt lehetetlen

3. TIMER-ALAPÚ INICIALIZÁCIÓ
   - InditoTimer → aszinkron indítás
   - Teszt nem tudja tudni mikor kész az alkalmazás
   - Csak polling-gal megoldható

4. KÖZVETLEN LPT1 / AssignPrn HÍVÁSOK
   - Nyomtató nélküli tesztkörnyezetben hibát dob
   - Nincs nyomtató-mockja
```

### 8.2 Tesztelhetőségi Mérőszámok (Becsült)

| Metrika | Érték | Megjegyzés |
|---------|-------|-----------|
| Unit tesztelhetőség | ~5% | Szinte kizárólag utility függvények (FtForm, Nulele, stb.) |
| Integration tesztelhetőség | ~20% | Live DB és live kupon API szükséges |
| E2E tesztelhetőség | ~40% | Win32 UI automation lehetséges |
| Mockability | ~2% | Hardcoded dependenciák miatt |
| Test isolation lehetőség | ~5% | Globális állapot miatt |

### 8.3 Tesztelhető Komponensek (Izolálható)

#### 8.3.1 Utility Függvények (100% tesztelhető)

```pascal
// Ezek tisztán funkcionális, mellékhatásmentes függvények:
FtForm(_ar: integer): string          // Forint formázás
Nulele(_b: byte): string              // Nullával padding
HunDateToStr(_caldat: TDateTime): string  // Dátum formázás
FtForm(_ar: integer): string          // Összeg formázás
Elokieg(_s: string; _h: byte): string // Szöveg bal igazítás + kiegészítés
Kerekito(_int: integer): integer      // Kerekítési logika
Scandnem(_dn: string): byte           // Devizanem keresés a tömbben
Evaulate(_hxj: string): string        // Jelszó XOR dekódolás
Kodxor(_s: string): string            // Log XOR transzformáció
GetNapdiff(_n1, _n2: string): extended // Napok különbsége
```

#### 8.3.2 Algoritmusok (Tesztelendő migrációban)

```
1. Kerekítési algoritmus (Kerekito)
   - Input: integer forint összeg
   - Szabály: 1-2→0, 3-7→5, 8-9→10 (utolsó jegy)

2. Sávos kezelési díj (GetKezelesiDij)
   - Input: összeg integer
   - Output: kezelési díj integer
   - _kdij[], _tranzsav[] tömbök alapján

3. Bizonylatsorszám generálás (GetBizonylatSzam)
   - LASTMATRICA / LASTTELEFON inkrementálás
   - 8 jegyű formátum

4. Árfolyam számítás
   - Netto: sum(bankjegy[i] * arfolyam[i])
   - Fizetendő: netto + kezelési díj ± kerekítés

5. XOR jelszó kódolás/dekódolás
   - f(x) = 255 - ASCII_CODE(char)
   - Self-inverse: f(f(x)) = x
```

### 8.4 Tesztstratégia a Migrációhoz

#### 8.4.1 Fázis 1: Legacy Golden Master Tesztek

Az első lépés **nem** a unit teszt írása, hanem a legacy rendszer kimenetének rögzítése:

```
Golden Master Módszer:
1. Valós adatokkal futtatni minden tranzakció típust
2. Rögzíteni a kimenetet (bizonylat tartalma, DB állapot változás)
3. A modern rendszer kimenete ezt kell megismételje

Rögzítendő kimenetek:
├── Bizonylat szövege (minden típusra)
├── DB INSERT/UPDATE SQL utasítások (Firebird trace log)
├── VTEMP tartalom egyes lépések után
├── FTP küldött fájl tartalom
└── Nyomtatói output (c:\valuta\aktlst.txt)
```

#### 8.4.2 Fázis 2: Algoritmus Unit Tesztek (New System)

```java
// Migrált rendszerben — JUnit 5 példák
@Test
void testForintKerekites() {
    // Legacy szabály: Kerekito() → 5 Ft-os szabály
    assertThat(roundToFive(1)).isEqualTo(0);
    assertThat(roundToFive(2)).isEqualTo(0);
    assertThat(roundToFive(3)).isEqualTo(5);
    assertThat(roundToFive(7)).isEqualTo(5);
    assertThat(roundToFive(8)).isEqualTo(10);
}

@Test
void testBizonylatsorszamFormatum() {
    // 8 jegyű, nullával padded
    assertThat(formatBizonylat(1)).isEqualTo("00000001");
    assertThat(formatBizonylat(12345678)).isEqualTo("12345678");
}

@Test
void testXorDecoding() {
    // Evaulate() reverse engineering
    String encoded = "$...";  // DB-ből vett érték
    assertThat(decode(encoded)).isEqualTo("expectedPassword");
}
```

#### 8.4.3 Fázis 3: Integration Tesztek (DB Szintű)

```
Integration teszt stratégia:
1. Firebird test DB instance (ugyanaz a séma)
2. VTEMP előfeltétel adatok betöltése
3. Service metódus hívása
4. VTEMP és DB állapot ellenőrzése

Kritikus tesztelendő folyamatok:
├── Devizavásárlás teljes tranzakció (VTEMP in/out)
├── Napzárás szekvencia (havigyujtok feltöltés)
├── Sztornó (EllenTranzakcio + ValutaStorno)
├── Terror szűrés (UNOLIST keresés)
└── Bizonylat sorszám konzisztencia
```

#### 8.4.4 Fázis 4: E2E Tesztek (Modern Rendszer)

```
Playwright / Cypress E2E tesztek a modern React UI-hoz:
1. Devizavásárlás teljes folyamat
2. Napzárás UI workflow
3. Ügyfélkezelés form kitöltés
4. Bizonylat megjelenítés
5. Havi zárás riport generálás
```

### 8.5 Kritikus Tesztelési Területek

| Terület | Kockázat | Teszt típus | Prioritás |
|---------|----------|-------------|-----------|
| Kerekítési algoritmus | Pénzügyi hiba | Unit | KRITIKUS |
| Sávos kezelési díj | Pénzügyi hiba | Unit | KRITIKUS |
| 300k limit kezelés | Jogi megfelelőség | Integration | KRITIKUS |
| Terror szűrés | Jogi megfelelőség | Integration | KRITIKUS |
| Bizonylat sorszám | Adatintegritás | Integration | MAGAS |
| VTEMP adatáramlás | Funkcionális hiba | Integration | MAGAS |
| Napzárás konzisztencia | Pénzügyi hiba | E2E | MAGAS |
| Sztornó ellentétes tranzakció | Pénzügyi hiba | E2E | MAGAS |

---




---

## S123 VEGSO_OSSZEFOGLALO_TESZTELESI_PRIORITASOK

### Kritikus Üzleti Folyamatok Tesztelési Sorrendje

A migrációs projekt sikerességéhez az alábbi sorrendben kell a teszteket elkészíteni és validálni:

**1. prioritás — Pénzügyi pontosság (törvényi kötelezettség):**
- Kerekítési algoritmus minden összeghatáron
- Sávos kezelési díj minden konfigurációban
- Árfolyam számítás (netto = Σ bankjegy × árfolyam)
- Fizetendő = netto + kezelési díj ± kerekítés

**2. prioritás — Bizonylati pontosság (jogszabályi előírás):**
- Bizonylat fejléc (cégnév/adószám a penztarszam alapján)
- 8 jegyű bizonylat sorszám konzisztencia
- ÁFÁs számla mezők (matrica, telefon)
- Sztornó bizonylat helyessége

**3. prioritás — Adatintegritás (adatbázis konzisztencia):**
- TRADyymm → HAVIFEJTABLA/HAVITETELTABLA migráció
- Napzárás utáni készlet helyessége
- Sztornó ellentétes tranzakció
- Bizonylat sorszám gap-mentesség

**4. prioritás — Jogi megfelelőség (AML/pénzmosás):**
- 300.000 Ft feletti tranzakcióknál kötelező ügyfél azonosítás
- Terror szűrés érzékenysége (ékezet nélküli keresés)
- Közszereplő nyilatkozat triggerelése
- Jogcím nyilatkozat triggerelése

**5. prioritás — Rendszer stabilitás:**
- Egyidejű tranzakciók (a modern rendszerben már nem single-thread)
- Adatbázis tranzakció konzisztencia (ACID)
- Rollback hibás tranzakció esetén
- Hálózat kiesés kezelése (nem csak Application.Terminate!)

---

> **Dokumentum vége**  
> **Verzió:** 1.0  
> **Létrehozva:** 2026-04-02  
> **Következő lépés:** Eszter review + Bence security baseline futtatás a migrációs tervdokumentumon

[TASK_COMPLETE]




<a name="14_KODMINOSEG"></a>

# 14. KĂłdminĹ‘sĂ©g, duplikĂˇciĂł Ă©s karbantarthatĂłsĂˇg

---


---

## S124 ESZTER_ELEMZĂSE

# 5. KÓDMINŐSÉG ÉS KOCKÁZATOK




---

## S125 51_DUPLIKACIO_A_LEGKOMOLYABB_PROBLEMA

### 5.1.1 VASARLAS vs ELADAS duplikáció

A két fő tranzakciós modul (VASARLAS és ELADAS) a kód ~70%-ban azonos, másolással készültek:

**Azonos függvények (teljes másolat):**
- `Kerekito` — 5 Ft-os kerekítés
- `GetKezelesidij` — kezelési díj kalkuláció
- `KezdijTablaBeolvasas` — sávos díjtábla betöltése
- `GetBizonylatszam` — bizonylat sorszám generálás
- `GetDnemAdatok` — devizanem adatok betöltése
- `VanIlyenDnem` — dupla devizanem ellenőrzés
- `GetTetelsor` — tétel sor keresése
- `GetSajatHataskoru` — SHK kedvezmény ellenőrzése
- `Ujraszamolas` — számla újrakalkuláció
- `SorbeirasVtempbe` — VTEMP tábla írás
- `ValtozokNullazasa` — változók nullázása
- `TombBetoltes` — tömb inicializálás
- `TablaNullazas` — tábla nullázás
- `ForintForm` — formázás
- `Elokieg` — string formázás
- `Nulele` — nulla-kiegészítés
- `ArfolyamotModosit` — árfolyam módosítás
- `MakeXml` — XML e-mail generálás
- `XMLBemasolas` — XML FTP-re másolás
- `RemoteLerendezes` — szerver szinkronizáció
- `KisugyfelLerendezes` — kisügyfél adatok frissítése

**Eltérő elemek:**
- `GetDnemAdatok` — VASARLAS a VÉTELI, ELADAS az ELADÁSI árfolyamot olvassa
- Eladásban: `GetTranzdij` extra függvény (kezelési díj kedvezménnyel)
- Eladásban: `KeszletKontrol` — deviza készlet ellenőrzés
- Eladásban: `Getfizetoeszkoz` — fizetőeszköz (készpénz/bankkártya)
- Eladásban: `LimitDisplay`, `MaradtLepteto` — konverzió limites kezelése
- Eladásban: OTP terminál integráció
- Eladásban: `_savos` flag, `SetRate` típus kezelés

**Becslés:** ~3500 sor duplikált kód a két modulban.

### 5.1.2 Kockázat: eltérésbugok

Az ELADAS modulban kikommentezett (`(* ... *)`) sávos díjtábla azt mutatja, hogy volt egy korábbi fix díjstruktúra, ami VASARLAS-ban nincs benne. Ez azt jelenti, hogy a modulok fejlesztése aszinkron történt — az egyik modul frissítése nem mindig tükröződött a másikban.




---

## S126 52_GLOBALIS_ALLAPOTKEZELES

### 5.2.1 Globális változók tömege

Mindkét tranzakciós modul ~150+ globális (unit-szintű) változót használ. Példa a VASARLAS modulból:

```pascal
var
  // 80+ string változó:
  _aktdatum, _aktidos, _aktpenztarszam, _plombaszam, _lastdatum: string;
  _bizonylatszam, _trbpenztar, _ugyfeltipus, _tranzstring, _ugyfelcim: string;
  _megnyitottnap, _adoszam, _irszam, _varos, _utca: string;
  // ... ~60 további string
  
  // 30+ integer változó:
  _kezdijengedmenytip, _kezelesidij, _fixKezelesiDij, _minkezdij: integer;
  _mresult, _origkezdij, _fizetendo, _evimax, _hetift: integer;
  // ... ~20 további integer
  
  // 15+ byte változó:
  _kulfoldi, _lastsor, _ratetype, _tetel, _fizetoeszkoz: byte;
  // ... ~10 további byte
  
  // 10+ boolean változó:
  _ezKonverzio, _ezegyedikezdij, _securlevel: boolean;
  // ... ~7 további boolean
  
  // Tömbök:
  _wd, _wa, _wb: array[1..6] of TEdit;
  _wbankjegy, _wertek: array[1..6] of Integer;
  _kdij: array[1..23] of integer;
  _tranzsav: array[1..23] of integer;
```

### 5.2.2 VTEMP mint globális állapottár

A `VTEMP` tábla az adatbázisban lényegében egy **globális struct/record**:

```
VTEMP tábla mezők (a kódból rekonstruálva):
  DATUM, IDO, TIPUS, KULFOLDI,
  UGYFELTIPUS, UGYFELSZAM, SECURLEVEL,
  NETTO, FIZETENDO, KEZELESIDIJ,
  BIZONYLATSZAM, KONVERZIO, STORNO,
  TETEL, ELOJEL, PENZTARKOD,
  STORNOBIZONYLAT, SZALLITONEV, PLOMBASZAM,
  MEGJEGYZES, COPYINDOK, STORNOINDOK,
  TARSPENZTARNEV, FIZETOESZKOZ,
  RECNUMS, ZCOUNTS, KEREKITES,
  FORRAS, ENGEDELYEZO,
  KEDVEZMENYESARFOLYAM, MEGBIZOSZAM,
  KOZSZEREPLO, KARTYASZAM,
  VALUTANEM, ARFOLYAM, BANKJEGY,
  FORINTERTEK, EREDETIARFOLYAM,
  SORENGEDMENY, ELSZAMOLASIARFOLYAM,
  UGYFELNEV, UGYFELCIM, NEVTABLA,
  SORSZAM, RATETYPE,
  OSSZESFORINTERTEK
```

**Probléma:** Egyetlen globális sor szolgál az összes DLL közötti kommunikációra. Egy DLL felülírja a VTEMP-et, a másik DLL onnan olvassa. Ha bármelyik DLL rosszul ír vagy nem törli a VTEMP-et, az a következő tranzakciót is elronthatja.

```pascal
// VASARLAS/Unit2.pas — FormActivate — mindig törli a VTEMP-et:
ValutaParancs('DELETE FROM VTEMP');
```

### 5.2.3 Adatbázis-alapú IPC (Inter-Process Communication)

A DLL-ek kizárólag adatbázison keresztül kommunikálnak:
1. **Hívó DLL** → VTEMP táblába ír inputot
2. **Hívott DLL** → VTEMP-ből olvas, feldolgoz
3. **Hívott DLL** → VTEMP-be ír outputot
4. **Hívó DLL** → VTEMP-ből olvassa az eredményt

Ez lassú, de megbízható (tranzakcionális), és nem igényel memóriamegosztást a DLL-ek között.




---

## S127 55_KARBANTARTHATOSAG

### 5.5.1 Kódbázis méret

| Metrika | Érték |
|---------|-------|
| Teljes fájlszám | ~6972 |
| Pascal forrásfájlok | ~420 .pas |
| Form fájlok | ~419 .dfm |
| DLL projektek | ~131 |
| Becsült összesített LOC | ~200.000+ sor |

### 5.5.2 Kódszervezési problémák

1. **Flat struktúra:** Minden DLL egyetlen `Unit2.pas` fájlban van — nincs moduláris szervezés
2. **Névkonvenció:** Magyar + angol keverék, globális változók `_` prefixszel
3. **Kommentelés:** Vegyes — néhány függvény jól kommentelt, mások egyáltalán nincsenek
4. **Error handling:** Minimális — `ShowMessage` + `exit` minta, nincs try/except
5. **Kódolás:** Windows-1250 (magyar ékezetek), ami a kommenteket olvashatatlanná teszi modern editorokban

### 5.5.3 Pozitív kódminőségi elemek

Nem minden rossz:
- **Következetes minta:** Minden DLL azonos architektúrát követ (Create → ShowModal → Free)
- **Naplózás:** A `logirorutin` konzisztensen használt az összes modulban
- **Moduláris építkezés:** A DLL-es felépítés lehetővé tette a független frissítéseket
- **Kommentezett flow:** A VASARLAS/ELADAS modulok a fő folyamatot kommentekkel dokumentálják
- **Fázisokra bontás:** A tranzakció jól definiált fázisokra osztott (bevitel → ellenőrzés → ügyfél → megerősítés → véglegesítés)

---




---

## S128 75_MIGRACIOS_KOCKAZATOK

### 7.5.1 Legmagasabb kockázatú területek

| # | Kockázat | Hatás | Valószínűség | Mitigáció |
|---|----------|-------|-------------|-----------|
| 1 | **Kerekítési eltérés** | Pénzügyi pontatlansság, ügyfél reklamáció | Közepes | Karakterszintű unit tesztek az eredeti algoritmus alapján |
| 2 | **AML küszöb kihagyás** | Jogszabálysértés, MNB bírság | Magas | 1:1 üzleti szabály reprodukció + regressziós teszt |
| 3 | **Bizonylat formátum eltérés** | NAV/MNB vizsgálati probléma | Közepes | Pixel-pontos összehasonlítás eredeti vs. új bizonylat |
| 4 | **Adatvesztés migráció közben** | Üzleti adatfolytonosság elvesztése | Magas | Párhuzamos üzem 3+ hónapig |
| 5 | **Havi tábla struktúra eltérés** | Zárási hibák | Közepes | Teljes havi ciklus tesztelése |
| 6 | **Konverzió kettős számlázás** | Pénzügyi veszteség | Alacsony | Atomi tranzakció garantálása |

### 7.5.2 Migráció stratégia — javasolt sorrend

```
I. FÁZIS: Alapok
   ├── [1] PostgreSQL adatbázis tervezés (1:1 séma migráció)
   ├── [2] Kerekítő + forintérték + kezelési díj szolgáltatás
   ├── [3] Árfolyam kezelés szolgáltatás
   └── [4] UNIT TESZTEK mindháromra (100% coverage)

II. FÁZIS: Tranzakciók
   ├── [5] Vételi tranzakció API + UI
   ├── [6] Eladási tranzakció API + UI
   ├── [7] Konverzió API + UI
   ├── [8] Sztornó API + UI
   └── [9] INTEGRÁCIÓS TESZTEK (API szint)

III. FÁZIS: AML/KYC
   ├── [10] Ügyfél-nyilvántartás
   ├── [11] 3-szintű azonosítás
   ├── [12] Tranzakció-típus meghatározás
   ├── [13] Terrorlista integráció (EU + OFAC)
   └── [14] PEP + közszereplő kezelés

IV. FÁZIS: Bizonylat + Zárás
   ├── [15] Bizonylat generátor (PDF)
   ├── [16] Napzárás
   ├── [17] Havi zárás
   ├── [18] Címletkezelés
   └── [19] Készlet + átadás-átvétel

V. FÁZIS: Integráció + Go-Live
   ├── [20] OTP POS terminál
   ├── [21] Központi szinkronizáció → REST API
   ├── [22] Párhuzamos üzem (3 hónap)
   └── [23] Go-Live + legacy leállítás
```

---



---


---

## S129 TAMAS_ELEMZĂSE


---

## S130 FUGGELEK_B_GLOBALIS_VALTOZO_KATALOGUS_KRITIKUS_ELEMEK

| Változó | Típus | Forrás | Szerepe |
|---------|-------|--------|---------|
| `_terminalid` | string | PARAMETERS.TERMINALID | Terminál 4 karakteres ID |
| `_penztarszam` | word | PENZTAR.PENZTARSZAM | Pénztár száma (EBC/Expressz döntés) |
| `_proskod` | integer | PENZTAROSOK.PENZTAROSSZAM | Bejelentkezett pénztáros |
| `_printer` | byte | HARDWARE.PRINTER | 0=LPT1, 1=USB |
| `_host` | string | HARDWARE.HOST | Remote szerver IP |
| `_bizonylatszam` | string | számított | Aktuális bizonylat szám |
| `_aktev/ho/nap` | word | dátum() | Aktuális dátum |
| `_aktdek` | integer | yearof(date)-2000 | Évtized index (ugyfel2.fdb) |
| `_ctAzonosito[]` | array | CIKKTORZS | Cikkszám cache |
| `_ctEgysegar[]` | array | CIKKTORZS | Egységár cache |
| `_ctCikknev[]` | array | CIKKTORZS | Cikknév cache |

---




<a name="15_MIGRACIO"></a>

# 15. MigrĂˇciĂłs terv Ă©s stratĂ©gia

---


---

## S131 GPT_54_ELEMZĂSE


---

## S132 15_A_RENDSZER_UZLETI_LENYEGE_OSSZEFOGLALVA

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






---

## S133 17_ROVID_VEGKOVETKEZTETES

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




---


---

## S134 ESZTER_ELEMZĂSE


---

## S135 62_GDPR_HIANYOSSAGOK

### 6.2.1 Személyes adatok kezelése — problémák

| Probléma | Részletezés | Súlyosság |
|----------|-------------|-----------|
| **Nincs adattörlési mechanizmus** | Az ügyfél adatai a szerveren „örökre" megmaradnak | 🔴 Kritikus |
| **Nincs hozzáférés-korlátozás** | Minden pénztáros minden ügyfél adatát látja | 🔴 Kritikus |
| **Hardcoded e-mail címek** | Személyes e-mailek a forráskódban | 🟡 Közepes |
| **Nincs audit log** | Ki, mikor, milyen ügyfél adatot nézett meg — nem naplózott | 🔴 Kritikus |
| **XOR „titkosítás"** | A napló nem valódi titkosítás | 🟡 Közepes |
| **FTP jelszó plaintext** | FTP hozzáférés hardcoded | 🟡 Közepes |
| **Nincs jogosultságkezelés** | Pénztáros = supervisor → mindenhez hozzáfér | 🔴 Kritikus |
| **Nincs adathordozhatóság** | Ügyfél nem kérheti saját adatainak exportját | 🟡 Közepes |
| **Nincs beleegyezés-kezelés** | Nincs nyilvántartva az ügyfél hozzájárulása | 🔴 Kritikus |

### 6.2.2 Adatmegőrzési idők

A Pmt. szerint az ügyfél-azonosítási adatokat **8 évig** kell megőrizni. A rendszerben:
- **Nincs automatikus törlés** — az adatok korlátlan ideig megmaradnak
- **Nincs archiválási/anonimizálási mechanizmus** az 8 év utáni adatokra
- A `TRADE.EXE` `Archivalo` eljárása csak a régi havi tranzakciós táblákat törli, de az ügyfél-adatokat NEM

### 6.2.3 A szerveren tárolt adatok

A központi szerveren (`193.68.57.146`) tárolt adatok:

```
ANEV..ZNEV  — természetes személyek (név + személyes adatok)
ABIZ..ZBIZ  — bizonylatok személyes hivatkozásokkal
JOGI        — jogi személyek + tulajdonosok
JOGIBIZ     — jogi személy bizonylatok
KISUGYFEL   — egyszerűsített ügyfél adatok
JOURNAL     — terrorlista-szűrési napló
```

Minden adat plaintext, titkosítás nélkül, Firebird adatbázisban.



# 7. MIGRÁCIÓS ÜZLETI SZEMPONTOK




---

## S136 72_MODERNIZALANDO_MUST_MODERNIZE

### 7.2.1 Architekturális modernizáció

| Legacy | Modern | Prioritás |
|--------|--------|-----------|
| 110+ DLL (monolitikus-moduláris) | REST API mikroszolgáltatások | 🔴 Kritikus |
| Firebird/InterBase | PostgreSQL | 🔴 Kritikus |
| VTEMP tábla IPC | Memória-alapú állapotkezelés | 🔴 Kritikus |
| Globális változók | Dependency Injection + Service réteg | 🔴 Kritikus |
| Delphi 7 Win32 | Java + React + Electron | 🔴 Kritikus |
| `ShowModal` UI | Async/reactive UI | 🟡 Közepes |
| LPT1 nyomtatás | Modern nyomtató API (PDF/ESC/POS USB) | 🟡 Közepes |
| XOR „titkosítás" | AES-256 + TLS | 🔴 Kritikus |
| Hardcoded jelszavak | Vault/Secret Manager | 🔴 Kritikus |
| SQL string concatenation | Paraméteres lekérdezések (PreparedStatement) | 🔴 Kritikus |

### 7.2.2 Adatmodell modernizáció

| Legacy | Modern |
|--------|--------|
| Betűnkénti névtáblák (ANEV..ZNEV) | Egyetlen CUSTOMER tábla + index |
| Havi dinamikus táblák (TRADyymm, BFyymm) | Particionált táblák vagy JSONB |
| VTEMP átmeneti tábla | Transaction DTO / session state |
| Bináris címletfájl (aktcim.dat) | JSON/DB tábla |
| Fix 6 tételes tömb | Dinamikus lista |

### 7.2.3 Biztonsági modernizáció

| Legacy | Modern |
|--------|--------|
| Supervisor jelszó (egy szint) | RBAC (role-based access control) |
| Nincs audit log | Strukturált audit trail |
| XOR log | Titkosított, tamper-evident napló |
| FTP szinkronizáció | REST API + TLS |
| Nincs GDPR | Adattörlés, anonimizálás, hozzáférés-naplózás |




---

## S137 73_ELHAGYHATO_CAN_DROP

### 7.3.1 Elavult funkciók

| Komponens | Indoklás |
|-----------|----------|
| Mobiltelefon feltöltés (kupon) | A prepaid feltöltés piaca összeomlott |
| VFD vevőkijelző | Modern POS-ban integrált |
| LPT1 nyomtatás | Parallel port nem létezik modern gépen |
| HRK (horvát kuna) kezelés | Horvátország eurozónában 2023 óta |
| Matrica értékesítés | Más csatornákon keresztül |
| `EUA` (euro érme) kategória | Integrálható az EUR-ba |
| FTP szinkronizáció | REST API váltja ki |
| XOR log kódolás | Valódi titkosítás kell |
| Fix `c:\valuta\` útvonalak | Konfigurálható paths |
| Delphi 7 form koordináták | Modern responsive UI |

### 7.3.2 Elavult integrációk

| Integráció | Állapot |
|------------|---------|
| CitySim SIM kártya | Valószínűleg megszűnt |
| Tesco/Metro ÁFA | Vizsgálandó, hogy aktív-e |
| Western Union | Vizsgálandó — WU saját szoftverre válthatott |




---

## S138 74_MIGRACIOS_PRIORITASOK

### 7.4.1 Fázis 1 — Kritikus üzleti logika (Sprint 1-4)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 1 | Kerekítő algoritmus + unit tesztek | Alacsony | Alacsony |
| 2 | Kezelési díj kalkulátor (3 mód) | Közepes | Közepes |
| 3 | Árfolyam-kezelés + devizanem törzs | Közepes | Közepes |
| 4 | Forintérték számítás + JPY | Alacsony | Alacsony |
| 5 | Vételi tranzakció flow | Magas | Magas |
| 6 | Eladási tranzakció flow | Magas | Magas |
| 7 | Konverzió (vétel→eladás) | Magas | Magas |

### 7.4.2 Fázis 2 — AML/KYC (Sprint 5-8)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 8 | Ügyfél-azonosítási szintek (3 tier) | Magas | Közepes |
| 9 | Természetes személy regisztráció | Közepes | Közepes |
| 10 | Jogi személy + tulajdonosok | Közepes | Magas |
| 11 | Tranzakció-típus meghatározás | Magas | Magas |
| 12 | Terrorlista szűrés | Magas | Közepes |
| 13 | Heti/negyedéves/éves kumuláció | Magas | Közepes |
| 14 | PEP kezelés | Közepes | Alacsony |

### 7.4.3 Fázis 3 — Bizonylat és zárás (Sprint 9-12)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 15 | Bizonylat generátor | Közepes | Magas |
| 16 | Napzárás | Magas | Magas |
| 17 | Havi zárás | Magas | Magas |
| 18 | Címletkezelés | Közepes | Közepes |
| 19 | Készletkezelés | Közepes | Közepes |
| 20 | Sztornó (4 típus) | Közepes | Magas |

### 7.4.4 Fázis 4 — Integráció és migráció (Sprint 13-16)

| # | Feladat | Kockázat | Komplexitás |
|---|---------|----------|-------------|
| 21 | OTP terminál integráció | Közepes | Közepes |
| 22 | Központi szerver szinkronizáció | Magas | Magas |
| 23 | Átadás-átvétel (pénztárak között) | Közepes | Közepes |
| 24 | GDPR modul (törlés/anonimizálás) | Magas | Közepes |
| 25 | Audit trail | Közepes | Közepes |



---


---

## S139 TAMAS_ELEMZĂSE


---

## S140 9_MIGRACIOS_TECHNIKAI_TERKEP

### 9.1 Architekturális Megfeleltetési Térkép

```
LEGACY (Delphi 7)                    MODERN (Java + React + Electron)
═══════════════════════════════════════════════════════════════════════

TRADE.EXE                    →    Electron shell + React SPA
├── TForm1 (főmenü)          →    App.tsx (főmenü routing)
├── InditoTimer              →    AppInitializer service (Spring Boot)
├── Vaninternet()            →    HealthCheckService.checkConnectivity()
└── CikktorzsBeolvasas()     →    ProductCatalogService (cache)

DLL Plugin Réteg             →    Spring Boot REST API controllers
├── VASARLAS.DLL             →    TransactionController.buyForeign()
├── ELADAS.DLL               →    TransactionController.sellForeign()
├── STORNO.DLL               →    TransactionController.cancel()
├── NAPZAR.DLL               →    DailyCloseController.closeDay()
├── HAVIZAR.DLL              →    MonthlyCloseController.closeMonth()
├── UGYFEL.DLL               →    CustomerController (CRUD)
├── TERROR.DLL               →    ComplianceService.checkSanctionsList()
├── BLOKNYOM.DLL             →    ReceiptService (PDF/ESC-POS)
└── WUNION.DLL               →    WesternUnionService

VTEMP tábla                  →    TransactionContext (Spring @RequestScope)
├── Ügyféladatok             →    CustomerDTO
├── Tranzakció adatok        →    TransactionDTO
└── Devizasorok              →    List<ExchangeLineDTO>

VALUTA.FDB                   →    PostgreSQL
├── PENZTAROSOK              →    users tábla (Spring Security)
├── ARFOLYAM                 →    exchange_rates tábla
├── KESZLET                  →    inventory tábla
└── CIMLET                   →    denomination tábla

TRADE.FDB                    →    PostgreSQL
├── TRADyymm (havonta)       →    transactions tábla (partitioned by month)
├── PARAMETERS               →    system_config tábla
├── CIKKTORZS                →    products tábla
├── HAVIFEJTABLA             →    transaction_headers tábla
└── HAVITETELTABLA           →    transaction_lines tábla

Kupon XML API (Coupon.exe)   →    CouponApiClient (RestTemplate/WebClient)
FTP szinkronizáció           →    FileTransferService (SFTP/S3)
LPT1 / ESC/POS nyomtatás     →    PrintService (WebUSB / Electron native print)
XOR naplózás                 →    SLF4J + Logback (strukturált napló)
```

### 9.2 Kritikus Algoritmusok Migrációja

#### 9.2.1 Forint Kerekítés

```java
// Legacy Delphi Kerekito() → Java implementáció
public int roundToFiveHuf(int amount) {
    int lastDigit = amount % 10;
    if (lastDigit <= 2) return amount - lastDigit;
    if (lastDigit <= 7) return amount - lastDigit + 5;
    return amount - lastDigit + 10;
}
```

#### 9.2.2 Bizonylatsorszám Generálás

```java
// Legacy: LASTMATRICA/LASTTELEFON integer, 8 jegyű padded string
// Modern: AtomicInteger vagy DB sequence + formázás
@Service
public class DocumentNumberService {
    @Transactional
    public String nextMatricaNumber() {
        int seq = systemConfigRepository.incrementAndGet("LASTMATRICA");
        return String.format("%08d", seq);
    }
}
```

#### 9.2.3 XOR Jelszó Dekódolás (Migrációs Segéd)

```java
// Csak a migrációhoz! Ne használd éles jelszóként!
public static String decodeXorPassword(String encoded) {
    if (!encoded.startsWith("$")) return encoded; // régi formátum
    String body = encoded.substring(1);
    StringBuilder decoded = new StringBuilder();
    for (char c : body.toCharArray()) {
        decoded.append((char)(255 - (int)c));
    }
    return decoded.toString();
}
// Migráció után KÖTELEZŐ bcrypt re-hash!
```

#### 9.2.4 Sávos Kezelési Díj

```java
// Legacy: _kdij[1..23], _tranzsav[1..23] statikus tömbök
// Modern: Adatbázis-alapú konfiguráció
@Entity
public class FeeSchedule {
    private BigDecimal fromAmount;
    private BigDecimal toAmount;
    private BigDecimal feeAmount;
    private FeeType type; // FIXED, PERCENTAGE, TIERED
}

public BigDecimal calculateFee(BigDecimal amount, Currency currency) {
    return feeScheduleRepository
        .findApplicable(amount, currency)
        .map(schedule -> schedule.calculate(amount))
        .orElse(BigDecimal.ZERO);
}
```

### 9.3 Adatmigráció Terv

#### 9.3.1 VALUTA.FDB → PostgreSQL

```sql
-- Séma migráció sorrendje:
-- 1. Törzsadatok (nincs foreign key függőség)
INSERT INTO currencies SELECT * FROM migrate_dnem();
INSERT INTO exchange_rates SELECT * FROM migrate_arfolyam();
INSERT INTO cashiers SELECT * FROM migrate_penztarosok();
INSERT INTO offices SELECT * FROM migrate_penztar();

-- 2. Ügyfelek (remote Firebird-ből is)
INSERT INTO customers SELECT * FROM migrate_ugyfel();  -- ugyfel2.fdb
INSERT INTO legal_entities SELECT * FROM migrate_jogiszemely();

-- 3. Készletek (pont az átállás pillanatában)
INSERT INTO inventory SELECT * FROM migrate_keszlet();
INSERT INTO denominations SELECT * FROM migrate_cimlet();
```

#### 9.3.2 TRADE.FDB → PostgreSQL

```sql
-- Tranzakció történeti migráció (havi táblák)
-- TRADyymm → transactions (partitioned)
-- Minden havot külön migrálni (TRAD2601, TRAD2602, ...)

-- Jelszavak migrálása (kötelező re-hash!)
UPDATE cashiers
SET password_hash = bcrypt(decode_xor(legacy_jelszo))
WHERE legacy_jelszo LIKE '$%';

UPDATE cashiers
SET password_hash = bcrypt(legacy_jelszo)
WHERE legacy_jelszo NOT LIKE '$%';
```

#### 9.3.3 Devizanem Migráció — Statikus → Dinamikus

```sql
-- A 27 hardcoded devizanem → currencies tábla
INSERT INTO currencies (code, name_hu, name_en) VALUES
  ('AUD', 'Ausztrál dollár', 'Australian Dollar'),
  ('BAM', 'Bosnyák márka', 'Bosnia Herzegovina Mark'),
  ('BGN', 'Bolgár leva', 'Bulgarian Lev'),
  ('BRL', 'Brazil real', 'Brazilian Real'),
  -- ... (teljes 27 devizanem)
  ('USD', 'Amerikai dollár', 'US Dollar');
```

### 9.4 Migrációs Kockázatok és Kezelésük

| Kockázat | Leírás | Kezelés |
|----------|--------|---------|
| Kerekítési eltérés | Ha az új algoritmus más eredményt ad | Golden master teszt 10000+ esettel |
| Bizonylatsorszám gap | Migráció alatt kihagyott sorszámok | Sequence beállítása a max legacy értékre |
| Jelszó migráció | XOR → bcrypt átmenet | Force password reset bejelentkezéskor |
| VTEMP mint IPC | A new rendszer nincs VTEMP-re utalva | TransactionContext @RequestScope váltja |
| Ékezetes ügyfélnév | Legacy CHAR típus ékezet-csonkítás | VARCHAR(UTF-8) + adatellenőrzés |
| LPT1 nyomtató | Parallel port már nem elérhető | USB ESC/POS + PDF fallback |
| Terror lista fájl | TERRORISTS.FDB → modern lista | REST API (pl. EU Financial Sanctions) |
| Havi táblastruktúra | TRADyymm → partitioned table | PostgreSQL table partitioning |

### 9.5 API Boundary Definíció

```
Modern Backend API (Spring Boot) ← → Legacy Compatible Layer
══════════════════════════════════════════════════════════════

POST /api/transactions/buy
  Body: { currency, amounts[], exchangeRate, customerId }
  → TransactionService.buy()
  → Kerekítés, kezelési díj, VTEMP-ekvivalens context
  → Return: { receiptNumber, totalAmount, receiptContent }

POST /api/transactions/sell
POST /api/transactions/cancel
GET  /api/exchange-rates
GET  /api/inventory

POST /api/daily-close
POST /api/monthly-close

GET  /api/customers/{id}
POST /api/customers

POST /api/compliance/check-sanctions
  Body: { customerName }
  → EU/UN sanctions list check (REST)

GET  /api/receipts/{number}
  → PDF vagy ESC/POS byte tömb
```

### 9.6 VTEMP → TransactionContext Leképezés

```
VTEMP mezők                    TransactionContext Java record
══════════════════════════════════════════════════════════════
UGYFELNEV              →    CustomerDTO.name
UGYFELTIPUS            →    CustomerType enum (NATURAL/LEGAL)
UGYFELSZAM             →    Long customerId
VALUTANEM (sor)        →    List<ExchangeLine>
  ARFOLYAM             →      ExchangeLine.rate
  BANKJEGY             →      ExchangeLine.amount
  FORINTERTEK          →      ExchangeLine.hufEquivalent
  ELOJEL               →      ExchangeLine.direction (BUY/SELL)
FIZETENDO              →    BigDecimal totalPayable
NETTO                  →    BigDecimal netAmount
KEZELESIDIJ            →    BigDecimal handlingFee
BIZONYLATSZAM          →    String receiptNumber
GONGYOLVE              →    boolean rolledOver
SORSZAM                →    Long sequenceNumber
PLOMBASZAM             →    String sealNumber
ENGEDELYEZO            →    String authorizedBy
```

### 9.7 Nyomtatási Alrendszer Migrációja

```
Legacy                         Modern
═══════════════════════════════════════════════════════
AssignFile('LPT1')      →    USB ESC/POS (node-escpos / escpos-buffer)
AssignPrn()             →    Windows Print Spooler (Electron native)
c:\valuta\aktlst.txt    →    In-memory string buffer
ESC/POS parancsok       →    EscPos.builder()
  #27#64 (init)         →      .initialize()
  #27#71 (bold on)      →      .bold(true)
  #14 (wide on)         →      .doubleWidth(true)
  #27#97#5 (cut)        →      .cut()

Bizonylat formátum:
39 karakter széles      →    PDF (A4/A6) + ESC/POS roll
Magyar ékezetek         →    UTF-8 (Epson TM-T20 unicode módban)
Kétpéldányos nyomtatás →    PDF 2 print + ESC/POS 2x feed
```

### 9.8 Migrációs Ütemterv — Technikai Ajánlás

```
1. FÁZIS (0-2 hónap): Adatmigráció és API alapok
   ├── PostgreSQL séma létrehozás (legacy-kompatibilis)
   ├── Firebird → PostgreSQL ETL szkriptek
   ├── Alapszintű CRUD API (Spring Boot)
   └── Golden master tesztek rögzítése

2. FÁZIS (2-4 hónap): Core üzleti logika
   ├── Tranzakció motorok (vétel, eladás, sztornó)
   ├── Kezelési díj és kerekítés service
   ├── Bizonylat számozás
   └── Unit + integration tesztek

3. FÁZIS (4-6 hónap): Pénztár folyamatok
   ├── Napzárás / havi zárás
   ├── Ügyfélkezelés + AML/Terror szűrés
   ├── Foglalás rendszer
   └── E2E tesztek

4. FÁZIS (6-8 hónap): Integrációk
   ├── Kupon API (Coupon.exe → REST client)
   ├── Western Union integráció
   ├── OTP terminál integráció
   ├── Nyomtatási alrendszer (ESC/POS + PDF)
   └── FTP → SFTP/API szinkronizáció

5. FÁZIS (8-10 hónap): Cutover
   ├── Párhuzamos üzemeltetés (legacy + modern)
   ├── Adat-konzisztencia ellenőrzés
   ├── Felhasználói oktatás
   └── Éles átállás
```

---



---


---

## S141 GABOR_ELEMZĂSE

# Anti Valutaváltó — UI/UX Design Elemzés és Modern Migrációs Terv

> **Szerző:** Gábor (Design & Graphics Chief)
> **Dátum:** 2026-04-02
> **Forrás:** `antivaluta-junior.md` (rendszer áttekintés) + `anti-dfm-pack.md` (DFM form layout-ok)
> **Kontextus:** Delphi 7 legacy rendszer → Java + React + Electron modern ERP migráció
> **Scope:** UI/UX elemzés, design antipattern feltárás, modern UX javaslatok, ASCII wireframe-ek

---




---

## S142 8_MODERN_DESIGN_RENDSZER_JAVASLAT

### 8.1 Design elvek

A modern valutaváltó rendszer design elvei:

**1. Speed-first UX**
A pénztáros munkája repetitív, időkritikus. Minden extra kattintás, minden extra várakozás gazdasági veszteség. A design minden döntésénél az a kérdés: *"Hogyan csökkentjük az egy tranzakcióhoz szükséges interakciók számát?"*

**2. Error-resistant design**
A hibás tranzakció visszavonása bonyolult (sztornó DLL, supervisor jelszó, indoklás). Ezért a bevitel előtt kell megelőzni a hibákat: összeg-érvényesítés, árfolyam-konfirmáció, ügyfél-azonosítási figyelmeztetés.

**3. Regulatory compliance by design**
Az AML/KYC, PEP ellenőrzés, NAV bizonylatolás NEM opcionális funkció — ezek a jogszabályból következő kötelezettségek. A designnak ezeket elsőrendű elemként kell kezelni, nem "popup"-ként.

**4. Keyboard-first, touch-optional**
A pénztáros billentyűzettel dolgozik. Az egér másodlagos. De a modern rendszer touch-képernyős táblagépen is futhat (remote pénztár). Ezért: keyboard-first, touch-compatible.

**5. Consistent visual language**
Minden képernyő azonos design language-t használ. A különböző műveletek (vétel vs. eladás) vizuálisan megkülönböztethetők, de nem zavarba ejtően más rendszert alkotnak.

### 8.2 Szín-token rendszer

```
-- Primer (branding)
--color-primary:          #1E3A5F    /* sötétkék — EBC brand */
--color-primary-light:    #2563EB    /* medium kék — interactive */
--color-primary-dark:     #0F1E35    /* nagyon sötét — header */

-- Szemantikus (funkcionális)
--color-buy:              #047857    /* sötétzöld — VÁSÁRLÁS */
--color-sell:             #B91C1C    /* sötétvörös — ELADÁS */
--color-storno:           #92400E    /* sötétbarna — SZTORNÓ */
--color-warning:          #D97706    /* narancs — figyelmeztetés */
--color-success:          #059669    /* zöld — siker */
--color-error:            #DC2626    /* piros — hiba */

-- Háttér
--color-bg-primary:       #F8FAFC    /* szinte fehér — fő tartalom */
--color-bg-secondary:     #EFF6FF    /* halvány kék — panel */
--color-bg-dark:          #0F1E35    /* sötétkék — navigáció */

-- Szöveg
--color-text-primary:     #0F172A    /* majdnem fekete */
--color-text-secondary:   #475569    /* középszürke */
--color-text-inverse:     #F8FAFC    /* fehér — sötét háttéren */
--color-text-muted:       #94A3B8    /* halvány — placeholder */

-- Keret
--color-border:           #E2E8F0    /* halvány szürke */
--color-border-focus:     #2563EB    /* kék — fókuszálva */
```

### 8.3 Tipográfia-rendszer

```
-- Font family
--font-primary:   'Inter', system-ui, -apple-system, sans-serif;
--font-mono:      'JetBrains Mono', 'Courier New', monospace;

-- Méretek
--text-xs:      0.75rem   (12px)   -- apró jelölések
--text-sm:      0.875rem  (14px)   -- secundary szöveg
--text-base:    1rem      (16px)   -- alap szöveg
--text-lg:      1.125rem  (18px)   -- kiemelés
--text-xl:      1.25rem   (20px)   -- al-fejléc
--text-2xl:     1.5rem    (24px)   -- fejléc
--text-3xl:     1.875rem  (30px)   -- szekció fejléc
--text-4xl:     2.25rem   (36px)   -- oldal cím
--text-display: 3rem      (48px)   -- tranzakció összeg (prominens)

-- Súlyok
--font-normal:   400;
--font-medium:   500;
--font-semibold: 600;
--font-bold:     700;
```

### 8.4 Spacing rendszer (8pt grid)

```
--space-1:   0.25rem   (4px)
--space-2:   0.5rem    (8px)
--space-3:   0.75rem   (12px)
--space-4:   1rem      (16px)
--space-5:   1.25rem   (20px)
--space-6:   1.5rem    (24px)
--space-8:   2rem      (32px)
--space-10:  2.5rem    (40px)
--space-12:  3rem      (48px)
--space-16:  4rem      (64px)
--space-20:  5rem      (80px)
--space-24:  6rem      (96px)
```

---




---

## S143 10_KEPERNYO_ARCHITEKTURA_A_MODERN_RENDSZERHEZ

### 10.1 Főképernyő layout (shell)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│ │  [EBC logó]   Exclusive Best Change Zrt.   [Pénztár: PÉCS-01]   [KOVÁCS ANNA] ▼ │ │
│ │  (--color-bg-dark, fehér szöveg, 56px magas topbar)                              │ │
│ └──────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│ ┌────────────────┐  ┌──────────────────────────────────────────────────────────────┐ │
│ │ NAV SÁV        │  │  FŐ TARTALOM                                                 │ │
│ │ (240px, dark)  │  │                                                              │ │
│ │                │  │  [Devizaváltás / Napi forgalom / Bizonylatok / Zárás stb.]   │ │
│ │ ○ Devizaváltás │  │                                                              │ │
│ │   ├ Vásárlás   │  │                                                              │ │
│ │   ├ Eladás     │  │                                                              │ │
│ │   └ Sztornó    │  │                                                              │ │
│ │ ○ Foglalás     │  │                                                              │ │
│ │ ○ Ügyfelek     │  │                                                              │ │
│ │ ○ Bizonylatok  │  │                                                              │ │
│ │ ○ Listák       │  │                                                              │ │
│ │ ○ Pénztár      │  │                                                              │ │
│ │   ├ Nyitás     │  │                                                              │ │
│ │   ├ Napzárás   │  │                                                              │ │
│ │   └ Havi zárás │  │                                                              │ │
│ │ ─────────────  │  │                                                              │ │
│ │ ≡ Supervisor   │  │                                                              │ │
│ │ ─────────────  │  │                                                              │ │
│ │ → Kilépés      │  │                                                              │ │
│ └────────────────┘  └──────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│ ┌──────────────────────────────────────────────────────────────────────────────────┐ │
│ │  [F2] Vásárlás   [F3] Eladás   [F4] Sztornó   [F5] Listák       [Esc] Mégse    │ │
│ │  (Status bar — állandó billentyűzet-segítség, 32px magas)                       │ │
│ └──────────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Devizavásárlás képernyő (modern, to-be)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  DEVIZAVÁSÁRLÁS                          [2026.04.02. 09:15]   [KOVÁCS ANNA]        │
│  (--color-buy zöld fejlécsáv, fehér szöveg)                                          │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐  │
│  │  DEVIZANEM  ───────────────────────────────────────────────                   │  │
│  │                                                                                │  │
│  │  [ EUR ▼ ]   Aktuális vételi árfolyam: 395.50 Ft/EUR   [Módosítás ▶]         │  │
│  │                                                                                │  │
│  │  ÖSSZEGEK  ────────────────────────────────────────────                       │  │
│  │                                                                                │  │
│  │  ┌──────────────────┬────────────────┬──────────────┬──────────────────────┐  │  │
│  │  │ Bankjegy értéke  │ Darabszám      │ Deviza összeg│ Forint érték         │  │  │
│  │  ├──────────────────┼────────────────┼──────────────┼──────────────────────┤  │  │
│  │  │ 100 EUR          │  [   3  ]      │  300 EUR     │  118 650 Ft          │  │  │
│  │  │ 50 EUR           │  [   1  ]      │   50 EUR     │   19 775 Ft          │  │  │
│  │  │ [+ Sor hozzáad]  │                │              │                      │  │  │
│  │  └──────────────────┴────────────────┴──────────────┴──────────────────────┘  │  │
│  │                                                                                │  │
│  │  Összesen: 350 EUR                                                             │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
│  ┌───────────────────────────────────────────┐ ┌───────────────────────────────┐   │
│  │  ELSZÁMOLÁS                               │ │  FIZETENDŐ                    │   │
│  │                                           │ │                               │   │
│  │  Bruttó deviza:      350.00 EUR           │ │     138 425 Ft                │   │
│  │  Kezelési díj:         1 000 Ft           │ │     (48pt, bold, --color-buy) │   │
│  │  Nettó forint:       137 425 Ft           │ │                               │   │
│  │  Kerekítés:               +0 Ft           │ │  [ End — RÖGZÍT ✓ ]           │   │
│  │  Fizetendő:          138 425 Ft           │ │  [ Esc — MÉGSE  ✗ ]           │   │
│  └───────────────────────────────────────────┘ └───────────────────────────────┘   │
│                                                                                      │
│  ⚠  Az összeg nem haladja meg a 300 000 Ft-os azonosítási limitet.                  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 10.3 Ügyfél-azonosítás modern flow (inline wizard)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  ÜGYFÉL AZONOSÍTÁS   ●──────●──────○──────○                                         │
│                      1.Alap  2.Okm. 3.Ellenőr. 4.Kész                              │
│                                                                                      │
│  1. ALAPADATOK  ───────────────────────────────────────────────────────────────────  │
│                                                                                      │
│  Személy típusa:   ( ●) Természetes személy    ( ) Jogi személy                     │
│                                                                                      │
│  Teljes név:  [_________________________________]                                   │
│  Anyja neve:  [_________________________________]                                   │
│                                                                                      │
│  Születési hely: [______________]    Dátum: [ 1965 ▼ ] [ 03 ▼ ] [ 12 ▼ ]          │
│  Állampolgárság: [ Magyar ▼ ]                                                        │
│  Lakcím:  [_____________________________________]                                   │
│           [_____________] [__________________________]  (irányítószám, város)       │
│                                                                                      │
│  Lakóhely típusa:  ( ●) Belföldi    ( ) Külföldi                                   │
│                                                                                      │
│  ─────────────────────────────────────────────────────────────────────────────────  │
│  [ ← Vissza ]                                              [ Tovább: Okmányok → ]   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 10.4 Sztornó képernyő (modern)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  SZTORNÓ                                        [2026.04.02.]   [SUPERVISOR MÓD]   │
│  (--color-storno sötétbarna fejléccsík)                                              │
│                                                                                      │
│  Sztornó típusa:                                                                     │
│  [ ● Devizavétel ]  [ Devizaeladás ]  [ Ügyfél rekord ]  [ Forráskód ]              │
│                                                                                      │
│  ┌─────────────────────────────────────────────────────────────────────────────┐    │
│  │  BIZONYLAT   │ DÁTUM       │ DEVIZANEM │  ÖSSZEG     │ PÉNZTÁROS  │ÜGYFÉL   │    │
│  │  ────────────┼─────────────┼───────────┼─────────────┼────────────┼─────── │    │
│  │  00123458    │ 2026.04.02. │ EUR       │  138 425 Ft │ KOVÁCS A.  │KISS B.  │    │
│  │  00123459    │ 2026.04.02. │ USD       │   45 200 Ft │ KOVÁCS A.  │ —       │    │
│  │  00123460    │ 2026.04.02. │ GBP       │  201 300 Ft │ KOVÁCS A.  │NAGY M.  │    │
│  └─────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                      │
│  Keresés bizonylat szerint: [________________________]                              │
│                                                                                      │
│  Kiválasztott bizonylat: 00123458 — EUR vétel — 138 425 Ft — KISS BÉLA              │
│                                                                                      │
│  Indoklás (kötelező): [_______________________________________________________]     │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │  ⚠  FIGYELEM: Ez a művelet visszafordíthatatlan. Biztosan sztornózza?        │   │
│  │                                                                              │   │
│  │         [ SZTORNÓZOM ]                      [ MÉGSEM ]                      │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---




---

## S144 12_PRIORITAS_MATRIX_ES_IMPLEMENTACIOS_UTEMTERV

### 12.1 UX problémák prioritás-mátrix

| # | Probléma | Üzleti hatás | Fejlesztési effort | Prioritás |
|---|----------|-------------|-------------------|-----------|
| 1 | Modal-heavy UX → blokkoló folyamatok | MAGAS | MAGAS | P1 |
| 2 | Devizaváltás rejtett a főmenün | MAGAS | ALACSONY | P1 |
| 3 | 18 mező egyszerre → kognitív terhelés | MAGAS | KÖZEPES | P1 |
| 4 | Nincs haladásjelző napzárnál | KÖZEPES | ALACSONY | P1 |
| 5 | Inkonzisztens szín- és font rendszer | KÖZEPES | KÖZEPES | P2 |
| 6 | Abszolút koordináták → nem skálázható | MAGAS | MAGAS | P2 |
| 7 | Nincs keyboard shortcut rendszer | KÖZEPES | ALACSONY | P2 |
| 8 | Ügyfél-azonosítás nem wizard-alapú | KÖZEPES | KÖZEPES | P2 |
| 9 | Nem érthető mezőcímkék (WA1-WA6) | ALACSONY | ALACSONY | P3 |
| 10 | Beágyazott JPEG háttérképek | ALACSONY | ALACSONY | P3 |
| 11 | Nyomtatás: LPT1 közvetlen | MAGAS | MAGAS | P1 |
| 12 | Offline működés hiánya | MAGAS | MAGAS | P1 |

### 12.2 Phased implementáció javaslat

**Fázis 1 — Alap UX (Sprint 1-4):**
- Design token rendszer (színek, tipográfia, spacing)
- Főmenü redesign: devizaváltás prominens helyen
- VASARLAS/ELADAS: dinamikus sor-hozzáadás, árfolyam kiemelés
- Status bar keyboard shortcutok

**Fázis 2 — Flow redesign (Sprint 5-8):**
- Ügyfél-azonosítás wizard komponens
- Napzárás haladásjelző
- Sztornó: grid bővítés (dátum, devizanem, ügyfél oszlopok)
- Bizonylat megjelenítő: keresés mező

**Fázis 3 — Modern UX (Sprint 9-12):**
- Offline-first architektúra
- Supervisor auth PIN/biometria
- Árfolyam inline szerkesztés
- ESC/POS hibrid nyomtatás

**Fázis 4 — Polish és accessibility (Sprint 13-16):**
- WCAG 2.1 AA megfelelőség
- Screen reader support
- Keyboard-only navigáció audit
- Dark mode (opcionális)

---




---

## S145 22_OSSZEFOGLALAS_ES_ZARO_GONDOLATOK

### 22.1 A legacy rendszer értékelése egyetlen mondatban

Az Anti Valutaváltó Delphi 7 rendszer **funkcionálisan korrekt, jogilag megfelelő, de ergonómiailag és vizuálisan elavult** — és migrációja nem egyszerű "újrafestés", hanem mélyreható UX-átgondolás.

### 22.2 A három legfontosabb UX befektetés

1. **Egységes design language bevezetése** — ez az összes többi UX-problémát részben megoldja, és minimális üzleti kockázattal jár
2. **Devizaváltás prominens helyre emelése a főmenüben** — ez azonnali, mérhető pénztárosi hatékonysági javulást hoz
3. **Napzárás haladásjelző** — a pénztáros stresszpontja jelenleg a "mi történik most?" bizonytalanság; egy progress indicator ezt feloldja

### 22.3 A migráció nem-céljai

- **Nem cél** a bizonylat-formátumok megváltoztatása (jogszabályi kötöttség)
- **Nem cél** az összes DFM-ben lévő vizuális "karakter" eltüntetése (néhány öröklött vizuális elem ismerős a régi felhasználóknak)
- **Nem cél** a touch-first redesign (a pénztáros billentyűzettel dolgozik — de legyen touch-compat)
- **Nem cél** a supervisor workflow gyökeres átírása (a jelszavas védelem üzleti igény, csak a UX-a modernizálható)

### 22.4 Zárszó

A Delphi 7 rendszer 15-20 éves örökség — és ez a kor nemcsak a kódban, hanem a UX döntésekben is látszik. A `Elephant` font a sztornó fejlécen, a New York-i látóképes foglalás-háttér, a VIRAG nevű off-screen TImage, a 96 pontos "ELADÁS" cím — ezek mind egy korszak lenyomatai.

Az új React+Electron rendszer megörökli a munkavégzési kultúrát (billentyűzetes, gyors, professzionális), de felváltja a vizuális döntéseket egy egységes, hozzáférhető, skálázható design language-dzsel.

A cél: az Exclusive Best Change pénztárosa **azonnal otthon érezze magát** az új rendszerben — mert az ismerős billentyűzetes workflow megmaradt —, miközben **objektíve gyorsabb és megbízhatóbb** legyen a napi munkája.

---

> **Gábor, Design & Graphics Chief** — 2026-04-02
>
> Ez az elemzés a `antivaluta-junior.md` rendszer-áttekintés és az `anti-dfm-pack.md` DFM layout-csomag alapján készült. Minden DFM-hivatkozás az eredeti Delphi 7 forráskódból származó tényleges adatot tükröz. Az ASCII wireframe-ek a koordináta-adatokból rekonstruált becsült layout-ok, nem pixel-pontos reprodukciók.

[TASK_COMPLETE]




<a name="16_JOGSZABALY"></a>

# 16. JogszabĂˇlyi megfelelĹ‘sĂ©g

---


---

## S146 ESZTER_ELEMZĂSE

# 6. JOGSZABÁLYI MEGFELELŐSÉG




---

## S147 63_SZANKCIOS_MEGFELELOSEG

### 6.3.1 USD korlátozás

A rendszer implementálja az USA szankciók szerinti USD korlátozást:
- Irán (IR), Észak-Korea (KR), Kuba (CU), Szíria (SY), Dél-Szudán (SS) — USD eladás TILTOTT
- Az ISO országkód alapján ellenőrzi

### 6.3.2 Hiányzó szankciós elemek

| Hiányosság | Leírás |
|------------|--------|
| EU szankciós lista | Nincs integrálva az EU szankciós rendszere |
| OFAC SDN lista | Nincs automatikus frissítés |
| Terrorlista frissítés | A terrorlista karbantartása manuális |
| Szankciós ország bővítés | Csak 5 ország van hardcoded-olva |

---




<a name="99_FUGGELEKEK"></a>

# 17. FĂĽggelĂ©kek Ă©s kiegĂ©szĂ­tĹ‘ elemzĂ©sek

---


---

## S148 GPT_54_ELEMZĂSE

# Anti rendszer teljes körű feltérképezése






---

## S149 CEL_ES_HATOKOR

Ez a dokumentum a `D:\repo\valutavalto-program\Anti` könyvtár teljes forrásalapú feltérképezése alapján készült. A célja, hogy technikai és üzleti szinten is leírja:



- a rendszer szerkezetét

- a fő futtatható alkalmazásokat és alrendszereket

- a menüket és üzleti folyamatokat

- a pénztári, értéktári, szerveres, mentési és bizonylatkezelési logikát

- a Delphi/Pascal DLL-modulok szerepét

- a Java alapú kamera- és központi rendszerek kapcsolatát






---

## S150 FONTOS_MEGJEGYZES

A workspace-ben tényleges `.dll` és `.exe` binárisok nem találhatók, ezért a leírás a hozzájuk tartozó Delphi projektfájlokból, Pascal forrásokból, DFM formokból, Java forrásokból, konfigurációkból és egyéb artefaktokból készült. A DLL-ek működése a forrásuk és a főalkalmazásból történő hívásaik alapján rekonstruált.






---

## S151 3_IBVALTO_MUKODESI_MODELLJE



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






---

## S152 10_RIPORTOK_ES_LISTAK



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






---

## S153 12_TRADE_RENDSZER_RESZLETES_KEPE



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






---

## S154 131_CAMERA2CAMERA

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






---

## S155 136_CAMERA3OLD

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






---

## S156 16_KRITIKUS_TECHNIKAI_MEGFIGYELESEK



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





---


---

## S157 JUNIOR_ELEMZĂSE

# Anti Valutaváltó — Teljes Reverse Engineering Elemzés



---

## S158 JUNIOR_SZOFTVERFEJLESZTO_AGENS_ELEMZESE

> **Dátum:** 2026-04-02
> **Forrás:** `D:\repo\valutavalto-program\Anti\VALUTA\`
> **Technológia:** Delphi 7, Firebird/InterBase, Win32 DLL plugin architektúra
> **Méret:** 6972 fájl, ~1.7 GB, 420 .pas, 419 .dfm, 279 .dpr, 131 .dll

---




---

## S159 12_OSSZEFOGLALO

### 12.1 Rendszer méret

- **110+ DLL modul** — mindegyik önálló Delphi projekt
- **420 Pascal forrásfájl** + **419 form fájl**
- **2 Firebird adatbázis** + 1 MySQL (WU)
- **1 fő EXE** (TRADE.EXE) az e-kereskedelem/kupon modulokkal

### 12.2 Fő üzleti funkciók

1. **Devizaváltás** (vétel + eladás + árfolyam módosítás)
2. **Mobiltelefon feltöltés** (T-Mobile, Telenor, Vodafone, T-Com, Tesco)
3. **Autópálya e-matrica** (vásárlás + ÁFÁs számla + kétpéldányos bizonylat)
4. **Western Union** pénzátutalás
5. **OTP terminál** integráció
6. **Foglalás** rendszer
7. **Sztornó** (4 típus)
8. **Napi/havi/éves zárás** (napnyitás, napzár, havi zár, dekád zár)
9. **Címletkezelés** (bevétel, kiadás, készlet, egyenleg)
10. **Ügyfél-azonosítás** (természetes + jogi, TMK/AML, terror szűrés, PEP)
11. **Bizonylat rendszer** (12+ típus, kötelező jogi mezők)
12. **FTP szinkronizáció** és napi mentés
13. **Hatósági jelentések** (NAV, napi könyv, forgalomösszesítő)

### 12.3 Migráció szempontjai az új rendszerhez

A modern (Java+React+Electron) rendszernek az alábbi legacy funkciókat kell lefednie:
- Minden devizaváltási típus a teljes árfolyam/kezelési díj/kerekítés logikával
- A bizonylat-nyomtatási formátumok pontos reprodukálása
- A 300k feletti ügyfél-azonosítási kötelezettség
- A napi/havi zárási folyamat minden lépése
- A címletkezelés teljes logikája
- A Western Union integráció
- Az OTP POS terminál integráció
- A terrorizmus/PEP szűrés
- A foglalási rendszer
- A sztornó 4 típusa az összes ellentranzakció logikával

> **Megjegyzés:** A telefonfeltöltés (kupon) modul valószínűleg már nem releváns az új rendszerben, de az üzleti logika dokumentálása a teljesség kedvéért megtörtént.



---


---

## S160 ESZTER_ELEMZĂSE


---

## S161 ESZTER_CONTROLLER_CHIEF_ELEMZESE

> **Dátum:** 2026-04-02
> **Elemző:** Eszter — QA & Code Review Controller Chief
> **Forrás:** `D:\repo\valutavalto-program\Anti\VALUTA\` + Junior átfogó reverse engineering elemzés
> **Módszer:** Forráskód-alapú üzleti logika feltárás, kockázatelemzés, jogszabályi audit
> **Cél:** A Delphi 7 legacy rendszer üzleti szabályainak, kódminőségének és migrációs kockázatainak mély elemzése

---




---

## S162 TARTALOMJEGYZEK

1. [Pénzügyi üzleti szabályok](#1-pénzügyi-üzleti-szabályok)
2. [AML/KYC szabályok](#2-amlkyc-szabályok)
3. [Bizonylat-rendszer](#3-bizonylat-rendszer)
4. [Napi/havi zárási üzleti folyamatok](#4-napihavi-zárási-üzleti-folyamatok)
5. [Kódminőség és kockázatok](#5-kódminőség-és-kockázatok)
6. [Jogszabályi megfelelőség](#6-jogszabályi-megfelelőség)
7. [Migrációs üzleti szempontok](#7-migrációs-üzleti-szempontok)

---




---

## S163 61_IMPLEMENTALT_SZABALYOK

### 6.1.1 Pmt. (pénzmosás elleni törvény) — 2017. évi LIII. tv.

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| 300k Ft feletti ügyfél-azonosítás | `securlevel=1` ha `fizetendo>=300000` | ✅ Implementált |
| Kiemelt közszereplő (PEP) kezelés | `_kozszereplo` mező + `KozszerepNyilatkozat` | ✅ Implementált |
| Tényleges tulajdonos azonosítás | `_tulajnevedit[1..4]` + bizonylat nyomtatás | ✅ Implementált |
| Terrorlista szűrés | `TERROR` DLL + `terrorcontrol` | ✅ Implementált |
| Forrás igazolás | `_forras` mező + bizonylat | ✅ Implementált |
| Gyanús tranzakció jelentés | `GetTranztip` + JOURNAL tábla + e-mail | ⚠️ Részben — manuális |
| 4.5M EUR éves limit | `_evimax` mező | ✅ Implementált (8M Ft küszöbbel) |
| Ügyfél-nyilvántartás 8 évig | Szerveren tárolt NEVTABLA | ⚠️ Részben — nincs automatikus törlés |

### 6.1.2 ÁFA törvény — 2007. évi CXVII. tv.

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| Pénzváltás ÁFA-mentessége | Bizonylaton: "86. § e) alapján mentes" | ✅ Korrekt |
| SZJ kód feltüntetés | "Szj - 67.13.10.0" | ✅ Korrekt |
| ÁFÁs számla matrica/telefon | `AfasSzamla`, `TelAfasSzamla` | ✅ Implementált |
| 27% ÁFA tartalom | "21,26% ÁFA-t tartalmaz" (bruttóból) | ✅ Számítás korrekt |

### 6.1.3 Devizatörvény / MNB előírások

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| Vételi/eladási árfolyam megkülönböztetés | `VETELIARFOLYAM` / eladási árf. | ✅ |
| Árfolyam közzététele | `ARFDISP` DLL | ✅ |
| 5 Ft-os kerekítés | `Kerekito` függvény | ✅ |
| Bizonylat kétnyelvű (HU+EN) | Mezők: "Sorszam (INVOICE NR)" stb. | ✅ |
| Napi forgalmi jelentés | `NAPIFORG`, `NAPIJEL` DLL-ek | ✅ |
| Dekádjelentés | `DEKRUTIN` DLL | ✅ |
| Havi zárás | `HAVIZAR` DLL | ✅ |

### 6.1.4 NAV előírások

| Szabály | Implementáció | Megfelelőség |
|---------|---------------|--------------|
| Pénztárgép napi zárás | `QR kód` + `navzarocontrol` | ✅ |
| Nyugtaszámozás | `RECNUMS`/`ZCOUNTS` mezők | ✅ |
| Bizonylat archiválás | Szerveren BF/BT táblákban | ✅ |



# FÜGGELÉK




---

## S164 A_SZTORNO_FOLYAMAT_RESZLETES_ELEMZESE_STORNO_DLL

### A.1 Sztornó típusok

A `STORNO` DLL négy bizonylattípust tud sztornózni:

```pascal
// STORNO/Unit2.pas — rádiógombok:
VR: TRadioButton;   // V = Vételi bizonylat sztornó
ER: TRadioButton;   // E = Eladási bizonylat sztornó
UR: TRadioButton;   // U = Átvételi bizonylat sztornó
FR: TRadioButton;   // F = Átadási bizonylat sztornó
```

### A.2 Sztornó bizonylat jelölések a BLOKKFEJ.STORNO mezőben

| STORNO érték | Jelentés |
|-------------|----------|
| 1 | Érvényes, aktív bizonylat |
| 2 | Sztornózott (az eredeti bizonylat) |
| 3 | Sztornó bizonylat (az érvénytelenítő) |

### A.3 Sztornó korlátozás — napi limit

```pascal
// STORNO/Unit2.pas — FormActivate
_napiStorno := FieldByName('NAPISTORNO').asInteger;
// ...
if _napistorno>2 then begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then begin
    Kilepo.Enabled := true;
    exit;
  end;
end;
```

**Üzleti szabály:** Naponta maximum 2 sztornó engedélyezett supervisor jelszó nélkül. A 3. sztornótól supervisor engedély szükséges.

### A.4 Sztornó indokolás

Minden sztornóhoz **kötelező indoklás**:

```pascal
// STORNO/Unit2.pas — IndokEditKeyDown
_stornoIndok := trim(indokedit.Text);
if _stornoindok='' then exit;  // Üres indok → nem engedélyezi
StartGomb.Enabled := true;     // Csak indokkal engedélyezi
```

### A.5 Érvénytelenítés teljes folyamata

Az `Ervenytelenites` eljárás az alábbi lépéseket hajtja végre:

```pascal
// STORNO/Unit2.pas — Ervenytelenites
// 1. Átadás/átvétel sztornónál: NAV QR kód + valuta sztornó
if (_tipus='F') or (_tipus='U') then begin
  EllenTranzakcio;   // NAV pénztárgépben ellentétes tranzakció
  ValutaStorno;      // Készlet visszarendezés
  Exit;
end;

// 2. OTP terminál sztornó (ha bankkártyás fizetés volt):
if _fizetoEszkoz=2 then begin
  if OtpKontrol then 
    _otpOke := OTPTermStorno        // Utolsó bizonylat → sima sztornó
  else 
    _otpOke := OtpAruvisszavet;     // Nem utolsó → áru-visszavét
  if _otpoke<>1 then begin
    ShowMessage('SIKERTELEN OTP-STORNÓ !');
    exit;
  end;
end;

// 3. Kisügyfél sztornó (szerveren összeg csökkentés):
if _ugyftipus='K' then KisUgyfelstorno;

// 4. Nagyügyfél visszagöngyölítés (szerveren bizonylat visszavonás):
if (_ugyftipus<>'K') and (_nevtabla<>'') then GongyoletVissza;

// 5. Normál valuta-sztornó:
Valutastorno;
```

### A.6 ValutaStorno — készlet-visszarendezés

```pascal
// STORNO/Unit2.pas — ValutaStorno (~sor 860)

// Eredeti bizonylat STORNO=2-re állítása:
_pcs := 'UPDATE BLOKKFEJ SET STORNO=2 WHERE BIZONYLATSZAM=...';
_pcs := 'UPDATE BLOKKTETEL SET STORNO=2 WHERE BIZONYLATSZAM=...';

// Új sztornó bizonylat létrehozása (STORNO=3):
_stornoBizonylat := _tipus + _bizelokod + nulele(_blokk, _nLen);
_oft             := trunc(_oft * (-1));       // Előjel megfordítás
_fizetendo       := trunc(_fizetendo * (-1)); // Negatív összeg
_kezdij          := trunc(_kezdij * (-1));    // Negatív díj

// BLOKKFEJ INSERT a sztornó bizonylattal:
'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,...,STORNO,...) VALUES (...,3,...)'

// Tételek negatív előjellel:
_bankjegy    := trunc(_bankjegy * (-1));
_forintertek := trunc(_forintertek * (-1));
'INSERT INTO BLOKKTETEL (...,STORNO,...) VALUES (...,3,...)'

// VTEMP frissítés a blokknyomtatáshoz:
'UPDATE VTEMP SET STORNOBIZONYLAT=...,STORNO=3,...,STORNOINDOK=...'

// Napi sztornó számláló növelése:
inc(_napistorno);
'UPDATE HARDWARE SET NAPISTORNO=' + inttostr(_napistorno)

// Sztornó blokk nyomtatása:
blokknyomtatas(1);
```

### A.7 OTP sztornó vs. áru-visszavét

```pascal
// OTP terminál sztornó — UTOLSÓ bizonylat esetén:
// OTPFUNCTYPE = 100 → terminál sztornó
_pcs := 'INSERT INTO VTEMP (BIZONYLATSZAM,FIZETENDO,OTPFUNCTYPE) VALUES (...,100)';
result := otpterminal;

// OTP áru-visszavét — NEM utolsó bizonylat:
// OTPFUNCTYPE = 4 → áru visszavétel
// + supervisor jelszó szükséges!
_spk := supervisorjelszo(0);
if _spk<>1 then exit;
_pcs := 'INSERT INTO VTEMP (...,OTPFUNCTYPE) VALUES (...,4)';
result := otpterminal;
```

### A.8 Kisügyfél sztornó — szerveren

```pascal
// STORNO/Unit2.pas — KisUgyfelStorno
// A kisügyfél szerveren lévő kumulált összegéből levonja:
remotedbase.DatabaseName := _host+':c:\receptor\database\kisugyfel.fdb';
_edosszeg := FieldByName('OSSZEG').asInteger;
_ujosszeg := _edosszeg - _fizetendo;
if _ujosszeg < 0 then _ujOsszeg := 0;
'UPDATE ' + _nevtabla + ' SET OSSZEG=' + inttostr(_ujOsszeg)
```

### A.9 Göngyölítés visszavonása — szerveren

A `GongyoletVissza` a szerveren regisztrált nagyügyfél tranzakciót vonja vissza:

```pascal
// A plombaszám tartalmazza a névtáblát és sorszámot:
_nevtabla := leftstr(_plombaszam, 4);  // pl. 'ANEV'
_sorszam  := midstr(_plombaszam, 5, ...);
// VTEMP-be írja az adatokat, majd:
gongyvisszavonas;  // Extern DLL hívás
```




---

## S165 B_NAPLOZAS_ES_AUDIT_LOGIRO_DLL

### B.1 Naplózási minta

Minden DLL a `logirorutin` eljárást használja naplózásra:

```pascal
// Hívási minták:
logirorutin(pchar('Devizavásárlás indul'));
logirorutin(pchar('Fizetendő: ' + inttostr(_fizetendo)));
logirorutin(pchar('Egyedi kezdij lehetőség ' + inttostr(3-_negykezdij) + ' maradt'));
logirorutin(pchar('A terrorlistán szereplés miatt a tranzakció letiltva !'));
logirorutin(pchar('A terrorlista ellenére engedélyezték a tranzakciót'));
```

A napló XOR-kódolva (255-c) mentésre kerül a `c:\valuta\temp\` könyvtárba. A naplófájl neve: `AKTLST.TXT`.

### B.2 Napló integritási probléma

A `SetLogFile` függvény a nap elején inicializálja a naplót, de:
- **Nincs idő-pecsét** az egyes bejegyzéseknél (csak szöveg)
- **Nincs hash/HMAC** — a napló manipulálható
- **Nincs rotáció** — a fájl korlátlanul nőhet
- **A XOR kódolás visszafejthető** — bárki elolvashatja




---

## S166 C_DLL_KOMMUNIKACIOS_PROTOKOLL_RESZLETES_ADATFOLYAM

### C.1 Vásárlás teljes adatfolyam

```
TRADE.EXE                      VASARLAS.DLL
    │                               │
    │──── VTEMP törlése ───────────►│ DELETE FROM VTEMP
    │                               │
    │──── DLL hívás ───────────────►│ vasarlasrutin() → ShowModal
    │                               │
    │                               │ ◄── ARFOLYAM tábla olvasás
    │                               │ ◄── HARDWARE tábla olvasás
    │                               │ ◄── PENZTAR tábla olvasás
    │                               │ ◄── TRANZDIJTABLA olvasás
    │                               │
    │                               │ ──► VTEMP sorok írása (max 6)
    │                               │
    │                               │ ──► kisarfolyamkedvezmeny DLL
    │                               │ ──► bigarfolyamkedvezmeny DLL
    │                               │ ──► kezdijkedvezmeny DLL
    │                               │
    │                               │ ──► ugyfelcontrol DLL
    │                               │     └── terrorcontrol DLL
    │                               │     └── kisugyfel DLL
    │                               │     └── bigcontrol DLL
    │                               │         └── getkiemeltstatusz DLL
    │                               │
    │                               │ ──► blokknyomtatas DLL
    │                               │ ──► confirmrutin DLL
    │                               │
    │                               │ ──► BLOKKFEJ INSERT
    │                               │ ──► BLOKKTETEL INSERT
    │                               │ ──► ARFOLYAM UPDATE (készlet)
    │                               │
    │◄──── visszatérési kód ────────│ _mResult
    │                               │
    │──── VTEMP olvasás ───────────►│ (eredmények)
    │                               │
```

### C.2 DLL hívási mélység

A leghosszabb DLL hívási lánc:

```
TRADE.EXE
  └── VASARLAS.DLL (vasarlasrutin)
       └── BIGARFVALT.DLL (bigarfolyamkedvezmeny)
       └── UGYFEL.DLL (ugyfelcontrol)
            └── KISUGYFEL.DLL (kisugyfel)
            └── BIGCTRL.DLL (bigcontrol)
                 └── GETSTATUS.DLL (getkiemeltstatusz)
                 └── SUPER.DLL (supervisorjelszo)
            └── TERROR.DLL (terrorcontrol)
       └── CONFIRM.DLL (confirmrutin)
       └── BLOKNYOM.DLL (blokknyomtatas)
       └── COPY2FTP.DLL (xmlbemasolas)
```

Maximum **4 szint mély** DLL lánc.




---

## S167 E_OSSZESITETT_KOCKAZATI_MATRIX

| # | Kockázat | Valószínűség | Hatás | Prioritás |
|---|----------|-------------|-------|-----------|
| 1 | SQL injection ügyfélnév mezőn | Alacsony | Magas | 🟡 |
| 2 | Hardcoded FTP jelszó kiszivárgás | Közepes | Magas | 🔴 |
| 3 | XOR log visszafejtése | Magas | Közepes | 🟡 |
| 4 | GDPR adatkérés (törlés/export) teljesíthetetlen | Magas | Magas | 🔴 |
| 5 | Terrorlista nem naprakész | Közepes | Magas | 🔴 |
| 6 | Szankciós ország lista nem teljes | Közepes | Magas | 🔴 |
| 7 | Kerekítési hiba negatív összegnél | Alacsony | Közepes | 🟡 |
| 8 | VTEMP-ben maradt adat (DLL crash) | Alacsony | Közepes | 🟡 |
| 9 | Egyidejű DLL hívás (VTEMP race condition) | Nagyon alacsony | Magas | 🟢 |
| 10 | Firebird adatbázis korrupció (áramszünet) | Alacsony | Nagyon magas | 🟡 |
| 11 | Központi szerver elérhetetlen | Közepes | Magas | 🔴 |
| 12 | Jelszó bruteforce (egyszerű kódolás) | Alacsony | Közepes | 🟡 |




---

## S168 F_AJANLASOK_OSSZEFOGLALASA

### F.1 Azonnali teendők (migráció előtt)

1. **FTP jelszó cseréje** és konfigurációs fájlba helyezése
2. **Terrorlista frissítés** automatizálása
3. **Szankciós lista bővítése** (EU + OFAC teljes)
4. **GDPR adatkezelési tájékoztató** megalkotása
5. **Naplózás megerősítése** — timestamp, hash

### F.2 Migráció során kötelező

1. **100% unit teszt lefedettség** a kerekítési, díjszámítási és AML algoritmusokra
2. **Párhuzamos üzem** — minimum 3 havi bizonylat-összehasonlítás
3. **Bizonylat pixel-pontos egyeztetés** — eredeti vs. modern
4. **Teljes AML szabálykatalógus** reprodukciója és auditálása
5. **RBAC jogosultságkezelés** a pénztáros/supervisor/admin szinteken
6. **Paraméteres SQL** mindenhol
7. **TLS titkosítás** a központi szerver felé

### F.3 Migráció után

1. **Legacy rendszer fokozatos leállítása** — csak teljes párhuzamos validáció után
2. **Adatmigráció** — betűnkénti névtáblák → egyetlen tábla
3. **Havi tábla struktúra** → particionált PostgreSQL tábla
4. **Audit trail** — minden művelet naplózva, GDPR-konform
5. **Automatikus adattörlés** — 8 év + 1 nap után

---

> **Dokumentum vége**
> Készítette: Eszter (Controller Chief) — 2026-04-02
> Forrás: `D:\repo\valutavalto-program\Anti\VALUTA\` forráskód közvetlen elemzése
> Módszer: Reverse engineering + üzleti logika feltárás + kockázatelemzés
> Terjedelem: ~2200 sor, 7 fókuszterület lefedve


---


---

## S169 TAMAS_ELEMZĂSE


---

## S170 TARTALOMJEGYZEK

1. [Rendszerarchitektúra](#1-rendszerarchitektúra)
2. [Adatbázis architektúra](#2-adatbázis-architektúra)
3. [Kommunikációs protokollok](#3-kommunikációs-protokollok)
4. [Állapotkezelés és adatáramlás](#4-állapotkezelés-és-adatáramlás)
5. [Nyomtatási alrendszer](#5-nyomtatási-alrendszer)
6. [Biztonsági architektúra](#6-biztonsági-architektúra)
7. [Telepítési és üzemeltetési modell](#7-telepítési-és-üzemeltetési-modell)
8. [Tesztelhetőségi elemzés](#8-tesztelhetőségi-elemzés)
9. [Migrációs technikai térkép](#9-migrációs-technikai-térkép)

---




---

## S171 FUGGELEK_C_DEVIZANEM_INDEX_TERKEP

A `_dnem[1..27]` tömb indexe kritikus — hardcoded feltételek hivatkoznak rá:

```
Index → ISO Kód → Magyar Név
 1    AUD    Ausztrál dollár
 2    BAM    Bosnyák márka
 3    BGN    Bolgár leva
 4    BRL    Brazil real
 5    CAD    Kanadai dollár
 6    CHF    Svájci frank
 7    CNY    Kínai yuan
 8    CZK    Cseh korona
 9    DKK    Dán korona
10    EUR    Euró        ← Leggyakrabban hivatkozott
11    GBP    Angol font
12    HRK    Horvát kuna (!) ← Már nem létező deviza
13    HUF    Magyar forint ← _hufIndex keresési célpont
14    ILS    Izraeli shakel
15    JPY    Japán jen
16    MXN    Mexikói peso
17    NOK    Norvég korona
18    NZD    Új-zélandi dollár
19    PLN    Lengyel zloty
20    RON    Román lei
21    RSD    Szerb dínár
22    RUB    Orosz rubel
23    SEK    Svéd korona
24    THB    Thai baht
25    TRY    Török líra
26    UAH    Ukrán hrivnya
27    USD    Amerikai dollár ← Második leggyakoribb
```

**Megjegyzés:** HRK (Horvát kuna) még szerepel a tömbbő bár Horvátország 2023-ban bevezette az Eurót. Ez egy technikai adósság.

---




---

## S172 OSSZEFOGLALAS

Az Anti Valutaváltó rendszer egy **jellege szerint monolitikus, implementációban moduláris** Win32 alkalmazás. A 110+ DLL-es plugin architektúra rugalmasságot ad a karbantartásban, de súlyos architektúrális problémákat rejt:

1. **Nincs valódi rétegezés:** Presentation, Business Logic és Data Access egyetlen Pascal fájlban
2. **VTEMP anti-pattern:** Adatbázis táblán keresztüli IPC helyett TransactionContext kellene
3. **Hardcoded minden:** Útvonalak, IP-k, jelszavak, devizanemek
4. **Tesztelhetetlen:** UI-ba ágyazott üzleti logika, globális állapot
5. **Biztonsági adósság:** XOR obfuszkáció, backdoor jelszó, plaintext credentials

**A migráció során a legkritikusabb feladat:** a VTEMP-alapú állapotgép pontos megértése és reprodukálása — ez a rendszer valódi „lelke", amelyen minden tranzakció áthalad. A golden master tesztelési megközelítés a migrációs kockázat csökkentésének legjobb útja.

---

---




---

## S173 FUGGELEK_E_OTP_TERMINAL_INTEGRACIO_RESZLETEI

### E.1 OTP.DLL Architektúra

Az OTP terminál integráció TCP socket kommunikációt használ (Indy komponenskönyvtár):

```pascal
// OTP.DLL — IdTCPClient1 komponens
IdTCPClient1 : TIdTCPClient;

// Csatlakozás:
function TOTPTERM.Csatlakozas: boolean;
begin
  IdTCPClient1.Host := _host;   // OTP terminál IP/COM
  IdTCPClient1.Port := ...;     // OTP protokoll port
  result := IdTCPClient1.Connected;
end;

// Kommunikáció:
function TOTPTERM.CsomagKuldes: boolean;
// Bináris csomag küldés + válasz fogadás

// LRC ellenőrzőkód számítás:
function TOTPTERM.GetLrcKod(_m: string): word;
// Longitudinal Redundancy Check — EFTPOS protokoll szabvány
```

### E.2 OTP Tranzakció Típusok

```pascal
// Az OTP modul az alábbi paneleket tartalmazza:
VasarlasPanel        → POS vásárlás (bankkártya terhelés)
StornoPanel          → Vásárlás sztornó
AruVisszavetPanel    → Áruvisszavétel
PenztarosBelep       → POS terminál pénztáros beléptetés
PenztarosKilepAndClose → POS terminál pénztáros kiléptetés + zárás
TerminalZaras        → POS napi zárás
ParaLetoltes         → POS paraméter letöltés
ReprintRutin         → Bizonylat újranyomtatás
```

### E.3 OTP Hibakezelés

```pascal
// GetHibaText(_hks: string) — OTP hibakód → szöveg konverzió
// KodSeek(_a: byte) → bináris adat feldolgozás
// DeKonv(_s: string) → terminál üzenet dekódolás
// GetMessString → fő üzenet string
// GetSubHmess54 / GetSubHmess90 → al-üzenetek (típusonként)
```

---




---

## S174 FUGGELEK_G_FOGLALASI_RENDSZER_RESZLETEI

### G.1 Foglalás Adatmodell (FOGLALO.DLL)

```pascal
// FOGLALO tábla mezői (FoglaloQuery mezők alapján):
FoglaloQueryDatum           : TIBStringField;   // foglalás dátuma
FoglaloQueryUgyfelszam      : TIntegerField;     // ügyfél azonosítója
FoglaloQueryUgyfelnev       : TIBStringField;   // ügyfél neve
FoglaloQueryUgyfeltipus     : TIBStringField;   // 'N' vagy 'J'
FoglaloQueryBizonylatszam   : TIBStringField;   // foglalási bizonylat
FoglaloQueryHatarido        : TIBStringField;   // kifizetési határidő
FoglaloQueryRendeltOsszeg   : TFloatField;       // rendelt deviza összeg
FoglaloQueryRendeltErtek    : TFloatField;       // forintban kifejezett érték
FoglaloQueryRendeltValutanem: TIBStringField;   // rendelt deviza ISO kód
FoglaloQueryFoglalo         : TFloatField;       // előleg összege
FoglaloQueryFoglaloValutanem: TIBStringField;   // előleg devizaneme
FoglaloQueryMozgas          : TSmallintField;    // mozgás típusa
FoglaloQueryHivatkozas      : TIBStringField;   // hivatkozási szám
FoglaloQueryStatus          : TSmallintField;    // 0=nyitott, 1=lezárt, 2=lejárt
FoglaloQueryStorno          : TSmallintField;    // 0=normál, 1=sztornózva
FoglaloQueryOsszeg          : TFloatField;       // tényleges összeg (kifizetéskor)
```

### G.2 Foglalás Státuszgép

```
NYITOTT (Status=0)
    │
    ├─► KIFIZETVE (UgyletOkeGomb) → FoglaloKifizetes()
    │       └── Tranzakció rögzítése + bizonylat nyomtatás
    │
    ├─► HATÁRIDŐ MÓDOSÍTÁS (NewtimeGomb) → MasidoPont()
    │       └── FOGLALO.HATARIDO update
    │
    ├─► VISSZAFIZETÉS (UgyletFaultByEBC / UgyletFaultByClient)
    │       └── VisszaFizetoProcedura()
    │           └── Előleg visszafizetése (részleges vagy teljes)
    │
    └─► SZTORNÓZVA (Status=1, Storno=1)
            └── RegiBizTorlese() + ellentétes tranzakció
```

### G.3 E-mail Értesítés (MAPI)

```pascal
// FOGLALO.DLL uses: mapi
procedure TFOGLALO.EmailekKuldese;
// Foglalás visszaigazolás e-mail küldése
// MAPI SimpleMail → alapértelmezett levelezőprogram
// Nincs SMTP direct — csak MAPI wrapper
// Ezért csak Outlook/Windows Mail esetén működik
```

---




---

## S175 FUGGELEK_H_NAPI_KONYV_NAPKONYVDLL_RESZLETEI

### H.1 Értéktár Térkép

```pascal
// NAPKONYV.DLL — értéktár térkép
_etarszam: array[1..8] of integer = (10, 20, 40, 50, 63, 75, 120, 145);
_etarnev: array[1..8] of string = (
  'SZEKSZÁRD',     // 10
  'SZEGED',        // 20
  'KECSKEMÉT',     // 40
  'DEBRECEN',      // 50
  'NYÍREGYHÁZA',   // 63
  'BÉKÉSCSABA',    // 75
  'PÉCS',          // 120
  'KAPOSVÁR'       // 145
);
```

Ez a lista az értéktár kódok (ERTEKTAR mező) és városok közötti leképezés. Az ERTEKTAR értéke alapján tudja a rendszer melyik városban van a pénztár — ez a napi könyv fejlécéhez kell.

### H.2 Napi Könyv Struktúra

```pascal
// Kétpéldányos nyomtatás (KetpeldanyPrint)
// 1. példány: pénztáros példánya
// 2. példány: könyvelési példány

// Napi könyv fejléc (Fejlec):
// - Dátum, nap neve (hétfő, kedd, stb.)
// - Értéktár neve (városnév)
// - Pénztár neve és kódja
// - KFT neve

// Napi könyv sorok (EgyAdatsor):
// SELECT * FROM NAPLOREKORDOK tábla WHERE DATUM=...
// Egy sor: [sorszám] [tranzakció típus] [deviza] [összeg] [pénztáros]

// Matematikai összesítés (Szamtan):
// Napi bevétel, kiadás, nyitó, záró készlet számítás

// Zárósor (Lablec):
// Aláírási sor (pénztáros + ellenőr)
```

---




---

## S176 FUGGELEK_I_CIMLETEZESI_ALRENDSZER_RESZLETEI

### I.1 Cimlet Struktúra (CIMLET.DLL)

```pascal
// TCimletezes.IbTabla → CIMLET_SETUP tábla (rekonstruált)
// Minden devizanemhez 14 féle bancímlet lehetséges (Cc1..Cc14 panelek)
// Minden sorhoz: névérték (Nn1..Nn27 panelek) + darab (Dd1..Dd27 panelek)
// + eredmény (Rr1..Rr14 panelek) + bevitel (Ed1..Ed14 edits)

// A 27 devizanem × 14 féle cimlet = max 378 cimlet típus tárolható

// INI fájl struktúra (CiminiBeolvasas/SaveCimini):
// Szekció: [EUR], [USD], stb.
// Kulcs: Cc1=100, Cc2=50, stb. (névértékek)
// Ez devizanemenkénti INI szekció
```

### I.2 Cimlet Ellenőrzés (CIMLCTRL.DLL)

```pascal
// Napzáráskor kötelező cimlet-ellenőrzés:
// cimletctrlrutin() → összehasonlítja a számított készletet
// a pénztáros által megszámlált cimletekkel

// Eltérés esetén:
// - Figyelmeztető üzenet
// - De a napzárás folytatható (warning, nem error)
```

---




---

## S177 FUGGELEK_J_SZTORNO_RESZLETES_ALGORITMUS

### J.1 Négy Sztornó Típus

```pascal
// VR = Vétel sztornó
// ER = Eladás sztornó
// UR = Ügyfél sztornó (ügyfélrekord érvénytelenítés)
// FR = Forráskód sztornó

// BizLista(_ST: string):
// SELECT * FROM HAVIFEJTABLA WHERE STORNO=0 AND TIPUS LIKE '_ST%'
// AND DATUM=MEGNYITOTTNAP
// ORDER BY DATUM DESC, IDO DESC
```

### J.2 Ellentétes Tranzakció Logika

```pascal
// EllenTranzakcio():
// 1. Bizonylat tételek beolvasása HAVITETELTABLA-ból
// 2. Minden tételre fordított előjel: '+' → '-', '-' → '+'
// 3. Készlet visszaállítás:
//    ValutaStorno() → UPDATE KESZLET SET MENNYISEG += visszaadott deviza
//    HUF visszavétel → UPDATE KESZLET SET MENNYISEG -= visszaadott HUF
// 4. Göngylölet visszavonás:
//    GongyoletVissza() → GONGBACK.DLL
// 5. OTP kártyás tranzakció esetén:
//    OtpTermStorno() → OTP terminálra visszavonás
//    OtpAruVisszavet() → áruvissza jel küldése

// Ervenytelenites():
// UPDATE HAVIFEJTABLA SET STORNO=1 WHERE BIZONYLATSZAM=...
// UPDATE HAVITETELTABLA SET STORNO=1 WHERE BIZONYLATSZAM=...
// INSERT INTO HAVIFEJTABLA (... STORNOBIZONYLAT=...) → ellentétes bejegyzés
```

### J.3 Biztonsági Korlátok

```pascal
// Sztornó korlátok (kódból rekonstruálva):
// _napistorno: byte   ← napi sztornó darabszám számláló
// _maistornodarab: byte ← mai sztornó darabszám
// _maxnum: byte        ← maximum napi sztornó (HARDWARE táblából?)

// SureStorno(): dupla megerősítés kérés
// "BIZTOSAN SZTORNÓZZA?" → Igen/Nem
// Ha Igen → SurePanel visible + befejező "VALÓBAN?" kérdés
```

---




---

## S178 FUGGELEK_K_RENDSZERPARAMETER_TELJES_KATALOGUS

### K.1 PARAMETERS Tábla Mező Szemantika

| Mező | Típus | Tartalom | Megjegyzés |
|------|-------|----------|-----------|
| ELESITVE | SMALLINT | 0/1 | Rendszer aktivált-e |
| ELESITESIDEJE | CHAR(16) | 'éééé.hh.nn óó:pp' | Aktiválás időpontja |
| LASTMATRICA | INTEGER | pl. 5432 | Utolsó matrica bizonylat sorszám |
| LASTTELEFON | INTEGER | pl. 1234 | Utolsó telefon bizonylat sorszám |
| TERMINALID | CHAR(4) | pl. 'SZKS' | 4 karakteres terminál azonosító |
| USERNAME | VARCHAR(20) | pl. 'antiuser' | Rendszer autentikáció |
| JELSZO | VARCHAR(50) | '$...' XOR kódolt | Rendszer jelszó |

### K.2 HARDWARE Tábla Mező Szemantika

| Mező | Típus | Tartalom | Példa |
|------|-------|----------|-------|
| PRINTER | SMALLINT | 0=LPT1, 1=USB | 0 |
| ERTEKTAR | SMALLINT | Városkód (etarszam[]) | 10 (Szekszárd) |
| MEGNYITOTTNAP | CHAR(10) | 'éééé.hh.nn' | '2026.01.15' |
| HOST | VARCHAR(20) | Remote szerver IP | '193.68.57.146' |
| VERZIO | VARCHAR(10) | Telepített verzió | '35.25' |
| VFD | SMALLINT | Vevőkijelző | 0=nincs |
| KELLMATRICA | SMALLINT | E-matrica aktív | 0/1 |
| KELLWESTERN | SMALLINT | WU aktív | 0/1 |
| KELLOTP | SMALLINT | OTP terminál aktív | 0/1 |
| NAV | SMALLINT | NAV kapcsolat aktív | 0/1 |
| NAVCOM | BYTE | NAV COM port száma | 1..9 |

---




---

## S179 FUGGELEK_L_NAPLOZASI_RENDSZER_RESZLETEI

### L.1 Log Fájl Struktúra

```
C:\VALUTA\TRADELOG\
├── LOG2026_01_15.dat   ← 2026.01.15 napi log
├── LOG2026_01_16.dat   ← 2026.01.16 napi log
└── ...

Fájlnév minta: 'LOG' + év + '_' + hónap + '_' + nap + '.dat'
```

### L.2 SetLogFile Implementáció

```pascal
// TRADE.EXE — SetLogFile()
procedure TForm1.SetLogFile;
begin
  _logfile := 'LOG' +
              inttostr(_aktev) + '_' +
              nulele(_aktho) + '_' +
              nulele(_aktnap) + '.dat';
  _logPath := _tradeLogDir + '\' + _logfile;
  // Fájl megnyitás append módban
  AssignFile(_logiro, _logPath);
  if fileExists(_logPath) then
    Append(_logiro)
  else
    Rewrite(_logiro);
end;

// Logbair() — naplóbejegyzés írása
procedure TForm1.Logbair(_mondat: string);
begin
  writeln(_logiro, Kodxor('[' + timetostr(time) + '] ' + _mondat));
  flush(_logiro);
end;
```

### L.3 Log Tartalom (XOR visszafejtés után)

A log bejegyzések mintája (visszafejtve):
```
[08:32:15] Valuta vásárlásba kezd
[08:32:16] ---------------------------------
[08:32:16]      Valuta vásárlásba kezd
[08:32:16] ---------------------------------
[08:32:16] ...
[08:32:16] Előzetes bizonylatsz.m: 00012345
[08:35:22] Ügyfél azonosítás kezd
[08:35:45] Ügyfél azonosítva: Kovács János
[08:35:46] Terror szűrés - nincs találat
[08:36:01] Bizonylat regisztrálva: 00012345
[08:36:02] Remote lerendezés OK
[08:36:03] Nyomtatás kész
```

---




---

## S180 FUGGELEK_M_KOMPLEX_MEZOKOLCSONHATASOK

### M.1 Árfolyam Típusok (SETRATE.DLL)

```pascal
// SETRATE.DLL → ARFTMK.DLL
// Három árfolyam típus:
// _wVarf      = vételi árfolyam (pénztár devizát vesz)
// _wEarf      = eladási árfolyam (pénztár devizát ad)
// _wElszarf   = elszámolási árfolyam (belső számítás)

// Típusonként más DLL:
// Kis árfolyam kedvezmény: KISARFVALT.DLL
// Nagy árfolyam kedvezmény: BIGARFVALT.DLL
// Határ: a BIGCTRL.DLL egy küszöbértékkel dönti el (EVIMAX mező?)
```

### M.2 Konverziós Tranzakció

```pascal
// Konverzió = devizacsere devizára (nem HUF-ra)
// Pl.: EUR → USD (nem EUR → HUF → USD, hanem közvetlen)
// _ezKonverzio: boolean flag
// KonvCimPanel, KonvSumPanel → konverziós UI panelek

// Konverzió adatai VTEMP-ben:
// NEVTABLA = 'KONV'
// KonvDataVtempbe() → konverziós adatok VTEMP-be írása

// Konverziónál két sor keletkezik a HAVITETELTABLA-ban:
// Sor 1: EUR -100 × 390 = -39000 (kiadott EUR)
// Sor 2: USD +108 × 360 = +38880 (kapott USD)
// A különbség (120 Ft) = kezelési díj
```

### M.3 Plombaszám Rendszer

```pascal
// GETPLOMB.DLL → plombaszám lekérdezés
// A plombaszám fizikai jelzés a pénztártáska plombálásán
// Minden tranzakcióhoz rögzítésre kerül (HAVIFEJTABLA.PLOMBASZAM)
// Az átadólapon szerepel (ATADOLAP.DLL)

// Plombaszám formátum: valószínűleg sorozatszám (XXXX-YYYYYYYY)
// GETPLOMBASZAM form → felhasználó beírja a sorozatszámot
```

---



---


---

## S181 GABOR_ELEMZĂSE


---

## S182 TARTALOMJEGYZEK

1. Vezetői összefoglaló
2. A legacy rendszer vizuális DNA-ja — DFM alapú elemzés
3. Navigációs architektúra elemzés
4. Képernyő-katalógus és ASCII wireframe-ek
   - 4.1 Főmenü (TRADE.EXE / Form1)
   - 4.2 Devizavásárlás (VASARLASFORM)
   - 4.3 Devizaeladás (ELADASFORM)
   - 4.4 Sztornó (STORNOFORM)
   - 4.5 Napzárás (NAPZARFORM)
   - 4.6 Bizonylat megjelenítő (BIZONYLATDISP)
   - 4.7 Ügyfél bevitel (UGYFELINPUT)
   - 4.8 Pénztáros belépés (PROSBELEP)
   - 4.9 Supervisor menü (SUPERVISORFORM)
   - 4.10 Foglalás (FOGLALO)
   - 4.11 Címletezés (CIMLETEZES)
   - 4.12 Bizonylat nyomtatás (BLOKKNYOM)
5. UI/UX antipatternák — részletes kritikai elemzés
6. Felhasználói folyamatok (User Flows) elemzése
7. Kognitív terhelés és ergonómia
8. Modern design rendszer javaslat
9. Komponens-könyvtár és design token-ek
10. Képernyő-architektúra a modern rendszerhez
11. Kritikus UX döntési pontok
12. Prioritás-mátrix és implementációs ütemterv
13. Összefoglalás

---




---

## S183 11_KRITIKUS_UX_DONTESI_PONTOK

### 11.1 Single Page Application vs. Multi-Window

**Kérdés:** Az Electron alkalmazás egyszerre egy ablakot használjon (SPA-szerű), vagy nyithatók legyenek párhuzamos ablakok?

**Javaslat:** SPA + drawer/panel alapú megközelítés. Az eddigi modal-heavy rendszerrel szemben egyetlen ablakban, belső navigációval. Ez:
- Megakadályozza az ablakok összetévesztését
- Jobb állapotkezelés (React state)
- Könnyebb keyboard-navigáció

**Kivétel:** A VFD ügyfélkijelző (customer-facing display) külön ablakban futhat.

### 11.2 Bizonylat nyomtatás stratégia

**Jelenlegi:** LPT1 párhuzamos port → közvetlen ESC/POS
**Modern opciók:**
1. ESC/POS over USB (megtartja a hardver-kompatibilitást, Node.js driver)
2. Thermal printer WebUSB API (Electron-kompatibilis)
3. HTML→PDF→print (rugalmasabb, de lassabb)

**Javaslat:** Hibrid megközelítés — az ESC/POS nyomtató-specifikus layer megtartása (gazdasági kényszerpálya), de a bizonylat-template HTML/CSS alapú legyen, amit runtime konvertál ESC/POS-ra.

### 11.3 Offline működés

**Jelenlegi:** A rendszer induláskor `Vaninternet` ellenőrzés — ha nincs internet, NEM indul el.

**Modern javaslat:** Offline-first architektúra:
- Helyi SQLite/IndexedDB a tranzakciók átmeneti tárolására
- Szinkronizáció hálózat-visszaálláskor
- "Offline mód" banner a UI-ban, amely jelzi az állapotot
- Árfolyamok lokálisan cache-elve (max. 24 órás érvényesség)

### 11.4 Supervisor auth modern megközelítés

**Jelenlegi:** SUPER.dll → jelszó dialog → tovább

**Modern javaslat:**
- PIN-kód alapú supervisor auth (nem jelszó gépelés, hanem 4-6 számjegy)
- Biometrikus opció (Windows Hello kompatibilis Electron-ban)
- Supervisor session token: 15 perces érvényes, utána újra auth
- Audit log minden supervisor műveletről

### 11.5 Árfolyam módosítás UX

**Jelenlegi:** `ArfolyamGomb` → ARFVALT.dll / BIGARFVALT.dll / KISARFVALT.dll → supervisor jelszó

**Modern javaslat:**
- Inline árfolyam-szerkesztés a tranzakciós képernyőn (supervisor auth után)
- Változásnapló: mikor, ki, mennyivel módosított
- Szándékos jóváhagyás: "Biztos, hogy 395.50-ről 393.00-re módosítja?"
- Opcionális: piaci árfolyam-lekérés (MNB API) referencia célból

---




---

## S184 13_OSSZEFOGLALAS

### 13.1 A legacy rendszer értékelése

Az Anti Valutaváltó rendszer egy **funkcionálisan komplett, üzletileg érett, de vizuálisan és ergonómiailag elavult** Delphi 7 alkalmazás. A 110+ DLL modularitás mesteri mérnöki döntés volt a maga korában — de az ebből fakadó modal-heavy, blokkoló UX ma már nem elfogadható.

**Amit meg kell menteni:**
- A lineáris, logikus tranzakciós workflow (Vétel/Eladás/Sztornó)
- A billentyűzetes, keyboard-first munkamód (End/Escape paradigma)
- A supervisor/pénztáros szerepkör-elválasztás
- A 300k limit kötelező ügyfél-azonosítás vizuális jelzése
- A napzárás lépésenkénti checklist logikája

**Amit el kell hagyni:**
- Abszolút pixel-koordináták → CSS Flexbox/Grid
- 8+ különböző szín- és fontrendszer → design token
- Beágyazott JPEG háttérképek → SVG/CSS
- Modal-pokol → wizard-alapú SPA flow
- XOR "titkosítás" → valódi kriptográfia
- Hardkódolt IP/FTP credentials → environment config
- LPT1 közvetlen nyomtatás → modern printer API réteg

### 13.2 A legkritikusabb DFM-megfigyelések összegzése

1. **VASARLASFORM `AlphaBlendValue=225`** — ez az egyetlen form, amelynek alpha-blend értéke van, de a tesztben ez helyes (225/255 ≈ 88% opák, alig átlátszó)

2. **NAPZARFORM `AlphaBlendValue=180`** — 70% opák; a napzárás képernyő áttetsző, ami lehetővé teszi az alatta lévő tartalom átütközését — ez valószínűleg véletlen konfiguráció, nem szándékos design

3. **PROSBELEP `AlphaBlendValue=200`** — 78% opák login képernyőn; ez biztonsági aggályokat vet fel (az előző session data átütközik)

4. **FOGLALO `Image1` alClient JPEG** — egy tengerpart fotó teljes képernyős háttérként a foglalási modulban; üzleti célra teljesen inkongruens

5. **UGYFELINPUT `VIRAG` TImage Left=-2200** — egy off-screen komponens, valószínűleg egy korábbi háttérkép maradványa — code hygiene probléma

6. **STORNO `Elephant` font** — egy kalandregény-stílusú dekoratív font a pénztári rendszer legkritikusabb (visszavonási) formján

7. **VASARLAS `6324288` vs ELADAS `16756991`** — a két legfontosabb formnak teljesen eltérő háttérszíne van; ez ugyan segíti a megkülönböztetést, de nem rendszertervezett döntés

8. **CIMLETEZES 14×n input mező** — a 14 devizanem × több (legalább 4-6) bankjegy-típus × 2 (bevétel/kiadás) ≈ 100+ mező; ez még a legtapasztaltabb pénztáros számára is rendkívüli kognitív terhelés

9. **BLOKKNYOM `272×56px` form** — egy postage stamp méretű form, ami nyomtatás alatt villan fel; ez elfogadható, de egy modern toast notification elegánsabb megoldás lenne

10. **TRADE főmenü `Stencil` font + NYC háttérkép** — a katonai stencil betűtípus és a New York-i városképes háttérkép teljesen inkongruens egy pénztári rendszer főmenüjéhez

### 13.3 A modern rendszer design garanciái

A Java+React+Electron platformon épülő modern rendszer az alábbi design garanciákat kell teljesítse:

1. **Egy design language** — egyetlen szín-token rendszer, egyetlen fontcsalád, következetes spacing
2. **Keyboard-first** — minden funkció elérhető billentyűzetről, minden shortcut látható a status bar-ban
3. **< 3 kattintás** — bármely főfunkció (vétel, eladás, sztornó) legfeljebb 3 interakcióval kezdeményezhető
4. **Regulatory compliance by design** — a 300k limit, terror szűrés, PEP nyilatkozat vizuálisan kiemelkedő, nem elrejthető
5. **Offline-first** — internet-kiesés esetén a rendszer nem omlik össze, hanem szivárgásmentes módban működik tovább
6. **Auditálható** — minden supervisor művelet, árfolyam-módosítás, sztornó azonnal naplózódik és kereshető
7. **Skálázható** — 1080p, 1440p, 4K képernyőkön egyaránt jól néz ki és használható
8. **Akadálymentes** — WCAG 2.1 AA megfelelőség (főleg a kontrasztarány és a keyboard navigáció)

---

> **Gábor, Design & Graphics Chief** — 2026-04-02
>
> Ez az elemzés a `antivaluta-junior.md` rendszer-áttekintés és az `anti-dfm-pack.md` DFM layout-csomag alapján készült. Minden DFM-hivatkozás az eredeti Delphi 7 forráskódból származó tényleges adatot tükröz. Az ASCII wireframe-ek a koordináta-adatokból rekonstruált becsült layout-ok, nem pixel-pontos reprodukciók.

---




---

## S185 20_KIEGESZITO_DESIGN_QA_ELLENORZOLISTA_A_MIGRACIOHOZ

Az alábbi ellenőrzőlista minden egyes React komponens implementálásakor alkalmazandó:

### 20.1 Vizuális ellenőrzőlista

- [ ] A komponens design token-eket használ (nem hardkódolt hex értékeket)
- [ ] A szövegek Inter fontban jelennek meg, nem rendszer-default fontban
- [ ] A kontrasztarány WCAG AA szintet teljesít (minimum 4.5:1 normál szövegnél)
- [ ] A komponens 1080p, 1440p és 4K felbontáson egyaránt tesztelt
- [ ] A komponens 125% és 150% Windows kijelzőméret-skálánál is helyes
- [ ] A hover és focus állapotok vizuálisan megkülönböztethetők
- [ ] Az aktív/inaktív állapotok vizuálisan megkülönböztethetők
- [ ] A hibás állapot (validation error) vizuálisan egyértelmű (nem csak piros szín)

### 20.2 Interakciós ellenőrzőlista

- [ ] Minden gomb elérhető Tab-bal és Enter/Space-szel
- [ ] Minden dropdown/select navigálható nyíl billentyűkkel
- [ ] Minden modal bezárható Escape-pel
- [ ] A fókusz-sorrend logikus (balról jobbra, fentről lefele)
- [ ] A fókusz nem "szökik meg" modálok mögé (focus trap implementálva)
- [ ] Gyors gépelők számára: Enter az aktuális mezőből továbblép (nem submit-ol)

### 20.3 Üzleti logika ellenőrzőlista

- [ ] Az árfolyam feltűnően látható a tranzakciós képernyőn
- [ ] A 300 000 Ft-os AML küszöb vizuális figyelmeztetés
- [ ] A napzárás előrehaladása mindig látható (progress indicator)
- [ ] A sztornó dupla megerősítést kér (és az inaktív gomb nem kattintható véletlenül)
- [ ] Az ügyfél-azonosítás kötelező mezői be nem töltéskor nem enged továbblépni
- [ ] A bizonylat nyomtatás meghiúsulása esetén egyértelmű hibaüzenet és újrapróbálási lehetőség

### 20.4 Adatvédelmi ellenőrzőlista

- [ ] Az ügyfél személyes adatai csak a szükséges ideig jelennek meg a képernyőn
- [ ] A pénztáros-váltáskor az előző session adatai nem láthatók (nem átlátszó login képernyő)
- [ ] A bizonylat részletei csak jogosult pénztárosoknak láthatók
- [ ] Az exportált fájlok (CSV, PDF) jelszóvédhetők

---




