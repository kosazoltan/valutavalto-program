# Legacy modul: KISARFVALT

> Forrás (primer): `Anti/VALUTA/DLL/KISARFVALT/MAKEDLL/Unit2.pas` (41918 karakter) · library: `DLL/KISARFVALT/MAKEDLL/Kisarfvalt.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kisarfolyamkedvezmeny`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · Nem adok kedvezm · Valuta · nemek · Elad · 50.000 Ft-IG · 50.001 - 300.000 Ft · 300.001 - 1.000.000 Ft · Max v · Min elad-i  · Saj · D1 · N1 · VA1 · EA1 · VK1 · EK1 · VF1 · EF1 · VX1 · EX1 · RENDBEN · EUR · 22,560 · Nincs t

## Eljárások / függvények (.pas)
`FormActivate`, `AdatNullazas`, `ArfolyamBeolvasas`, `BeCuppanas`, `CellaRegeneracio`, `CellaKijeloles`, `CuppOkeGombClick`, `EscapeGombClick`, `GetCellaColor`, `GetTablasoroszlop`, `KilepoTimer`, `KurzorBeallitas`, `NyujtoTimer`, `Nyujto2Timer`, `PanelFeltoltes`, `ShkCuppanas`, `SHKOkeGombClick`, `SP1MouseMove`, `TombokbeToltes`, `UjarfEditKeyDown`, `VK2MouseDown`, `VK2MouseMove`, `Vparancs`, `VX2MouseMove`, `VX2MouseDown`, `Ftform`, `Limformat`, `Nulele`, `ScanDnem`, `TForm2.FormActivate`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `VTEMP`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET ARFOLYAM=`
- `WHERE VALUTANEM=`
- `SELECT * FROM HARDWARE`
- `SELECT* FROM ARFOLYAM`
- `WHERE VALUTANEM<>`
- `SELECT * FROM VTEMP WHERE SORENGEDMENY=0`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Már minden valuta árfolyam kedvezményes

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
