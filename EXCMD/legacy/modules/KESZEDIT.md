# Legacy modul: KESZEDIT

> Forrás (primer): `Anti/VALUTA/DLL/KESZEDIT/MAKEDLL/Unit2.pas` (33698 karakter) · library: `DLL/KESZEDIT/MAKEDLL/Keszedit.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`keszleteditalorutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · VALUTA MEGNEVEZ · MENNYIS · FT  · 123 456 789 · 30 955 · 0000 · Panel18 · DT2 · DT3 · DT4 · DT5 · DT6 · DT7 · DT9 · DT8 · DT10 · DT11 · DT12 · DT13 · DT14 · DT15 · DT16 · DT17 · DT19

## Eljárások / függvények (.pas)
`AdatNullazas`, `FormActivate`, `TombeToltes`, `PanelClear`, `PanelsWhiting`, `DN1Click`, `DNHIDEEDITKeyDown`, `ScanDnem`, `ValutaAdatokBetoltese`, `ErtekKijelzes`, `DB1Click`, `Realtostr`, `DBHIDEEDITKeyDown`, `Ftform`, `DA1Click`, `DAHIDEEDITKeyDown`, `DT1Click`, `DTHIDEEDITKeyDown`, `CI1Click`, `NextCurrency`, `PrevCurrency`, `Vparancs`, `NewCurrency`, `QUITGOMBClick`, `ENDGOMBClick`, `TRANZOKEGOMBClick`, `kerekito`, `ARFCHANGEBOXClick`, `VOltmar`, `supervisorjelszo`

## Érintett adatbázis-táblák
`ARFOLYAM`, `CIMLETPISZKOZAT`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM CIMLETPISZKOZAT`
- `SELECT * FROM VTEMP`
- `SELECT * FROM ARFOLYAM`
- `WHERE (VALUTANEM<>`
- `SELECT * FROM CIMLETPISZKOZAT WHERE VALUTANEM=`
- `INSERT INTO CIMLETPISZKOZAT (VALUTANEM,VALUTANEV,BANKJEGY,`
- `UPDATE CIMLETPISZKOZAT SET ARFOLYAM=`
- `WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
