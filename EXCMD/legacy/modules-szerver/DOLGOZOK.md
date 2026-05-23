# Legacy modul (SZERVER): DOLGOZOK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/dolgozok/debug/unit2.pas` (19656 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/dolgozok/makedll/dolgozok.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`dolgozokarbantarto`

## DFM form(ok) / képernyő
`TForm1`, `TPROSTMK`

**Feliratok/gombok (Caption):** Form1 · START · KIL · PROSTMK · A DOLGOZ · ID-K · SORSZ · UTOLS · NYIREGYH · 50099 · NAGYHEGYIN · 1234 · 223 · DOLGOZ · EGY  · Az  · Panel3 · ADATOK R · NEM R · Biztosan t · a ny · Igen, t · Ne t · Az adatok kiment · BIZTOSAN T

## Eljárások / függvények (.pas)
`AdatKimentes`, `DelMegsemGombClick`, `FormActivate`, `ProsParancs`, `ProsRacsCellClick`, `ProsRacsKeyUp`, `KilepoGombClick`, `KorzetComboChange`, `ModMegsemGombClick`, `ModOkeGombClick`, `ModositoGombClick`, `NevEditEnter`, `NevEditExit`, `NevEditKeyDown`, `PenztarosChange`, `RacsNyitas`, `UjNemokeGombClick`, `UjOkeGombClick`, `UjPenztarosGombClick`, `KileptetoGombClick`, `NoSureKilepGombClick`, `SureKilepGombClick`, `RenameEditKeyDown`, `GetkorzetIndex`, `IdControl`, `TPROSTMK.FormActivate`, `TProstmk.RacsNyitas`, `TProstmk.PenztarosChange`, `TProsTmk.UjPenztarosGombClick`, `TProsTMK.NevEditKeyDown`

## Érintett adatbázis-táblák
`PENZTAROSOK`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAROSOK`
- `WHERE KORZETSZAM=`
- `INSERT INTO PENZTAROSOK (IDKOD,PENZTAROSNEV,`
- `DELETE FROM PENZTAROSOK WHERE SORSZAM=`
- `WHERE IDKOD=`
- `UPDATE PENZTAROSOK SET PENZTAROSNEV=`
- `WHERE SORSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- ILYEN SZÁMÚ ID-KÓD MÁR LÉTEZIK !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
