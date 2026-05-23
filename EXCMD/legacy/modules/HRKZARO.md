# Legacy modul: HRKZARO

> Forrás (primer): `Anti/VALUTA/DLL/HRKZARO/MAKEDLL/Unit2.pas` (28133 karakter) · library: `DLL/HRKZARO/MAKEDLL/hrkzaro.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`horvatkunazaro`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · HORV · HRK H · 1.000 · 500 · 200 · 100 · 50 · 20 · 10 · CIMLETEZETT · VISSZA A MEN · CIMLET RENDBEN · ALAPPANEL

## Eljárások / függvények (.pas)
`AlapadatBeolvasas`, `BlokkFejKitoltes`, `BlokkTetelKitoltes`, `Cimletezes`, `CimOkeGombClick`, `CimMegsemGombClick`, `E1KeyDown`, `E1Enter`, `E1Exit`, `EladasQRKodja`, `ForintKivezetes`, `FormActivate`, `HaziPenztarBevetel`, `HrkEladas`, `Hrkparancs`, `KilepoTimer`, `ThFejKitoltes`, `ThtetelKitoltes`, `ThQrKodja`, `ThTempKitoltes`, `Tombbetoltes`, `ValParancs`, `Vegigszamol`, `VTempKitoltes`, `Ftform`, `Nulele`, `blokknyomtatas`, `regeneralorutin`, `TForm2.FormActivate`, `TForm2.AlapadatBeolvasas`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKFEJ`, `BLOKKTETEL`, `CIMINI`, `HARDWARE`, `HRKDATA`, `HRKNAPLO`, `HRKSZAMLAK`, `JOGISZEMELY`, `PENZTAR`, `QRPARAMS`, `UTOLSOBLOKKOK`, `VTEMP`

**SQL-műveletek (minta):**
- `UPDATE CIMINI SET AKTKESZLET=0,CIMLETEZETT=0`
- `WHERE VALUTANEM=`
- `SELECT * FROM JOGISZEMELY WHERE (JOGISZEMELYNEV LIKE`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM UTOLSOBLOKKOK`
- `SELECT * FROM HRKDATA`
- `INSERT INTO HRKSZAMLAK (DATUM,IDO,BIZONYLATSZAM,BEVETEL,STORNO)`
- `UPDATE HRKDATA SET BESORSZAM=`
- `SELECT * FROM HRKNAPLO`
- `SELECT * FROM HRKNAPLO WHERE DATUM=`
- `SELECT * FROM HRKNAPLO ORDER BY DATUM`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
