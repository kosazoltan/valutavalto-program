# Legacy modul: TRADE (kereskedési / díj alrendszer)

> Forrás (primer): `Anti/VALUTA/TRADE/` — 14 unit, fő projekt `fejleszt/trade.dpr`.

## Unitok
`unit3.pas` (62527b), `unit1.pas` (53483b), `unit12.pas` (49617b), `unit2.pas` (47646b), `unit11.pas` (26487b), `unit10.pas` (20270b), `unit4.pas` (10306b), `unit5.pas` (6437b), `unit9.pas` (4888b), `unit13.pas` (4849b), `unit8.pas` (3067b), `unit14.pas` (2138b), `unit1.pas` (2091b), `unit1.pas` (1974b)

## Exportált API
_(EXE projekt, nem DLL — nincs exports)_

## Eljárások / függvények
`AfasSzamla`, `AlapadatBeolvasas`, `Archivalo`, `BlokkFocimIro`, `BlokkNyitas`, `CikktorzsBeolvasas`, `FormActivate`, `FormClose`, `HardKozepreir`, `HaviTradeControl`, `InditoTimer`, `KilepesGombClick`, `KilepoTimerTimer`, `Konyveles`, `Kozepreir`, `ListaGombClick`, `Logbair`, `LogOlvasoGombClick`, `MakeTradeTabla`, `MatricaSellerCopy`, `MatricaCustomerCopy`, `MatricaGombClick`, `SetLogFile`, `StartNyomtatas`, `TelefonBlokk`, `TelefonGombClick`, `TelefonGombEnter`, `TelefonGombExit`, `TelefonGombMouseMove`, `TextKiiro`, `TelAfasSzamla`, `TelenorBizonylat`, `TRadeParancs`, `TanusitvanyGombClick`, `TMobilBizonylat`

## Érintett adatbázis-táblák
`AUTOPALYA`, `CIKKTORZS`, `FELSEGJEL`, `HARDWARE`, `PARAMETERS`, `PENZTAR`, `PENZTAROSOK`, `SORTED`, `UTOLSOBLOKKOK`

## SQL-műveletek (minta)
- `INSERT INTO`
- `UPDATE PARAMETERS SET LASTMATRICA=`
- `UPDATE PARAMETERS SET LASTTELEFON=`
- `SELECT * FROM PARAMETERS`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM UTOLSOBLOKKOK`
- `SELECT * FROM CIKKTORZS WHERE AZONOSITO<1000`
- `SELECT * FROM`
- `UPDATE PARAMETERS SET UTBIZONYLAT=`
- `WHERE PENZTARKOD<>`
- `UPDATE`

## Felhasználói üzenetek
- NINCS INTERNET !
- NINCS ADAT A HÓNAPRÓL !
- Nem adtad meg az összeget
- NINCS ENNYI PÉNZ FELADÁSRA !
- NINCS A KÉRT HÓNAPRÓL ADAT
- NINCS ERRŐL A NAPRÓL LOG-FILE
- A RENDSZÁMOT MEG KELL ADNI
- NEM EGYEZIK A MEGISMÉTELT RENDSZÁM
- A JELSZÓ NEM MEGFELELŐ
- HIBÁS A RÖGZITETT JELSZÓ !

## Megfeleltetés
_(TBD — kereskedési/díj alrendszer; a jelenlegi programban a tranzakció+díj modulok fedik. Gap-jelölt, ha új kereskedési funkció.)_
