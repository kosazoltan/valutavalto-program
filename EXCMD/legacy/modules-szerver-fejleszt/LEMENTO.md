# Legacy modul (SZERVER-FEJLESZT): LEMENTO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/lemento/unit1.pas` (29985 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/lemento/lemento.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TGYUJTESDISPLAY`

**Feliratok/gombok (Caption):** FORGALMI ADATOK LEMENT · ADATOK ELMENT · (dekanySoft) · Verzi · -T · -IG · ID · BLOKKADATOK LEGY · 2007 · SZEPTEMBER · ADATOK MEGTEKINT · KIL · PENZTARPANEL · GYUJTESDISPLAY · 2007.12.31 · 2008.03.05 · BLOKK · VALUTA · VISSZA A MEN · KECSKEM

## Eljárások / függvények (.pas)
`TOLEVKOMBOChange`, `TOLNAPKOMBOChange`, `IgevKomboChange`, `PenztartValasztott`, `IDOSZAKOKEGOMBClick`, `Nulele`, `EgyHonapIro`, `DBFZarasok`, `EgyteteltListaz`, `Trinul`, `FtForm`, `KedvezmenySeek`, `Elokieg`, `ArfKepzo`, `Nullaz`, `LementoParancs`, `CreateLementoFdb`, `CreateListaTabla`, `CANCELGOMBClick`, `FormClose`, `Space`, `DISPLAYGOMBClick`, `KILEPOGOMBClick`, `SAVEGOMBClick`, `VesszobolPont`, `ESCAPEGOMBClick`, `FormActivate`, `KILEPOTimer`, `penztarcomboDblClick`, `penztarcomboKeyDown`

## Érintett adatbázis-táblák
`ARFE`, `IRODAK`, `LISTA`

**SQL-műveletek (minta):**
- `DELETE FROM LISTA`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE (FEJ.DATUM BETWEEN`
- `INSERT INTO LISTA (DATUM,IDO,BIZONYLATSZAM,BANKJEGY,FORINTERTEK,`
- `SELECT * FROM ARFE`
- `WHERE (BIZONYLATSZAM=`
- `SELECT * FROM LISTA`
- `SELECT * FROM IRODAK`
- `WHERE FEJ.DATUM=`
- `WHERE FEJ.DATUM BETWEEN`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KEZDŐ DÁTUM NAGYOBB A VÉGSŐ DÁTUMNÁL
- NEM TUDOM ELÉRNI A SZERVERT !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
