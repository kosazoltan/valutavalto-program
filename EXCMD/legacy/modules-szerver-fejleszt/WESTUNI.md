# Legacy modul (SZERVER-FEJLESZT): WESTUNI

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/westuni/unit1.pas` (29742 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/westuni/westuni.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** WESTERN UNION FORGALOM LEV · WESTERN UNION ADATOK LEGY · -T · -IG · ID · KIL · EXCEL T · A WESTERN UNION FORGALOM LEV · EGY K · EGY P · EGY KFTRE · EXCLUSIVE BEST CHANGE KFT · EXCLUSIVE EAST CHANGE KFT · EXCLUSIVE PANNON CHANGE KFT · EXPRESSZ  · VISSZAL · EXCELT · SZEKSZ · SZEGEDI K · KECSKEM · DEBRECENI K · NYIREGYH · KAPOSV · EXPRESSZ H · VISSZA A F

## Eljárások / függvények (.pas)
`QUITGOMBClick`, `FormActivate`, `UjidoszakBeallitas`, `Nulele`, `Scankorzet`, `GetPenztarnev`, `ExcGombClick`, `EVCOMBOChange`, `TOLCOMBOChange`, `IGCOMBOChange`, `Getirodak`, `IDSZOKEGOMBClick`, `LevalogatoRutin`, `MakeExcel`, `ExcelKill`, `PtValasztott`, `ZPtValasztott`, `KftValasztott`, `PENZTARGOMBClick`, `KorzetetValasztott`, `CHANGEBOXDblClick`, `CHANGEBOXKeyUp`, `EXPBOXDblClick`, `EXPBOXKeyUp`, `EXPGOMBClick`, `KFTGOMBClick`, `BACKKFTGOMBClick`, `backptvalgombClick`, `KORZETGOMBClick`, `BACKKORZETGOMBClick`

## Érintett adatbázis-táblák
`IRODAK`, `WUGYUJTO`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE WESTERNUNION=1`
- `DELETE FROM WUGYUJTO`
- `SELECT * FROM`
- `WHERE (DATUM>=`
- `INSERT INTO WUGYUJTO (CEG,KORZET,PENZTAR,DATUM,SORSZAM,`
- `SELECT * FROM WUGYUJTO`
- `WHERE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
