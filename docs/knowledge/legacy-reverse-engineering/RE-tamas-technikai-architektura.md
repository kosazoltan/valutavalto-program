---
type: reference
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Anti Valutavalto — Technikai Architektura es Integracios Elemzes"
load: on-demand
---

# Anti Valutaváltó — Technikai Architektúra és Integrációs Elemzés
## S1 TAMAS_TESTOPS_CHIEF_MELYARCHITEKTURA_ELEMZES

> **Dátum:** 2026-04-02  
> **Elemző:** Tamás (testops/Claude Sonnet 4.6)  
> **Forrás:** `D:\repo\valutavalto-program\Anti\VALUTA\`  
> **Referenciák:** `antivaluta-junior.md`, `anti-context-pack.md`, közvetlen forráskód-beolvasás  
> **Célközönség:** Migrációs csapat, tesztstratégia, architektúratervezés

---


---

## S2 TARTALOMJEGYZEK

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

## S3 1_RENDSZERARCHITEKTURA

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

## S4 2_ADATBAZIS_ARCHITEKTURA

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

## S5 3_KOMMUNIKACIOS_PROTOKOLLOK

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

## S6 4_ALLAPOTKEZELES_ES_ADATARAMLAS

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


---

## S7 5_NYOMTATASI_ALRENDSZER

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

## S8 6_BIZTONSAGI_ARCHITEKTURA

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

## S9 7_TELEPITESI_ES_UZEMELTETESI_MODELL

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


---

## S10 8_TESZTELHETOSEGI_ELEMZES

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

## S11 9_MIGRACIOS_TECHNIKAI_TERKEP

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

## S12 FUGGELEK_A_DLL_HIVASI_OSSZEFOGLALAS

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


---

## S13 FUGGELEK_B_GLOBALIS_VALTOZO_KATALOGUS_KRITIKUS_ELEMEK

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


---

## S14 FUGGELEK_C_DEVIZANEM_INDEX_TERKEP

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

## S15 FUGGELEK_D_BIZTONSAGI_LELETJEGYZEK

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


---

## S16 OSSZEFOGLALAS

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

## S17 FUGGELEK_E_OTP_TERMINAL_INTEGRACIO_RESZLETEI

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

## S18 FUGGELEK_F_WESTERN_UNION_INTEGRACIO_RESZLETEI

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

## S19 FUGGELEK_G_FOGLALASI_RENDSZER_RESZLETEI

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

## S20 FUGGELEK_H_NAPI_KONYV_NAPKONYVDLL_RESZLETEI

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

## S21 FUGGELEK_I_CIMLETEZESI_ALRENDSZER_RESZLETEI

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

## S22 FUGGELEK_J_SZTORNO_RESZLETES_ALGORITMUS

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

## S23 FUGGELEK_K_RENDSZERPARAMETER_TELJES_KATALOGUS

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

## S24 FUGGELEK_L_NAPLOZASI_RENDSZER_RESZLETEI

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

## S25 FUGGELEK_M_KOMPLEX_MEZOKOLCSONHATASOK

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

## S26 VEGSO_OSSZEFOGLALO_TESZTELESI_PRIORITASOK

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
