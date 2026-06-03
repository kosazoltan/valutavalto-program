# Legacy modul (VALUTA): ARFREG

> Forrás (primer): `Anti/SZERVER/_extracted/VALUTA/DLL/ARFREG/DEBUG/Unit2.pas` (32730 karakter)
> KORREKCIÓ: az `Anti/VALUTA/DLL/` mappában 0-bájtos stub volt; a VALÓDI forrás az `Anti/SZERVER/_extracted/VALUTA/DLL/` mappában található.

## Exportált API
`arfolyamregiszter`

## Eljárások / függvények
`FormActivate`, `ArfolyamRogzites`, `ArfolyamKijelzes`, `MakeArfolyamTabla`, `EgyracsDisplay`, `EgyIdoBeolvasas`, `RacsTakarito`, `Intdekodol`, `RealToStr`, `Limitform`, `RACSDrawCell`, `VISSZAGOMBClick`, `REGEBBIGOMBClick`, `datumrendbengombClick`, `EHAVIGOMBClick`, `Nulele`, `RealFormat`, `LIMITGOMBClick`, `USZOTIMERTimer`, `KEDVVISSZAGOMBClick`, `KOVETKEZOGOMBClick`, `kilepoTimer`, `MASIKHONAPGOMBClick`, `ELOZOGOMBClick`, `HunDatetostr`, `EVCOMBOChange`, `arfolyamregiszter`, `TARFOLYAMTAROLO.FormActivate`, `TArfolyamTarolo.ArfolyamRogzites`, `TArfolyamTarolo.Intdekodol`, `TArfolyamTarolo.RealToStr`, `TArfolyamTarolo.MakeArfolyamTabla`, `TarfolyamTarolo.ArfolyamKijelzes`, `TARFOLYAMTAROLO.RACSDrawCell`, `TARFOLYAMTAROLO.VISSZAGOMBClick`, `TArfolyamTarolo.RegebbiGombClick`, `TARFOLYAMTAROLO.datumrendbengombClick`, `TARFOLYAMTAROLO.EHAVIGOMBClick`, `TArfolyamTarolo.Nulele`, `TarfolyamTarolo.EgyracsDisplay`

## Érintett adatbázis-táblák
`PENZTAR`

- `SELECT * FROM PENZTAR`
- `DELETE FROM`
- `WHERE (DATUM=`
- `INSERT INTO`
- `SELECT * FROM`

## Felhasználói üzenetek
- A KÉRT HÓNAPRÓL NINCSENEK ADATAIM !
- ÜRES AZ ADATBÁZIS
- NEM VOLT A HÓNAPBAN TÖBB ÁRFOLYAMVÁLTOZÁS
- Nem volt a hónapban ez elött másik árfolyam

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
