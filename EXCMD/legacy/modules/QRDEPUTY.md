# Legacy modul: QRDEPUTY

> Forrás (primer): `Anti/VALUTA/DLL/QRDEPUTY/MAKEDLL/Unit2.pas` (24128 karakter) · library: `DLL/QRDEPUTY/MAKEDLL/QRGENER.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`qrdisplayrutin`

## DFM form(ok) / képernyő
`TForm2`, `TForm1`

**Feliratok/gombok (Caption):** Adatk · A TRANZAKCI · A NAV-OS P · TRANZAKCI · VALUTA: · FORINT: · MEHET AZ ADAT · NE  K · OLVASSA BE · A MINDJ · QR-K · PARANCS KIJELZ · KIJ · IGEN RENDBEN · Form1 · A SZ · SK · KIL · TESZT · START · KILEP

## Eljárások / függvények (.pas)
`Clear_All_currencies`, `Install_currencies`, `Day_close`, `Day_open`, `Pay_in`, `Pay_out`, `Buying`, `Selling`, `Cancellation`, `QrParamBeolvasas`, `MEHETGOMBClick`, `FormActivate`, `KilepoTimer`, `ValutaBeolvasas`, `Scandnem`, `Nulele`, `Konvdnem`, `Arfform`, `Konv`, `Commless`, `Ftform`, `MEGSEMGOMBClick`, `DISPLAYGOMBClick`, `UJRAKULDOGOMBClick`, `IGENRENDBENGOMBClick`, `MRGSEMGOMBClick`, `TForm2.FormActivate`, `Tform2.Clear_All_currencies`, `Tform2.Install_currencies`, `Tform2.Day_close`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `PENZTAR`, `QRPARAMS`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM QRPARAMS`
- `SELECT * FROM ARFOLYAM`
- `WHERE NAVSORSZAM>0`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TUDTAM BEÁLLITANI A 

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
