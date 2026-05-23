# Legacy modul (SZERVER-FEJLESZT): TABLOMAK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/tablomak/unit2.pas` (44239 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/tablomak/tablomak.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TUjtabloKeszites`

**Feliratok/gombok (Caption):** Form1 · TABL · AZ UTOLS · KIL

## Eljárások / függvények (.pas)
`FormActivate`, `AdatNullazas`, `Adatfeldolgozas`, `KilepoTimerTimer`, `GetcimletAdatbazis`, `HaviKeszletTolto`, `ElozonapiKeszletek`, `ElozohaviAdatok`, `ElozohaviMainForgalom`, `WriteElonapi`, `AdatParancs`, `KorzetBeolvasas`, `WriteElohavi`, `WriteMainCurrency`, `Tablofeliras`, `KorzetMeghatarozas`, `ByteIras`, `Wordiras`, `RealIras`, `IntegIras`, `StrIras`, `Cimletfeliro`, `ForgalomBeolvasas`, `ErtektarosBeolvasas`, `TalanNemvoltNyitvaElsejen`, `Elohavicimlet`, `Nulele`, `Getvalss`, `ScanDnem`, `ScanKorzet`

## Érintett adatbázis-táblák
`ELOHAVI`, `ELONAPI`, `IRODAK`, `MAINCURR`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1) AND (TIPUS<>`
- `WHERE DATUM<=`
- `WHERE DATUM=`
- `SELECT * FROM ELONAPI`
- `WHERE DATUM<`
- `SELECT * FROM ELOHAVI`
- `WHERE EVHOSTRING<`
- `SELECT * FROM MAINCURR`
- `WHERE (EV=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
