# Legacy modul: OTPLOG

> Forrás (primer): `Anti/VALUTA/DLL/OTPLOG/MAKEDLL/Unit2.pas` (4602 karakter) · library: `DLL/OTPLOG/MAKEDLL/otplog.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`otpterminallog`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · OTP TERMIN · El · 2020.12.31 · Ezt a napot k · Vissza a f · VISSZA A NAPT

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `PreHonapClick`, `NextHonapClick`, `NaptarChange`, `Nulele`, `KILEPOTimer`, `NAPTARVISSZAGOMBClick`, `NAPOKEGOMBClick`, `ujnapgombClick`, `TForm2.Button1Click`, `TForm2.FormActivate`, `TForm2.PREHONAPClick`, `TForm2.NEXTHONAPClick`, `TForm2.NAPTARChange`, `TForm2.Nulele`, `TForm2.KILEPOTimer`, `TForm2.NAPTARVISSZAGOMBClick`, `TForm2.NAPOKEGOMBClick`, `TForm2.ujnapgombClick`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
