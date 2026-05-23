# Legacy modul (SZERVER-FEJLESZT): LISTOPENOFFICES

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/listopenoffices/debug/unit2.pas` (7171 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/listopenoffices/makedll/opofflist.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`openofficelist`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · A K

## Eljárások / függvények (.pas)
`FormActivate`, `IdoszakBeolvasas`, `InitParancs`, `ParancsPart`, `GyujtoParancs`, `KilepoTimer`, `TForm2.FormActivate`, `TForm2.InitParancs`, `TForm2.ParancsPart`, `TForm2.GyujtoParancs`, `TForm2.IdoszakBeolvasas`, `TForm2.KilepoTimer`

## Érintett adatbázis-táblák
`IDOSZAK`, `IRODAK`, `OPENOFFICES`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `SELECT * FROM IRODAK WHERE UZLET=`
- `DELETE FROM OPENOFFICES`
- `INSERT INTO OPENOFFICES (PENZTARSZAM,PENZTARNEV,PENZTARCIM,`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉRT IDŐSZAKBAN NEM VOLT NYITOTT PÉNZTÁR !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
