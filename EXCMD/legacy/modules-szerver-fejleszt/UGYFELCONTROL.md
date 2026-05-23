# Legacy modul (SZERVER-FEJLESZT): UGYFELCONTROL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/tiltasok/debug/unit2.pas` (76082 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/adatgyujto/mnakedll/adatgyujto.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`adatgyujtorutin`

## DFM form(ok) / képernyő
`TForm1`, `TADATFELTOLTES`, `TForm2`, `TGETIDOSZAK`, `TIMPORTFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Panel1 · ADATFELTOLTES · ADATOK LEGY · ADATOK KINULL · IROD · ID · ADATOK BEOLVAS · ADATOK FELIR · OK · Form2 · KFT szerint · RENDBEN · EGYS · FOCIMPANEL · BEST · EXPRESSZ · TELJES C · MELYIK EGYS · Ft · LEGY · VISSZA A MEN · VISSZA A F

## Eljárások / függvények (.pas)
`AktJogiNevDisplay`, `AnyjaEditKeyDown`, `AthozoGombClick`, `AthozMegsemGombClick`, `BetuEditKeyDown`, `FormActivate`, `ForrasGombClick`, `LastYearGombClick`, `LetiltoGombClick`, `LocJogiParancs`, `LocNaturParancs`, `LocNaturParancsPart`, `LocJogiParancsPart`, `Levalogatas`, `ListaGombClick`, `JogiLevalogatas`, `JogiTiltottListazas`, `JogiRacsKeyUp`, `JogiListaVisszaGombClick`, `JogiRacsDblClick`, `JogiRacsCellClick`, `JogiGombClick`, `JogiVisszaVonoGombClick`, `JNevEditKeyDown`, `JTelephelyEditKeyDown`, `JFotevEditKeyDown`, `JogiAdatKimasolo`, `JogiAdatBemasolo`, `JogiListaRacsKeyUp`, `JogiListaRacsCellClick`

## Érintett adatbázis-táblák
`JOGI`, `JOGISZEMELY`, `LASTNUMS`, `UGYFELEK`

**SQL-műveletek (minta):**
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
- `INSERT INTO JOGISZEMELY (JOGISZEMELYNEV,TELEPHELYCIM,`
- `SELECT * FROM JOGISZEMELY ORDER BY JOGISZEMELYNEV`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS LETILTOTT TERMÉSZETES SZEMÉLY
- NINCS LETILTOTT JOGI SZEMÉLY
- A választott személy már le van tiltva !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
