# Legacy modul (SZERVER): DATADISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/datadisp/debug/unit2.pas` (11039 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/datadisp/makedll/datadisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`datadisplay`

## DFM form(ok) / képernyő
`TForm1`, `TMNBDISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · MNBDISPLAY · Button1 · DNEM · ST · NYIT · ELAD · BANK + · BANK - · PT · HI · SZ · VISSZA+ · VISSZA- · KIL

## Eljárások / függvények (.pas)
`Button1Click`, `KILEPESGOMBClick`, `FormActivate`, `KILEPOTimer`, `IdoszakDisplay`, `FejlecDisplay`, `KFTDisplay`, `IrodaBetoltes`, `ScanKorzet`, `MASEGYSEGGOMBClick`, `BitBtn2Click`, `TMNBDISPLAY.FormActivate`, `TMNBDisplay.IdoszakDisplay`, `TMNBDISPLAY.Button1Click`, `TMNBDISPLAY.KILEPESGOMBClick`, `TMNBDISPLAY.KILEPOTimer`, `TMNBDisplay.FejlecDisplay`, `TMNBDisplay.ScanKorzet`, `TMNBDisplay.KftDisplay`, `TMNBDisplay.Irodabetoltes`, `TMNBDISPLAY.MasEgysegGombClick`, `TMNBDISPLAY.BitBtn2Click`

## Érintett adatbázis-táblák
`ADATATADO`, `IDOSZAK`, `IRODAK`, `MNB`

**SQL-műveletek (minta):**
- `SELECT * FROM MNB`
- `WHERE`
- `SELECT * FROM ADATATADO`
- `SELECT * FROM IDOSZAK`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
