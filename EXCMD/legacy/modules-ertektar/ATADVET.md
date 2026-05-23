# Legacy modul (ÉRTÉKTÁR): ATADVET

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/atadvet/debug/unit2.pas` (84339 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/atadvet/makedll/atadvet.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`atadatvetrutin`

## DFM form(ok) / képernyő
`TForm1`, `TATADATVETFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · FORINT  · KELL C · NEM KELL C · 258 450 000 Ft · TRANZAKCI · Kezel · E-kereskedelmi p · Vissza a valutaprogram f · Horv · Teljes k · A bek · CIMLETFUGGONY · CIMLETEZ · CIMLETEZZEM ? · IGEN · NEM · VALUT · Valut · ALLGIVEBACKPANEL · Az  · A t · Forint 

## Eljárások / függvények (.pas)
`AlapadatBeolvasas`, `Alapnullazas`, `AtadGombClick`, `AtvetGombClick`, `B1Click`, `B1MouseDown`, `BackBizonyEditKeyDown`, `BackDatumEditKeyDown`, `BackFtBizonyEditKeyDown`, `BackGombClick`, `BackPtarEditEnter`, `BackPtarEditExit`, `BackPtarEditKeyDown`, `BlokkFejIras`, `BlokkTetelIras`, `CimletBedolgozas`, `CImletKijelolo`, `CimletNyomtatas`, `CImletTombbe`, `Dec1Click`, `PRNZATADGOMBClick`, `PENZATVETGOMBClick`, `DisappearPanels`, `Dnemkod`, `EgyebPenzatvetel`, `EgyebPenzekKonyvelese`, `EgytetelFeliras`, `EkerGombClick`, `EkerAtvetel`, `ElszamBeolvasas`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKFEJ`, `BLOKKTETEL`, `CIMINI`, `CIMLETEK`, `CIMLETPISZKOZAT`, `EKERESKEDELEM`, `HARDWARE`, `KEZDIJ`, `KEZDIJDATA`, `PENZTAR`, `UTOLSOBLOKKOK`, `VTEMP`, `WPENZSZALLITAS`, `WUAFAADATOK`, `WUAFAFORG`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET TIPUS=`
- `DELETE FROM VTEMP`
- `INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,`
- `UPDATE VTEMP SET BIZONYLATSZAM=`
- `INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,PLOMBASZAM,`
- `UPDATE UTOLSOBLOKKOK SET`
- `INSERT INTO BLOKKTETEL (DATUM,BIZONYLATSZAM,VALUTANEM,ELOJEL,`
- `INSERT INTO VTEMP (VALUTANEM,BANKJEGY,ELOJEL,FORINTERTEK,`
- `SELECT * FROM CIMLETPISZKOZAT`
- `DELETE FROM BLOKKFEJ`
- `WHERE BIZONYLATSZAM=`
- `DELETE FROM BLOKKTETEL`

## Felhasználói üzenetek (üzleti szabály-jelek)
- ÉRVÉNYTELEN BIZONYLATSZÁM: (
- ÉRVÉNYTELEN A FORINT BIZONYLATSZÁM: (
- NINCS ENNYI 

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
