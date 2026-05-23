# Legacy modul (ÉRTÉKTÁR): RATECTRL **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/ratectrl/debug/unit2.pas` (25865 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/ratectrl/makedll/ratectrl.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`ratecontrolrutin`

## DFM form(ok) / képernyő
`TForm1`, `TPERMITCTRL`

**Feliratok/gombok (Caption):** Form1 · BitBtn1 · BitBtn2 · PERMITCTRL · KEDVEZM · BIZONYLAT D · BIZONYLATSZ · DNEM · VALUTA MENNYIS · ENGED · KIADOTT BIZONYLAT · NINCS ENGED · MINDEN BIZONYLAT · NEM ENGED · VISSZA A F · MELYIK H · KONTROL · KIL · ADATOK

## Eljárások / függvények (.pas)
`FormActivate`, `AlapadatBeolvasas`, `Startgombclick`, `IrodaBeolvasas`, `DataParancs`, `FDBControl`, `MakeFdb`, `MakeTabla`, `Combotolto`, `GetHaviPenztarAdat`, `GetEngedelyAdat`, `Nulele`, `KILEPOTimer`, `Scanetar`, `QUITGOMBClick`, `Getengedonev`, `HONAPCOMBOChange`, `ENGEDELYRACSKeyUp`, `ENGEDELYRACSDblClick`, `ENGEDELYRACSCellClick`, `StatusKontrol`, `BitBtn1Click`, `NOPERMITGOMBClick`, `TPERMITCTRL.FormActivate`, `TPermitCtrl.AlapadatBeolvasas`, `TPERMITCTRL.Startgombclick`, `TPERMITCTRL.Nulele`, `TPERMITCTRL.DataParancs`, `TPERMITCTRL.MakeTabla`, `TPERMITCTRL.MakeFdb`

## Érintett adatbázis-táblák
`ENGEDELY`, `HARDWARE`, `IRODAK`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM ENGEDELY`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM IRODAK`
- `WHERE (ERTEKTAR=`
- `DELETE FROM ENGEDELY`
- `SELECT * FROM`
- `WHERE ENGEDMENYTIPUS>7`
- `INSERT INTO ENGEDELY (BIZONYLATSZAM,PDATUM,PDNEM,`
- `WHERE (ENGEDELYTIPUS=`
- `UPDATE ENGEDELY SET EDATUM=`
- `WHERE STATUS=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- EZ AZ IRODA NEM ÉRTÉKTÁR !
- A KÉRT HÓNAP A JÖVŐBEN LESZ

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
