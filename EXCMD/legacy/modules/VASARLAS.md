# Legacy modul: VASARLAS

> Forrás (primer): `Anti/VALUTA/DLL/VASARLAS/MAKEDLL/Unit2.pas` (101099 karakter) · library: `DLL/VASARLAS/MAKEDLL/Vasarlas.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`vasarlasrutin`

## DFM form(ok) / képernyő
`TVASARLASFORM`

**Feliratok/gombok (Caption):** eur · End · Escape · SAJ · ENGEDM · Nett · Kezel · DNEM · VALUTA MEGNEVEZ · BANKJEGY · FIZETEND · Vissza a f · BLOKKSZ · Konverzi · VALUTA(K) · Kerek · NINCS INTERNET · BIZTOSAN ELDOBJA EZT A V · IGEN · NEM · AZ  · JUTAL

## Eljárások / függvények (.pas)
`AdatBevitelkesz`, `AlapadatBeolvasas`, `ArfelterWrite`, `ArfolyamGombClick`, `ArfolyamotModosit`, `ArfolyamKeyDown`, `BankjegyKeyDown`, `Bizregiszter`, `BlokkFejIro`, `BlokktetelIro`, `DnemKeyDown`, `EngedelyezoKijeloles`, `EnggombClear`, `EscapeGombClick`, `EurErmeKonvertalas`, `ETGOMBMouseMove`, `ENGSHAPEMouseMove`, `ETGOMBClick`, `KezdijEngedmenyGombClick`, `Figyelmeztetes`, `FizetendoDisplay`, `Folytatas`, `FormActivate`, `FormCreate`, `IgenKilepGombClick`, `KezdijBeepites`, `KezdijRogzito`, `KezdijTablaBeolvasas`, `Kilepniakar`, `KilepTimer`

## Érintett adatbázis-táblák
`ARFOLYAM`, `ARFOLYAMELTERITES`, `BLOKKFEJ`, `BLOKKTETEL`, `EGYENIKEZDIJ`, `HARDWARE`, `JOGI`, `JOGIBIZ`, `KEZELESIDATA`, `MEDIA`, `PENZTAR`, `QRPARAMS`, `TRANZDIJTABLA`, `UGYFEL`, `UTOLSOBLOKKOK`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `UPDATE VTEMP SET MEGJEGYZES=`
- `WHERE VALUTANEM=`
- `SELECT * FROM VTEMP`
- `UPDATE VTEMP SET FORINTERTEK=`
- `UPDATE VTEMP SET NETTO=`
- `WHERE BANKJEGY=0`
- `UPDATE HARDWARE SET SAJATHATASKORU=`
- `UPDATE VTEMP SET RATETYPE=`
- `UPDATE HARDWARE SET NAPIEGYEDIKEZDIJ=`
- `INSERT INTO ARFOLYAMELTERITES (DATUM,PENZTAROSNEV,`
- `SELECT * FROM KEZELESIDATA`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A FORINT NEM VÁLASZTHATÓ VALUTA
- Nincs ilyen valutanem
- AZ ÁRFOLYAM MÁR MÓDOSÍTVA VAN !
- EZ MÁR KEDVEZMÉNYES ÁRFOLYAM
- Ez már módositott árfolyam !
- KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !
- NINCS ENNYI FORINT KÉSZLETÜNK !
- NINCS ENNYI FORINTUNK KÉSZLETEN !
- AZ E-MAILEKET SIKERESEN ELKÜLDTEM
- ILYEN VALUTA MÁR VAN
- EURO BANKJEGYET ÉS ÉRMÉT KÜLÖN BIZONYLATON KELL KIADNI

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
