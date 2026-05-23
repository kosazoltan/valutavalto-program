# Legacy modul (SZERVER-FEJLESZT): SERVER

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/server/unit29.pas` (76619 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/server/server.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TFOMENUFORM`, `THIANYZOZARASOKFORM`, `TUSERFORM`, `TKEZIADATPOTLASFORM`, `TMNBLEGYUJTO`, `TUGYFELFORGALOMPOTLO`, `TIRODATMK`, `TMNBLISTADISPLAY`, `TGETUZLETSZAM`

**Feliratok/gombok (Caption):** Exclusive Change Server · SZERVER SZOLG · VERZI · KIL · FOMENUFORM · RENDSZERADATOK KARBANTAR · NAPI  · IMPORT-FILE K · BE · ADATSZOLG · ID · WU  · DOLGOZ · TRANZAKCI · JUTAL · HIANYZOZARASOKFORM · A TEGNAPI NAPR · HI · TOV · USERFORM · FELHASZN · FABULYA ZSUZSA · JELSZ · BEL · JELSZAVA:

## Eljárások / függvények (.pas)
`FormActivate`, `INDITOTimer`, `ForgalomGyujtes`, `CimletGyujtes`, `WuniForgalomGyujtes`, `BankGyujtes`, `Cimletosszesites`, `ForgalomOsszesites`, `WuniOsszesites`, `InterPtControl`, `TRBControl`, `ForgalomRutin`, `SendingRutin`, `TRBGyujtes`, `WuniNullazas`, `GetWuniNyitasZaras`, `StornoRegisztracio`, `TablaUrites`, `WuniAfaBerogzites`, `MetroForgalomGyujtes`, `TescoForgalomGyujtes`, `GetElszamar`, `MulthaviUtolsoCimNap`, `BetubolInteger`, `TADATLEGYUJTES.FormActivate`, `TADATLEGYUJTES.INDITOTimer`, `TadatLegyujtes.ForgalomGyujtes`, `TadatLegyujtes.ForgalomRutin`, `TadatLegyujtes.SendingRutin`, `TadatLegyujtes.TRBGyujtes`

## Érintett adatbázis-táblák
`CIMLETGYUJTO`, `FORGALOMGYUJTO`, `PENZTARKOZOTT`, `STORNOFEJ`, `STORNOTETEL`, `SUMBANKFORGALOM`, `TRBGYUJTO`, `WUNIGYUJTO`

**SQL-műveletek (minta):**
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE FEJ.DATUM=`
- `WHERE FEJ.DATUM BETWEEN`
- `Select * From Forgalomgyujto`
- `where Irodaszam=`
- `INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,`
- `UPDATE FORGALOMGYUJTO`
- `WHERE IRODASZAM=`
- `SELECT * FROM PENZTARKOZOTT`
- `WHERE KULDODNEMFOGADO=`
- `INSERT INTO PENZTARKOZOTT (VALUTANEM,KULDO,FOGADO,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
