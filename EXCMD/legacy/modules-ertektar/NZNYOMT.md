# Legacy modul (ÉRTÉKTÁR): NZNYOMT

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/nznyomt/debug/unit2.pas` (30445 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/nznyomt/makedll/nznyomt.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napzarnyomtatorutin`

## DFM form(ok) / képernyő
`TForm1`, `TNAPZARNYOMTATOFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · NAPZARNYOMTATOFORM · NAPI Z

## Eljárások / függvények (.pas)
`AtadAtvetGyujtes`, `AtadatvetLista`, `ForgalomLista`, `WuAfaNyomtatas`, `EkerNyomtatas`, `KunaNyomtatas`, `Naplobair`, `Hrkregeneralo`, `HrkParancs`, `NaploParancs`, `BlokkFocimIro`, `EllenorBejegyzes`, `FormActivate`, `IdozitoTimer`, `Kezelesidijnyomtatas`, `KozepreIr`, `PenztarAllas`, `StartNyomtatas`, `VonalHuzo`, `ZaroKeszletBeolvasas`, `Elokieg`, `ForintForm`, `FormKiir`, `Scandnem`, `TNAPZARNYOMTATOFORM.FormActivate`, `TNAPZARNYOMTATOFORM.IDOZITOTimer`, `TNapzarNyomtatoForm.BlokkFocimIro`, `TNapZArNyomtatoForm.PenztarAllas`, `TNapzarNyomtatoForm.Kezelesidijnyomtatas`, `TNapzarNyomtatoForm.Ekernyomtatas`

## Érintett adatbázis-táblák
`HARDWARE`, `HRKDATA`, `HRKNAPLO`, `HRKSZAMLAK`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM`
- `WHERE DATUM=`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1) AND (FEJ.DATUM=`
- `SELECT * FROM HRKNAPLO`
- `DELETE FROM HRKNAPLO`
- `SELECT * FROM HRKSZAMLAK`
- `WHERE STORNO=1`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
