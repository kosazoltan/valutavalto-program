# Legacy modul: QRGENER

> Forrás (primer): `Anti/VALUTA/DLL/QRGENER/MAKEDLL/Unit2.pas` (20894 karakter) · library: `DLL/QRGENER/MAKEDLL/QRGENER.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`qrdisplayrutin`

## DFM form(ok) / képernyő
`TForm2`, `TForm1`

**Feliratok/gombok (Caption):** Form1 · Exclusive · Change · Kft. · TOV · OLVASSA BE · A MINDJ · QR-K · A SZ · SK · KIL

## Eljárások / függvények (.pas)
`Day_open_3`, `Clear_All_currencies`, `Install_currencies`, `Day_close`, `Day_open`, `Pay_in`, `Pay_out`, `Buying`, `Selling`, `Cancellation`, `FormDestroy`, `KijelzoPaint`, `MeretChange`, `FormCreate`, `QrParamBeolvasas`, `TOVABBGOMBClick`, `FormActivate`, `MasodikLepcso`, `HarmadikLepcso`, `Scandnem`, `Nulele`, `Konvdnem`, `Arfform`, `NEXTGOMBClick`, `Konv`, `Commless`, `Frissit`, `TForm2.FormCreate`, `TForm2.FormActivate`, `TForm2.MeretChange`

## Érintett adatbázis-táblák
`ARFOLYAM`, `PENZTAR`, `QRPARAMS`

**SQL-műveletek (minta):**
- `SELECT * FROM ARFOLYAM`
- `SELECT * FROM QRPARAMS`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM ARFOLYAM WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
