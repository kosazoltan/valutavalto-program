# Legacy modul (VALUTA): ARFDISP

> Forrás (primer): `Anti/SZERVER/_extracted/VALUTA/DLL/ARFDISP/DEBUG/Unit2.pas` (42500 karakter)
> KORREKCIÓ: a Anti/VALUTA/DLL-ben 0-bájtos stub volt; a VALÓDI forrás az _extracted/VALUTA/DLL-ben.

## Exportált API
`arfolyamkijelzes`

## Eljárások / függvények
`FormActivate`, `Adatbeolvasas`, `Limformat`, `RealToStr`, `VesszobolPont`, `ScanDnem`, `ScanLive`, `NyujtoTimer`, `AdatNullazas`, `Becuppanas`, `OkeGombClick`, `Nulele`, `GetTablasoroszlop`, `shkcuppanas`, `TombokbeToltes`, `PanelFeltoltes`, `CellaRegeneracio`, `GetCellaColor`, `Realform`, `Arfformat`, `Nyujto2Timer`, `SHKOkeGombClick`, `UjarfEditKeyDown`, `ESCAPEGOMBClick`, `VK2MouseMove`, `SP1MouseMove`, `VK2MouseDown`, `VX2MouseMove`, `VX2MouseDown`, `arfolyamkijelzes`, `Tarfolyamtablakijelzes.FormActivate`, `TArfolyamTablaKijelzes.Adatbeolvasas`, `TarfolyamtablaKijelzes.Arfformat`, `TarfolyamTablaKijelzes.Limformat`, `Tarfolyamtablakijelzes.ARFOLYAMRACSSelectCell`, `TarfolyamTablaKijelzes.ScanDnem`, `TarfolyamTablaKijelzes.ScanLive`, `Tarfolyamtablakijelzes.NYUJTOTimer`, `Tarfolyamtablakijelzes.OKEGOMBClick`, `TArfolyamTablaKijelzes.Realform`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `VTEMP`

- `SELECT * FROM HARDWARE`
- `SELECT* FROM ARFOLYAM`
- `WHERE VALUTANEM<>`
- `SELECT * FROM VTEMP`
- `WHERE BANKJEGY>0`
- `UPDATE VTEMP SET ARFOLYAM=`
- `WHERE VALUTANEM=`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
