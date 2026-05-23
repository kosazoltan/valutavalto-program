# Legacy modul: OTP

> Forrás (primer): `Anti/VALUTA/DLL/OTP/MAKEDLL/Unit2.pas` (58036 karakter) · library: `DLL/OTP/MAKEDLL/otp.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`otpterminal`

## DFM form(ok) / képernyő
`TOTPTERM`

**Feliratok/gombok (Caption):** OTP Termin · OTP TERMINAL PROGRAM · dekanySoft · A V · Bizonylatsz · Fizetend ·    · KOMMUNIK · Neve: · ID-k · TOV · POS-TERMINAL LEZ · VISSZA · INKABB K · TRANZAKCI · SIKERTELEN · SIKERES BEL · UTOLS · BIZONYLAT SZ · BIZONYLAT  · SIKERTELEN  · BIZONYLAT SIKERESEN  · (az  · SIKERES · SIKERTELEN ARUVISSZAV

## Eljárások / függvények (.pas)
`AdatBeolvasas`, `AruvisszaCancel`, `AruvisszaCancelGombClick`, `Aruvisszavet`, `AruvisszaOkeGombClick`, `CashGombClick`, `ClCancelGombClick`, `CloseCancel`, `CloseOkeGombClick`, `ComCtrl`, `FormActivate`, `FunkcioValasztas`, `IdTCPClient1Connected`, `IdTCPClient1Disconnected`, `KilepoTimer`, `Logwrite`, `Memoiro`, `Paraletoltes`, `PenztarosBelep`, `PenztarosKilepAndClose`, `PBCancelGombClick`, `PBOkeGombClick`, `PkCancelGombClick`, `PkOkeGombClick`, `PLCancelGombClick`, `PLoadCancel`, `PLOkeGombClick`, `ProsBelepCancel`, `ProskiCancel`, `ReprintRutin`

## Érintett adatbázis-táblák
`HARDWARE`, `POS`, `VTEMP`

**SQL-műveletek (minta):**
- `FROM POS:`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM VTEMP`
- `UPDATE VTEMP SET FMEZO=`
- `FROM POS:CONNECTED`
- `FROM POS:DISCONNECTED`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nincs kifizetendő összeg
- Nincs bizonylatszám !
- Nincs átutalandó összeg

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
