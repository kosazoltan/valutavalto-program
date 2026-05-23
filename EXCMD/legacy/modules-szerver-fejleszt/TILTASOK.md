# Legacy modul (SZERVER-FEJLESZT mély): TILTASOK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/tiltasok/debug/unit2.pas` (76082 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/tiltasok/makedll/tiltasok.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`tiltaskezelorutin`

## Eljárások / függvények
`AktJogiNevDisplay`, `AnyjaEditKeyDown`, `AthozoGombClick`, `AthozMegsemGombClick`, `BetuEditKeyDown`, `FormActivate`, `ForrasGombClick`, `LastYearGombClick`, `LetiltoGombClick`, `LocJogiParancs`, `LocNaturParancs`, `LocNaturParancsPart`, `LocJogiParancsPart`, `Levalogatas`, `ListaGombClick`, `JogiLevalogatas`, `JogiTiltottListazas`, `JogiRacsKeyUp`, `JogiListaVisszaGombClick`, `JogiRacsDblClick`, `JogiRacsCellClick`, `JogiGombClick`, `JogiVisszaVonoGombClick`, `JNevEditKeyDown`, `JTelephelyEditKeyDown`, `JFotevEditKeyDown`, `JogiAdatKimasolo`, `JogiAdatBemasolo`, `JogiListaRacsKeyUp`, `JogiListaRacsCellClick`

## DFM Caption-ök
Form1 · INDIT · KILEP · Form2 · TILTOTT SZEM · TERM · JOGI SZEM · AZ  · TILTOTTAK  · VISSZA A MEN · KERES · A LETILTOTT TERM · ANYJA NEVE · SZ · TILT · VISSZA A F · MEGNEVEZ · TELEPHELY CIME · MEGBIZOTT NEVE · A LETILTOTT JOGI SZEM · ANYJA NEVE: · ADATOK RENDBEN · LAKCIM: · CSAK P · TELEPHELY C

## Adatbázis-táblák
`JOGI`, `JOGISZEMELY`, `LASTNUMS`, `UGYFELEK`

- `DELETE FROM UGYFELEK`
- `SELECT * FROM`
- `WHERE TILTVA>0`
- `INSERT INTO UGYFELEK (NEV,ANYJANEVE,SZULETESIHELY,`
- `SELECT * FROM UGYFELEK ORDER BY NEV`
- `UPDATE`
- `WHERE SORSZAM=`
- `DELETE FROM JOGISZEMELY`
- `SELECT * FROM JOGI`
- `WHERE TILTVA=1`

## Felhasználói üzenetek
- NINCS LETILTOTT TERMÉSZETES SZEMÉLY
- NINCS LETILTOTT JOGI SZEMÉLY
- A választott személy már le van tiltva !

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
