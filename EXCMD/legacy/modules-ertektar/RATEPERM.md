# Legacy modul (ÉRTÉKTÁR): RATEPERM **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/rateperm/debug/unit2.pas` (23421 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/rateperm/debug/minta.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TENGEDELYADAS`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · KEDVEZM · Melyik p · Melyik napra ad kedvezm · KEZEL · TRANZAKCI · VALUTA · BANKJEGY · KEDV.  · ENGED · EGY  · BIZONYLATSZ · A fenti kedvezm · Kil · AZ ENGED · 2016.12.22 · EGY KEZEL · A KEZEL · Ft · HOGYAN FOLYTASSUK AZ ADATFELVITELT ? · TOV · VISSZAT

## Eljárások / függvények (.pas)
`FormActivate`, `PENZTARCOMBOChange`, `ComboFeltoltes`, `FtForm`, `MakeHaviTabla`, `GetTranzIndex`, `Nulele`, `Konvertdatum`, `EXITGOMBClick`, `PENZTARRENDBENGOMBClick`, `ARFOLYAMENGEDOGOMBClick`, `ESCAPEGOMBClick`, `TRANZCOMBOChange`, `BANKJEGYEDITEnter`, `BANKJEGYEDITExit`, `BANKJEGYEDITKeyDown`, `ARFOLYAMKONYVELOGOMBClick`, `ArfolyamKonyveles`, `KezdijKonyveles`, `AlapadatBeolvasas`, `MASIKPENZTARGOMBClick`, `KEZDIJENGEDOGOMBClick`, `kezdijtipcomboChange`, `KEZDIJEDITKeyDown`, `KEZDIJKONYVELOGOMBClick`, `TOVABBIGOMBClick`, `RemoteParancs`, `KBIZONYLATEDITKeyDown`, `BIZONYLATEDITKeyDown`, `TENGEDELYADAS.FormActivate`

## Érintett adatbázis-táblák
`HARDWARE`, `IRODAK`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE (ERTEKTAR=`
- `INSERT INTO`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
