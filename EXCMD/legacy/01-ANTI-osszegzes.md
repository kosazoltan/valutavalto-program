# Anti legacy feldolgozás — konszolidált összegzés (primer forrásból)

> Készült: 2026-05-22. Minden megállapítás a **tényleges fájlrendszerből** verifikálva
> (NEM a korábbi `antivaluta.md`-ből). Az `Anti/` = 5.9 GB, 32 960 fájl.

## Modulonkénti diszpozíció (a tényleges tartalom alapján)

| Modul | Mit tartalmaz valójában (verifikálva) | Diszpozíció |
|---|---|---|
| **VALUTA** | Valódi Delphi forrás: 109 üzleti-logika DLL + IBVALTO kliens + TRADE | ✅ **Feltérképezve** (`00-VALUTA-modul-terkep.md`) — érdemben teljesen lefedett a jelenlegi programban |
| **ARFOLYAM** | CSAK `Arfolyam.exe` bináris + `arfdata.dat` adatfájlok; a `.zip`-ben **0 forrásfájl** | Forrás nem elérhető; a funkciót a Felmérés `b1-arfolyamkeszito` spec fedte (RFM, G7/G22 implementálva) |
| **SZERVER** | 2881 `.pas` — **mind** `_extracted`/`_extracted_auto` alatt (egy korábbi session által kicsomagolt **archívum-duplikátumok**, nem új kódbázis) | Duplikátum — nincs új egyedi forrás |
| **ERTEKTAR** | 1 fájl (minimális) | Az értéktár-funkciók a jelenlegi programban megvannak |
| **KESZLEX** | 64 fájl (készlet-lekérdező) | Készlet-lekérdezés lefedett (CashBalance/stock) |
| **KORLEVEL_ZIP** | körlevél-anyag | ✅ CircularService (G21) |
| **camera / camera2 / camera3** | Java kamera-alrendszer (1614+238+1376 Java fájl) | Külön kamera-rendszer (a jelenlegi programban van camera modul; lásd `ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md`) |
| **firebird** | Firebird 2.1 DB-motor + config | Infrastruktúra (a jelenlegi PostgreSQL-re migrálva) |
| **37 zip/7z** | nagyrészt már kicsomagolva `_extracted_auto`-ba (a SZERVER-duplikátumok) | — |

## Verifikált eredmény

**Az `Anti` egyetlen valódi, egyedi legacy ÜZLETI forráskódja a `VALUTA` modul (109 DLL).** Ezt a tényleges `.pas` ellen feltérképeztem, és a jelenlegi Java/React/Electron program **érdemben teljesen lefedi** (ELADAS/VASARLAS/STORNO/FOGLALO/címletezés/zárások/AML/szankció/WU/ÁFA/átadás-átvétel/riportok/körlevél/beállítások).

A többi „forrás" vagy bináris (ARFOLYAM.exe), vagy adatfájl (arfdata.dat), vagy újra-kicsomagolt duplikátum (SZERVER), vagy külön alrendszer (camera Java), vagy infrastruktúra (firebird).

## A VALUTA-térképből adódó EGYETLEN nem-lefedett rövid lista (verifikálva)

| Tétel | Jelleg | Miért nem implementáljuk most |
|---|---|---|
| **FNYUJSAG** futófény LED-kijelző tábla | hardver (soros/COM port) | Fizikai LED-tábla + Electron-runtime kell; a G20 a beállítást tárolja |
| **SCANNING** fizikai okmány-beolvasás | hardver (szkenner driver) | Fizikai szkenner kell; a G20 a driver-beállítást tárolja |
| **TEAOR** céges tevékenységi kód | marginális | Csak jogi-személy ügyfélnél, ritka a valutaváltásban; kis adat-mező, ha kell |
| **EUAKCIO** EU-akció IGEN/NEM dialógus | triviális | Egyszerű kérdő dialógus, nem érdemi üzleti logika |

→ **Nincs hiányzó érdemi pénztári üzleti funkció a legacy forrásban.** A két hardver-tétel (FNYUJSAG, SCANNING) futó-app (Electron) + fizikai eszköz nélkül nem implementálható/verifikálható; a TEAOR egy opcionális kis adat-mező.

## Auditálhatóság
- VALUTA modul-lista (ground truth): `EXCMD/legacy/valuta-modul-lista.csv`
- VALUTA modul-térkép: `EXCMD/legacy/00-VALUTA-modul-terkep.md`
- A teljes Anti `.gitignore`-olt (5.9 GB) — csak ez a feldolgozás-dokumentáció kerül a repóba.
