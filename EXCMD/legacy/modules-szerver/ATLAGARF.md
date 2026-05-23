# Legacy modul (SZERVER): ATLAGARF

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/atlagarf/debug/unit2.pas` (44322 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/atlagarf/makedll/atlagarf.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`atlagarfolyamrutin`

## DFM form(ok) / képernyő
`TForm1`, `TATLAGARFOLYAM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Panel1 · ATLAGARFOLYAM · EGYS · ELAD · VALUTA NEMEK · AMERIKAI DOLL · VISSZA A F · EXCEL K

## Eljárások / függvények (.pas)
`FormActivate`, `AtlagLegyujtes`, `AtlagRacsEnter`, `AtlagRacsExit`, `AtlagSzamitas`, `AtlagDisplay`, `ExceladatokBeirasa`, `IkonKirako`, `KilepoTimer`, `KillExcel`, `LivePenztarBeolvasas`, `PenztarBeolvasas`, `ValutaBoxEnter`, `ValutaBoxExit`, `ValutaBoxtolto`, `ValutaBoxMouseDown`, `ValutaBoxKeyUp`, `ValutaValtozott`, `AtlagParancs`, `AtlagRogzito`, `MakeFejlec`, `MakeFrames`, `Oszlopszelesseg`, `Vekony`, `Vastag`, `ErtTarScan`, `DnemScan`, `VesszobolPont`, `FtForm`, `BitBtn1Click`

## Érintett adatbázis-táblák
`ATLAGARFOLYAM`, `IDOSZAK`, `IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IDOSZAK`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE (FEJ.DATUM=`
- `WHERE (FEJ.DATUM BETWEEN`
- `DELETE FROM ATLAGARFOLYAM`
- `INSERT INTO ATLAGARFOLYAM (IRODA,ERTEKTAR,MEGNEVEZES,`
- `SELECT * FROM`
- `SELECT * FROM IRODAK ORDER BY UZLET`
- `SELECT * FROM ATLAGARFOLYAM`
- `WHERE (IRODA=0) AND (ERTEKTAR>0)`
- `WHERE (IRODA=0) AND (ERTEKTAR=0)`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM VOLT AZ IDÖSZAK ALATT FORGALOM

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
