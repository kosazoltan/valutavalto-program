# Legacy modul (SZERVER): UNPACKER

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/unpacker/debug/unit2.pas` (26701 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/unpacker/makedll/unpacker.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`unpackerrutin`

## DFM form(ok) / képernyő
`TForm1`, `TUNPACKER`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · UNPACKER

## Eljárások / függvények (.pas)
`FormActivate`, `CsomagParaBeolvasas`, `FoglaloDekodolas`, `HaviDekodolas`, `JogiBedolgozas`, `KilepoTimer`, `ReceptParaBeolvasas`, `TablaKontrol`, `TempParancs`, `UgyfelBedolgozas`, `Vparancs`, `Angolra`, `DekodDatum`, `DekodPenztar`, `GetPenztarNev`, `HutoGb`, `Nulele`, `Tomorit`, `Ujtablafeldolgozas`, `DataToVFDB`, `TUNPACKER.FormActivate`, `TUNPACKER.UjTablaFeldolgozas`, `TUNPACKER.FoglaloDekodolas`, `TUNPACKER.HaviDekodolas`, `TUNPACKER.Vparancs`, `TUNPACKER.KilepoTimer`, `TUNPACKER.GetPenztarNev`, `TUNPACKER.DekodDatum`, `TUNPACKER.DekodPenztar`, `TUNPACKER.Nulele`

## Érintett adatbázis-táblák
`FOGLALO`, `MEZOADATOK`, `TABLANEVEK`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM FOGLALO`
- `WHERE DATUM=`
- `INSERT INTO`
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (FDBPATH,TABLASORSZAM,TABLANEV,DATUM)`
- `DELETE FROM`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM MEZOADATOK`
- `SELECT * FROM TABLANEVEK`
- `SELECT * FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
