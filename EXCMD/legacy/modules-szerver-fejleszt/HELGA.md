# Legacy modul (SZERVER-FEJLESZT): HELGA

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/helga/dllek/tranzdij/debug/unit3.pas` (50455 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/helga/dllek/arftmk/makedll/arftmk.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`arfolyamkarbantarto`

## DFM form(ok) / képernyő
`TForm1`, `TARFOLYAMTMK`, `TATTEKINTES`, `TPROSTMK`, `TMAKEIMPORT`, `TForm2`, `TMNBLISTAK`, `TTRANZDIJ`, `TMNBARFOLYAM`, `Thovalasztoform`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · ARFOLYAMTMK · VISSZA · VNEM · VALUTA NEVE · ELSZ-I  · ATTEKINTES · BE · START · KIL · PROSTMK · A DOLGOZ · ADATM · EGY  · Az  · Panel3 · ADATOK R · NEM R · Biztosan t · a ny · Igen, t · Ne t · A dolgoz

## Eljárások / függvények (.pas)
`VISSZAGOMBClick`, `OLDALVALTOGOMBClick`, `FormActivate`, `OldalDisplay`, `DatumDisplay`, `TablaTorles`, `ElszamAdatokBetoltese`, `Elszamadatokfelirasa`, `SetSorOszlop`, `Adatbeiras`, `CaptiontoTomb`, `GetTablaAdat`, `Nulele`, `a1Click`, `ARFEDITEnter`, `ARFEDITExit`, `ElszamParancs`, `ARFEDITKeyDown`, `HIDEEDITKeyDown`, `FELGOMBClick`, `LEGOMBClick`, `N1Click`, `TMNBARFOLYAM.FormActivate`, `TMNBarfolyam.DatumDisplay`, `TMNBArfolyam.Tablatorles`, `TMNBARFOLYAM.OldalValtoGombClick`, `TMNBArfolyam.Nulele`, `TMNBArfolyam.OldalDisplay`, `TMNBARFOLYAM.a1Click`, `TMNBARFOLYAM.ARFEDITEnter`

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
