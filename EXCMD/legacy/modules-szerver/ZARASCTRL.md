# Legacy modul (SZERVER): ZARASCTRL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/zarasctrl/debug/unit2.pas` (34444 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/zarasctrl/makedll/zarasctrl.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`zarasbeerkezesek`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · Label5 · 23 · 25 · 10 · 30 · 29 · 28 · 27 · 22 · 21 · 50 · 49 · 48 · 47 · 46 · 45 · 44 · 43 · 42 · 41 · 70

## Eljárások / függvények (.pas)
`AcDbookParancs`, `AllPenztarGombClick`, `Bejottdisp`, `BitBtn2Click`, `DatumMegsemGombClick`, `DatumRendbenGombClick`, `DbookBeolvaso`, `DBookParancs`, `DDisp`, `EgyPenztarGombClick`, `EloHoGombClick`, `ElozoNAPGOMBClick`, `FormActivate`, `IrodaBetolto`, `JeloloVisszaGombClick`, `KovetkezoNapGombClick`, `KovHoGombClick`, `NaptarChange`, `NemJottbeDisp`, `NoPtarDisp`, `Pn1MouseMove`, `Pn1Click`, `Tablaalapra`, `Tablaszinezo`, `Tombetolto`, `VisszaGombClick`, `ZarvaDisp`, `HunDateToStr`, `Hunstrtodate`, `Nulele`

## Érintett adatbázis-táblák
`DAYB`, `IRODAK`, `RENDSZER`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `SELECT * FROM RENDSZER`
- `SELECT * FROM IRODAK`
- `UPDATE DAYB`
- `WHERE PENZTAR=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
