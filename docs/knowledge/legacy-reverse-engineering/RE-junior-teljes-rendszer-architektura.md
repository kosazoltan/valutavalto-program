---
type: reference
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Anti Valutavalto — Teljes Reverse Engineering Elemzes"
load: on-demand
---

# Anti Valutaváltó — Teljes Reverse Engineering Elemzés
## S1 JUNIOR_SZOFTVERFEJLESZTO_AGENS_ELEMZESE

> **Dátum:** 2026-04-02
> **Forrás:** `D:\repo\valutavalto-program\Anti\VALUTA\`
> **Technológia:** Delphi 7, Firebird/InterBase, Win32 DLL plugin architektúra
> **Méret:** 6972 fájl, ~1.7 GB, 420 .pas, 419 .dfm, 279 .dpr, 131 .dll

---


---

## S2 1_ALKALMAZAS_ARCHITEKTURA

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

## S3 2_FOMENU_ES_MENUPONTOK

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

## S4 3_TELJES_DLL_MODUL_KATALOGUS_110_MODUL

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

## S5 4_UZLETI_LOGIKA_RESZLETES_ELEMZES

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

## S6 5_BIZONYLATOK_RESZLETES_ELEMZES

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

## S7 6_UGYFELKEZELES_ES_AMLTMK

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

## S8 7_ADATBAZIS_SEMA

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

## S9 8_SZERVER_KOMMUNIKACIO_ES_SZINKRONIZACIO

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

## S10 9_BIZTONSAGI_MECHANIZMUSOK

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

## S11 10_HARDVER_INTEGRACIO

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

## S12 11_KONFIGURACIO

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

## S13 12_OSSZEFOGLALO

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
