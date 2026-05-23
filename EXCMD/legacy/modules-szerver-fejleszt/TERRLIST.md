# Legacy modul (SZERVER-FEJLESZT mély): TERRLIST

> Forrás (primer): `Anti/VALUTA/DLL/TERROR/DEBUG/Unit2.pas` (7902 karakter) · library: `Anti/VALUTA/DLL/TERROR/MAKEDLL/terrlist.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`terrorcontrol`

## Eljárások / függvények
`FormActivate`, `KilepoTimer`, `Regisztracio`, `EngedelyGombClick`, `StopGombClick`, `EngedelyezoGombClick`, `EngedelyezoEditKeyDown`, `BetuKiemelo`, `logirorutin`, `supervisorjelszo`, `TTERROR.FormActivate`, `TTERROR.ENGEDELYGOMBClick`, `TTERROR.STOPGOMBClick`, `TTerror.Betukiemelo`, `TTerror.Regisztracio`, `TTERROR.ENGEDELYEZOGOMBClick`, `TTERROR.ENGEDELYEZOEDITKeyDown`, `TTerror.KilepoTimer`

## DFM Caption-ök
Form1 · KERESETT N · KIL · TERROR · AZ   · SZEREPEL AZ ENSZ · TERRORLIST · ENGED · TERRORLITSA ELLEN · Tranzakci

## Adatbázis-táblák
`HARDWARE`, `JOURNAL`, `PENZTAR`, `UNOLIST`, `VTEMP`

- `SELECT * FROM VTEMP`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM UNOLIST WHERE TERROR_NAME LIKE`
- `INSERT INTO JOURNAL (DATUM,IDO,PENZTARKOD,PENZTARNEV,UGYFELNEV,`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
