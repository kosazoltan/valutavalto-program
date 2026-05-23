# Legacy modul (SZERVER): TRANZAKC

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/tranzakc/debug/unit3.pas` (50853 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/tranzakc/debug/tdij.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TTRANZDIJ`, `TMNBARFOLYAM`, `Thovalasztoform`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · TRANZDIJ · A TRANZAKCI · dekanySoft · EGY H · EGY NAP BEDOLGOZ · MNB  · VISSZA · ADATOK KIMUTAT · <<     el · 2013 szeptember 30 · Az adatgy · VAGY. · ADATAIT MUTASSAM KI · EGY NAP · 3 M FELETT · NAGYV · ELAD · 3M FELETT · NAGYELAD · KONVER · NAGYKONV · TRANZ.D

## Eljárások / függvények (.pas)
`VISSZAGOMBClick`, `OLDALVALTOGOMBClick`, `FormActivate`, `OldalDisplay`, `DatumDisplay`, `TablaTorles`, `ElszamAdatokBetoltese`, `Elszamadatokfelirasa`, `SetSorOszlop`, `Adatbeiras`, `CaptiontoTomb`, `GetTablaAdat`, `HunstrtoDate`, `Nulele`, `a1Click`, `ARFEDITEnter`, `ARFEDITExit`, `ElszamParancs`, `ARFEDITKeyDown`, `HIDEEDITKeyDown`, `FELGOMBClick`, `LEGOMBClick`, `N1Click`, `TMNBARFOLYAM.FormActivate`, `TMNBarfolyam.DatumDisplay`, `TMNBArfolyam.Tablatorles`, `TMNBARFOLYAM.OldalValtoGombClick`, `TMNBArfolyam.Nulele`, `TMNBArfolyam.OldalDisplay`, `TMNBARFOLYAM.a1Click`

## Érintett adatbázis-táblák
_(nincs explicit SQL-tábla)_

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `DELETE FROM`
- `INSERT INTO`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
