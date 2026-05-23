# Legacy modul: ELADAS

> Forrás (primer): `Anti/VALUTA/DLL/ELADAS/MAKEDLL/Unit2.pas` (132704 karakter) · library: `DLL/ELADAS/MAKEDLL/Eladas.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`eladasrutin`

## DFM form(ok) / képernyő
`TELADASFORM`

**Feliratok/gombok (Caption):** End · Escape · ELAD · Nett · Kezel · VISSZA A F · DNEM · VALUTA MEGNEVEZ · BANKJEGY · FIZETEND · BANK · BLOKKSZ · E123456789 ·                    0 · Konverzi · forint  · forint · RENDBEN · FORINT KERET: · MARADT: · NINCS LIMIT · LIMIT BE · Kerek · NINCS SZERVER · BIZTOSAN ELVETI EZT AZ ELAD

## Eljárások / függvények (.pas)
`AdatbevitelKesz`, `AktualNullazo`, `AlapadatBeolvasas`, `ArfelterWrite`, `ArfolyamGombClick`, `ArfolyamKeyDown`, `ArfolyamotModosit`, `ArfvaltParaWrite`, `BankjegyKeyDown`, `BankKartyaRendezes`, `BankkartyaKonyveles`, `Bizregiszter`, `BlokkFejIro`, `Blokkteteliro`, `DnemKeyDown`, `Dnem2VTemp`, `EditTombTolto`, `EngedelyezoKijeloles`, `EscapeGombClick`, `ETGOMBClick`, `Figyelmeztetes`, `FizetendoDisplay`, `Folytatas`, `FormActivate`, `FormCreate`, `FormKeyDown`, `GetKonvertAdatok`, `GetLimitOsszeg`, `IgenKilepGombClick`, `KedvezmenyAnalizis`

## Érintett adatbázis-táblák
`ADATLAP`, `ARFOLYAM`, `ARFOLYAMELTERITES`, `BLOKKFEJ`, `BLOKKTETEL`, `EGYENIKEZDIJ`, `HARDWARE`, `JOGI`, `JOGIBIZ`, `JOGISZEMELY`, `KEZELESIDATA`, `MEDIA`, `PENZTAR`, `QRPARAMS`, `TRANZDIJTABLA`, `UGYFEL`, `UTOLSOBLOKKOK`, `VTEMP`, `VTEMPD`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `UPDATE VTEMP SET MEGJEGYZES=`
- `WHERE VALUTANEM=`
- `SELECT * FROM VTEMP`
- `UPDATE VTEMP SET FORINTERTEK=`
- `WHERE BANKJEGY=0`
- `UPDATE HARDWARE SET SAJATHATASKORU=`
- `UPDATE VTEMP SET RATETYPE=`
- `UPDATE HARDWARE SET NAPIEGYEDIKEZDIJ=`
- `UPDATE VTEMP SET FIZETOESZKOZ=`
- `INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,OSSZESFORINTERTEK,`
- `INSERT INTO BLOKKTETEL (BIZONYLATSZAM,DATUM,VALUTANEM,ARFOLYAM,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A FORINT NEM VÁLASZTHATÓ VALUTA
- A KÚNA NEM VÁLASZTHATÓ VALUTA
- EURO ÉRMÉT NEM ADUNK EL
- Nincs ilyen valutanem
- AZ ÁRFOLYAM MÁR MÓDOSÍTVA VAN !
- EZ MÁR KEDVEZMÉNYES ÁRFOLYAM
- Ez már módositott árfolyam !
- KEZELÉSI ENGEDMÉNY UTÁN NINCS ÁRFOLYAMKEDVEZMÉNY !
- A KONVERTÁLT VALUTA ÉRTÉKE NEM LEHET NAGYOBB !
- AZ ÉRTÉK NEM LEHET 5.000 FT-NÁL NAGYOBB !
- ILYEN VALUTA MÁR VAN
- AZ E-MAILEKET SIKERESEN ELKÜLDTEM
- SIKERTELEN E-MAIL KÜLDÉS

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
