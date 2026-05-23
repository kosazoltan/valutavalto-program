# Legacy modul (SZERVER-FEJLESZT): UFILL18

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/ufill18/unit1.pas` (27574 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/ufill18/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · START · KILEP · HONAPPANEL · UGYFELPANEL

## Eljárások / függvények (.pas)
`KILEPOGOMBClick`, `STARTGOMBClick`, `AdatTorles`, `Bemasolas`, `NaturRutin`, `JogiRutin`, `NaturDAtaFromPersbig`, `NaturUgyfelBedolgozas`, `UjNaturUgyfelFelvetele`, `JogiDataFromPersbig`, `FoundJogiClient`, `JogiUgyfelBedolgozas`, `UjJogiUgyfelFelvetele`, `Bizregisztracio`, `Angolra`, `HutoGb`, `Tomorito`, `Uparancs`, `Vparancs`, `Szetszed`, `ezertektar`, `Doublekill`, `Nulele`, `Ezirszam`, `TForm1.STARTGOMBClick`, `TForm1.ADattorles`, `TForm1.Bemasolas`, `TForm1.NaturRutin`, `TForm1.NaturDAtaFromPersbig`, `TForm1.NaturUgyfelBedolgozas`

## Érintett adatbázis-táblák
`JOGI`, `JOGIBIZ`, `LASTNUMS`

**SQL-műveletek (minta):**
- `DELETE FROM`
- `DELETE FROM JOGI`
- `DELETE FROM JOGIBIZ`
- `DELETE FROM LASTNUMS`
- `INSERT INTO LASTNUMS (ALAST,BLAST,CLAST,DLAST,ELAST,FLAST,GLAST,HLAST,`
- `SELECT * FROM`
- `WHERE`
- `WHERE UGYFELSZAM=`
- `WHERE NEV=`
- `WHERE (NEV=`
- `UPDATE`
- `WHERE SORSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
