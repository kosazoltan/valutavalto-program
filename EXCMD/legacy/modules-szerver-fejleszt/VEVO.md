# Legacy modul (SZERVER-FEJLESZT): VEVO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/vevo/unit1.pas` (24369 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/vevo/vevok.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Forgalmi adatok  · Adatok  · KEZD · UTOLS · dekanySoft · SZ · KIL

## Eljárások / függvények (.pas)
`PenztarBeolvasas`, `PenztartValasztott`, `STARTGOMBClick`, `MINFORINTEnter`, `MINFORINTExit`, `ESCAPEGOMBClick`, `DatumDisplay`, `VevoLepteto`, `LFormat`, `TOLNAPTARClick`, `FormActivate`, `Vesszokivono`, `Forintform`, `MINFORINTKeyDown`, `MAXFORINTKeyDown`, `Nulele`, `WideDatum`, `Allgombclear`, `AllgombDisable`, `AllgombEnable`, `FormMouseMove`, `mindengombMouseMove`, `KFTGOMBMouseMove`, `KORZETGOMBMouseMove`, `PENZTARGOMBMouseMove`, `mindengombClick`, `KFTGOMBClick`, `KORZETGOMBClick`, `PENZTARGOMBClick`, `Scanetar`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE (DATUM>=`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KEZDŐ-DÁTUM NAGYOBB AZ UTOLSÓ DÁTUMNÁL !
- A KEZDŐNAP MINIMUMA 2014.01.01 LEHET !
- AZ UTOLSÓ NAP MAXIMUMA A TEGNAPI NAP !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
