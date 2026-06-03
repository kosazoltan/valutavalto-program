# Legacy modul (VALUTA): ADATLAP

> Forrás (primer): `Anti/SZERVER/_extracted/VALUTA/DLL/ADATLAP/DEBUG/Unit2.pas` (46203 karakter)
> KORREKCIÓ: az `Anti/VALUTA/DLL/` mappában 0-bájtos stub volt; a VALÓDI forrás az `Anti/SZERVER/_extracted/VALUTA/DLL/` mappában található.

## Exportált API
`adatlaprutin`

## Eljárások / függvények
`FormActivate`, `KartonDisplay`, `UgyfelDataRead`, `Kozepreir`, `JogiDataRead`, `GongyErtekDisp`, `VonalHuzo`, `cancelgombClick`, `ADATLAPRACSKeyDown`, `AdatlapBeolvaso`, `UrlapFeltolto`, `BitBtn1Enter`, `BitBtn1Exit`, `korvisszagombClick`, `Valutaparancs`, `MINORTRANSGOMBClick`, `MAJORTRANSGOMBClick`, `ELOZOGOMBClick`, `KOVETKEZOGOMBClick`, `FormKeyDown`, `ADATLAPRACSDblClick`, `MODRENDBENGOMBClick`, `GetnaturAdatok`, `GetJogiadatok`, `MegbizoKereso`, `Ninelen`, `LapformClear`, `JogiDisp`, `TextKiiro`, `Pirosito`, `adatmodositogombClick`, `CIMEDITEnter`, `CIMEDITExit`, `MainJob`, `CIMEDITKeyDown`, `BitBtn2Click`, `Bejelentesnyomtatas`, `WriteNaturAdatok`, `WriteJogiadatok`, `StartNyomtatas`

## Érintett adatbázis-táblák
`ADATLAP`, `GONGYCSOMAG`, `HARDWARE`, `JOGISZEMELY`, `PENZTAR`, `UGYFEL`

- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM ADATLAP`
- `WHERE`
- `SELECT * FROM UGYFEL`
- `WHERE UGYFELSZAM=`
- `UPDATE UGYFEL SET NEV=`
- `SELECT * FROM JOGISZEMELY`
- `UPDATE JOGISZEMELY SET JOGISZEMELYNEV=`
- `SELECT * FROM GONGYCSOMAG`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
