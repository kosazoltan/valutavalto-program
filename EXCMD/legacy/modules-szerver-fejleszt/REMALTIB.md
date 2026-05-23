# Legacy modul (SZERVER-FEJLESZT): REMALTIB

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/remaltib/unit1.pas` (51949 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/remaltib/altib.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TROGZITESFORM`, `TREKORDTORLOFORM`, `TZAPPOLOFORM`, `TSZAMSUMMA`, `TMEZOTOLTOFORM`

**Feliratok/gombok (Caption):** Form1 · ALTERNATIV ADATB · dek · ALTIB-8.00 · KIL · MNEVPANEL2 · MNEVPANEL3 · SZ · EG · TIZEDES T · MTIPPANEL4 · MTIPPANEL5 · MTIPPANEL6 · MTIPPANEL7 · MTIPPANEL8 · MNEVPANEL4 · MNEVPANEL5 · MNEVPANEL6 · MNEVPANEL7 · MNEVPANEL8 ·   ADATKIJELZ ·   RENDEZ · Nincs rendez · Sorbarendez · ELS

## Eljárások / függvények (.pas)
`FdbComboFeltoltes`, `FormCreate`, `QUITGOMBClick`, `DBCOMBOChange`, `TABLALISTAClick`, `TablaChange`, `TABLALISTAEnter`, `TABLALISTAExit`, `DBEDITEnter`, `DBEDITExit`, `RENDEZESVALASZTOClick`, `MezoMeghatarozo`, `TablaTorles`, `TablaBeiras`, `UpScroll`, `DownScroll`, `MasRekord`, `RekordRead`, `Felfele`, `Lefele`, `AdatControl`, `GetIndexNev`, `VanAltIndex`, `ADATKIJELZESClick`, `MVALUEEDIT1Enter`, `MVALUEEDIT1Exit`, `MVALUEEDIT1KeyDown`, `TABLALISTAKeyDown`, `DBEDITKeyDown`, `DBNavigator1Click`

## Érintett adatbázis-táblák
`RDB`

**SQL-műveletek (minta):**
- `SELECT RDB$RELATION_NAME FROM RDB$RELATIONS`
- `WHERE RDB$FLAGS=1`
- `SELECT r.RDB$FIELD_NAME AS FIELD_NAME,`
- `FROM RDB$RELATION_FIELDS r`
- `WHERE r.RDB$RELATION_NAME=`
- `+_aktTablaNev,_XFS,[ixDescending]);

  Ibtranz.Commit;


  IbTabla.IndexDefs.Update;

  IBTabla.IndexName :=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉPERNYÖ FELBONTÁSÁT ÁLLÍTSA 1024x768-RA !
- NEM TALÁLOK TÁBLÁKAT !
- NEM TALÁLOM A KERESETT ADATOT !
- NEM TALÁLTAM ADATBÁZISOKAT

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
