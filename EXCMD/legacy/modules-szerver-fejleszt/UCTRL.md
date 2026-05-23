# Legacy modul (SZERVER-FEJLESZT): UCTRL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/uctrl/butitott/unit1.pas` (76202 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/uctrl/adatpotlo/adatpotlo.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TGETIDOSZAK`, `TADATFELTOLTES`, `TMAKEEXCEL`, `Timportform`

**Feliratok/gombok (Caption):** Form1 · HI · PROGRAM INDIT · KIL · TOV · BitBtn1 · A KERESETT  · ANYJA NEVE · SZ · OKM · AZONOS · EL · LE · LAKCIMK · TARTOZKOD · 2019 · TERM · Keresett szem · VISSZA A MEN · JOGI SZEM · TELEPHELY C · OKIRAT SZ · MEGBIZOTT NEVE · MEGBIZOTT BEOSZT · Az Exclusive Change kft 

## Eljárások / függvények (.pas)
`FormActivate`, `IdBeolvasas`, `Menube`, `SetKertev`, `TiltotValasztott`, `Nul3`, `Angolra`, `TetelDisplay`, `HutoGb`, `DoubleKill`, `KILEPOGOMBClick`, `KERESOGOMBClick`, `NEVEDITEnter`, `NEVEDITExit`, `IrodaBeolvasas`, `NEVEDITKeyDown`, `MENUBEGOMBClick`, `NATURRACSDblClick`, `NATURRACSKeyDown`, `NevetValasztott`, `AllAdatBeolvasas`, `Alldisplay`, `FtForm`, `BACKGOMBClick`, `NRADIOClick`, `JMENUBEGOMBClick`, `Nevkereses`, `BIZRACSDblClick`, `FoMenube`, `RacsDisplay`

## Érintett adatbázis-táblák
`FEJEK`, `IRODAK`, `JOGI`, `PENZTAROSOK`, `TETELEK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE NEV LIKE`
- `SELECT * FROM JOGI`
- `WHERE JOGISZEMELYNEV LIKE`
- `WHERE SORSZAM=`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM IRODAK`
- `WHERE CLOSED=`
- `INSERT INTO`
- `UPDATE`
- `SELECT * FROM FEJEK`
- `SELECT * FROM TETELEK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL
- ILYEN NEVÜ ÜGYFELÜNK NINCS.ADJON MEG MÁSIK NEVET !
- NEM SIKERÜLT A KÉRÉST KIKÜLDENI
- A kért okmányokat a C:\UCTRL\DATA könyvtárba másoltam

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
