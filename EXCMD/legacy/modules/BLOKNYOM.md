# Legacy modul: BLOKNYOM

> Forrás (primer): `Anti/VALUTA/DLL/BLOKNYOM/MAKEDLL/Unit2.pas` (56515 karakter) · library: `DLL/BLOKNYOM/MAKEDLL/Bloknyom.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`blokknyomtatas`

## DFM form(ok) / képernyő
`TBLOKKNYOM`

**Feliratok/gombok (Caption):** BLOKKNYOM · Nyomtat

## Eljárások / függvények (.pas)
`FormActivate`, `Nullazo`, `GetVtempBasic`, `GetPartnerPara`, `GetPenztarData`, `NaturadatokBeolvasasa`, `JogiAdatokBeolvasasa`, `CimletNyomtatas`, `VetelSzamlaNyomtatas`, `EladasSzamlaNyomtatas`, `AtadBlokkNyomtatas`, `AtveszBlokkNyomtatas`, `StornoBlokknyomtatas`, `ArfModNyomtatas`, `ReklamNyomtatas`, `Ugyfelnyomtatas`, `SajatNyil`, `Jogcimnyilatkozat`, `DevizsStatuszNyomtatas`, `KozszerepNyilatkozat`, `BlokkFocimIro`, `BlokkFejlecIro`, `BlokkTetelIro`, `VonalHuzo`, `KozepreIr`, `TextKiiro`, `KilepotimerTimer`, `Soremeles`, `OroszNyilatkozat`, `StartNyomtatas`

## Érintett adatbázis-táblák
`HARDWARE`, `JOGISZEMELY`, `PENZTAR`, `UGYFEL`, `UJTULAJOK`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM UGYFEL WHERE UGYFELSZAM=`
- `SELECT * FROM JOGISZEMELY WHERE UGYFELSZAM=`
- `SELECT * FROM UJTULAJOK WHERE UGYFELSZAM=`
- `WHERE (BANKJEGY>0)`
- `WHERE KEDVEZMENYESARFOLYAM>0`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
