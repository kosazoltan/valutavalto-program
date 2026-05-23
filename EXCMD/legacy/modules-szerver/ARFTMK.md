# Legacy modul (SZERVER): ARFTMK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/arftmk/debug/unit2.pas` (17656 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/arftmk/makedll/arftmk.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`arfolyamkarbantarto`

## DFM form(ok) / képernyő
`TForm1`, `TARFOLYAMTMK`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · ARFOLYAMTMK · VISSZA · Valnem · Valuta neve · Elsz-i  · MNB- · MNB  · AUSZTR

## Eljárások / függvények (.pas)
`DnemKod`, `FormActivate`, `FileBeiro`, `IntegKod`, `VisszaGombClick`, `MNBArfKikuldo`, `OldArfolyamDelete`, `OldArfRemove`, `UjKikuldo`, `Kitkod`, `Nulele`, `ARFOLYAMRACSDblClick`, `ARFOLYAMEDITKeyUp`, `TARFOLYAMTMK.VISSZAGOMBClick`, `TARFOLYAMTMK.FormActivate`, `TARFOLYAMTMK.FileBeiro`, `TARFOLYAMTMK.DnemKod`, `TARFOLYAMTMK.Kitkod`, `TARFOLYAMTMK.IntegKod`, `TARFOLYAMTMK.Nulele`, `TArfolyamTmk.MNBarfKikuldo`, `Tarfolyamtmk.OldArfolyamDelete`, `TARFTMK.BetoltoGombClick`, `TARFTMK.IntegDek`, `TARFTMK.DnemDekod`, `TARFTMK.RealToStr`, `TARFTMK.OldArfolyamDelete`, `TARFOLYAMTMK.ARFOLYAMRACSDblClick`, `TARFOLYAMTMK.ARFOLYAMEDITKeyUp`, `TArfolyamTmk.UjKikuldo`

## Érintett adatbázis-táblák
`ARFOLYAM`

**SQL-műveletek (minta):**
- `UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=`
- `WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCSENEK MAI ÁRFOLYAMOK SEHOL
- NINCSENEK ÁRFOLYAMOK AZ ADATOKBAN
- AZ ELSZÁMOLÓ ÁRFOLYAMOK SIKERESEN BETÖLTÖDTEK

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
