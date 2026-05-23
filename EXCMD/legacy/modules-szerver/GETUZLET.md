# Legacy modul (SZERVER): GETUZLET

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/getuzlet/debug/unit2.pas` (15387 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/getuzlet/makedll/getegyseg.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getegysegkod`

## DFM form(ok) / képernyő
`TForm1`, `TGETUZLETSZAM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Panel1 · LISTA V · EXCLUSIVE BEST CHANGE  · EXPRESSZ 

## Eljárások / függvények (.pas)
`FormActivate`, `IrodaBetolto`, `ChangeKftGombClick`, `ErtektarakGombClick`, `PenztarakGombClick`, `ParaParancs`, `SetFilter`, `ParaFeliro`, `ErtektarListKeyDown`, `ErtekTartValasztott`, `PenztarListKeyDown`, `PenztartValasztott`, `ChangeKftGombEnter`, `ChangeKftGombExit`, `ChangeKftGombMouseMove`, `ValasztoGombEnter`, `ValasztoGombExit`, `MegsemGombClick`, `ZalogGombClick`, `Kibovit`, `TGetuzletszam.FormActivate`, `TGETUZLETSZAM.CHANGEKFTGOMBClick`, `TGETUZLETSZAM.ERTEKTARAKGOMBClick`, `TGETUZLETSZAM.PenztarakGombClick`, `TGETUZLETSZAM.CHANGEKFTGOMBMouseMove`, `TGETUZLETSZAM.VALASZTOGOMBEnter`, `TGETUZLETSZAM.VALASZTOGOMBExit`, `TGetuzletszam.IrodaBetolto`, `TGETUZLETSZAM.PENZTARLISTKeyDown`, `TGetuzletszam.PenztartValasztott`

## Érintett adatbázis-táblák
`ADATATADO`, `IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `DELETE FROM ADATATADO`
- `INSERT INTO ADATATADO (TIPUS,IRODA,KORZET,CEGBETU,SZURO)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
