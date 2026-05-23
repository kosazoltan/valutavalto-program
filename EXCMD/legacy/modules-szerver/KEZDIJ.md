# Legacy modul (SZERVER): KEZDIJ

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/kezdij/debug/unit2.pas` (27724 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/kezdij/makedll/kezdij.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kezdijosszesito`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · HAVI K

## Eljárások / függvények (.pas)
`KezdijNullazo`, `KezdijKiolvaso`, `KezdijBeiro`, `KezdijExcelbetoltes`, `PenztarSorEpito`, `PenztarParaBeolvasas`, `GetIdoszak`, `KezdParancs`, `FormActivate`, `Keret`, `KilepoTimer`, `FejlecKeszites`, `Makekezdtabla`, `KezdtablaNyitas`, `ezEtar`, `TForm2.FormActivate`, `TForm2.KezdijNullazo`, `TForm2.KezdijKiolvaso`, `TForm2.KezdijBeiro`, `TForm2.PenztarSorEpito`, `TForm2.PenztarParaBeolvasas`, `TForm2.GetIdoszak`, `TForm2.KILEPOTimer`, `TForm2.KezdijExcelbeToltes`, `TForm2.FejlecKeszites`, `TForm2.KezdtablaNyitas`, `TForm2.Keret`, `TForm2.KezdParancs`, `Tform2.Makekezdtabla`, `TForm2.EzEtar`

## Érintett adatbázis-táblák
`IDOSZAK`, `IRODAK`, `KEZD`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE`
- `DELETE FROM`
- `INSERT INTO`
- `SELECT * FROM IRODAK ORDER BY UZLET`
- `SELECT * FROM IDOSZAK`
- `SELECT * FROM KEZD`
- `WHERE CEGBETU=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
