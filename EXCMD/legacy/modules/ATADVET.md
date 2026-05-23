# Legacy modul: ATADVET

> Forrás (primer): `Anti/VALUTA/DLL/ATADVET/MAKEDLL/Unit2.pas` (134295 karakter) · library: `DLL/ATADVET/MAKEDLL/Atadvet.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`atadatvetrutin`

## DFM form(ok) / képernyő
`TATADATVETFORM`

**Feliratok/gombok (Caption):** FORINT  · KELL C · NEM KELL C · 258 450 000 Ft · TRANZAKCI · Kezel · E-kereskedelem p · Vissza a valutaprogram f · Horv · Deviza  · Teljes k · CIMLETFUGGONY · CIMLETEZ · CIMLETEZZEM ? · IGEN · NEM · VALUT · Valut · ALLGIVEBACKPANEL · Az  · A t · Forint  · UF · fenti adatok rendben · tranzakci

## Eljárások / függvények (.pas)
`AlapadatBeolvasas`, `Alapnullazas`, `AllAfaAtad`, `AllAtadGombClick`, `AllAtvetGombClick`, `AllDevTombbe`, `AllEkerAtad`, `AllKezdijAtad`, `AllMetroAfaAtad`, `AllValutaTotFileBa`, `AllWesternatad`, `AtadGombClick`, `AtvetGombClick`, `B1Click`, `B1MouseDown`, `BackBizonyEditKeyDown`, `BackDatumEditKeyDown`, `BackFtBizonyEditKeyDown`, `BackGombClick`, `BackPtarEditEnter`, `BackPtarEditExit`, `BackPtarEditKeyDown`, `BlokkFejIras`, `BlokkTetelIras`, `CimletBedolgozas`, `CImletKijelolo`, `CimletNyomtatas`, `CImletTombbe`, `Dec1Click`, `DevAtadGombClick`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKFEJ`, `BLOKKTETEL`, `CIMINI`, `CIMLETEK`, `CIMLETPISZKOZAT`, `HARDWARE`, `KEZELESIDATA`, `KEZELESIDIJ`, `MATBIZONYLAT`, `MATDATA`, `METROAFAMOZGAS`, `PARAMETERS`, `PENZTAR`, `QRPARAMS`, `TESCO`, `UTOLSOBLOKKOK`, `VTEMP`, `WUAFAADATOK`, `WUMOZGAS`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `DELETE FROM QRPARAMS`
- `UPDATE QRPARAMS SET NUMBER=`
- `INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,KEZELESIDIJ,`
- `UPDATE VTEMP SET BIZONYLATSZAM=`
- `UPDATE UTOLSOBLOKKOK SET`
- `INSERT INTO BLOKKTETEL (DATUM,BIZONYLATSZAM,VALUTANEM,ELOJEL,`
- `INSERT INTO VTEMP (VALUTANEM,VALUTANEV,ARFOLYAM,ELSZAMOLASIARFOLYAM,`
- `INSERT INTO QRPARAMS (VALUTANEM,BANKJEGY)`
- `SELECT * FROM CIMLETPISZKOZAT`
- `DELETE FROM CIMLETEK`
- `INSERT INTO CIMLETEK (DATUM,VALUTANEM,OSSZESFORINTERTEK)`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBÁS CIMLETEZÉS
- ÉRVÉNYTELEN BIZONYLATSZÁM: (
- ÉRVÉNYTELEN A FORINT BIZONYLATSZÁM: (
- NINCS ENNYI 

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
