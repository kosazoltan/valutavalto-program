# Legacy modul (SZERVER-FEJLESZT): PERSONAL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/personal/kereso/unit1.pas` (52421 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/personal/kereso/kereso.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · A keres · A TELJES ADATB · CSAK EGY KFT-BEN · CSAK EGY K · CSAK EGYTELEN P · NEM KERESS · Exclusive Pannon Change · Exclusive East Change · Exclusive Best Change · KERES · KIL · SZEKSZ · SZEGED · KECSKEM · DEBRECEN · NY · KAPOSV · MESSPANEL · ID · PTSZ · BIZONYLAT · VNEM · FORINT · EXCEL T

## Eljárások / függvények (.pas)
`NEVKEZDETGOMBClick`, `IrodaBeolvasas`, `Tol_Ig_beallito`, `UgyfeletValasztott`, `GetPenztarNev`, `TalalatDisplay`, `neveditKeyDown`, `NevEloOkeGombClick`, `GetkorzetNev`, `IrodatValasztott`, `FindParancs`, `FormActivate`, `evelomegsemgombClick`, `NOCONDIGOMBClick`, `VANCONDIGOMBClick`, `KEZDETEGOMBClick`, `TARTALMAZZAGOMBClick`, `nexteditKeyDown`, `ESOKEGOMBClick`, `fieldcomboChange`, `neveditEnter`, `neveditExit`, `BitBtn3Click`, `TOROKEGOMBClick`, `NEVTOREDITKeyDown`, `BitBtn4Click`, `KERMEZOOKEGOMBClick`, `kerkezdgombClick`, `KERTTARTGOMBClick`, `KERDATAEDITKeyDown`

## Érintett adatbázis-táblák
`BIZONYLATOK`, `IRODAK`, `VALOGATAS`

**SQL-műveletek (minta):**
- `SELECT * FROM VALOGATAS`
- `SELECT * FROM IRODAK`
- `WHERE CLOSED=`
- `DELETE FROM VALOGATAS`
- `SELECT * FROM`
- `WHERE`
- `INSERT INTO VALOGATAS (UGYFELSZAM,NEV,ELOZONEV,ANYJANEVE,`
- `DELETE FROM BIZONYLATOK`
- `WHERE (UGYFELSZAM=`
- `WHERE BIZONYLATSZAM=`
- `INSERT INTO BIZONYLATOK (DATUM,IDO,BIZONYLATSZAM,TIPUS,PENZTARNEV,`
- `SELECT * FROM BIZONYLATOK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TALÁLTAM ÜGYFELET A MEGADOTT ADATOK FIGYELEMBEVÉTELÉVEL !
- Érvénytelen időintervallum !
- NEM TALÁLOM 
- NEM TALÁLTAM BIZONYLATOT A KÉRT IDŐINTERVALLUMBAN

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
