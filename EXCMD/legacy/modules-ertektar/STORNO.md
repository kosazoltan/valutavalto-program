# Legacy modul (ÉRTÉKTÁR): STORNO

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/storno/debug/unit2.pas` (20123 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/storno/makedll/storno.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`stornorutin`

## DFM form(ok) / képernyő
`TForm1`, `TSTORNOFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · STORNOFORM · Bizonylat: · keres ·    · Valuta  · Forint  · BIZONYLAT · VISSZA A MEN · EZT A BIZONYLATOT STORN · UF143 · BIZTOSAN STORN · SZ · V143123456 · IGEN · NEM · EGY BIZONYLAT  · Bizonylatsz · Bizonylat  · Storn · 456 789 456 Ft · STORN · A NAV BIZONYLAT RENDBEN KINYOMODOTT ?

## Eljárások / függvények (.pas)
`FormActivate`, `BizLista`, `FtForm`, `ValutaParancs`, `URClick`, `FRClick`, `UFRClick`, `FFRClick`, `AlapAdatBeolvasas`, `SureStorno`, `SzamlaBeolvasas`, `StornoFolyamat`, `VISSZAGOMBClick`, `FormKeyPress`, `NEMGOMBClick`, `STORNOGOMBClick`, `radiokClick`, `IGENGOMBClick`, `BIZONYLATRACSDblClick`, `ZCOUNTEDITEnter`, `ZCOUNTEDITExit`, `MEGSEMGOMBClick`, `STARTGOMBClick`, `Nulele`, `INDOKEDITKeyDown`, `KILEPOTimer`, `blokknyomtatas`, `supervisorjelszo`, `TSTORNOFORM.FormActivate`, `TStornoForm.AlapadatBeolvasas`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `BLOKKTETEL`, `HARDWARE`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `SELECT* FROM PENZTAR`
- `SELECT* FROM HARDWARE`
- `SELECT * FROM BLOKKFEJ`
- `WHERE (BIZONYLATSZAM LIKE`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM BLOKKTETEL`
- `UPDATE BLOKKFEJ SET STORNO=2`
- `UPDATE BLOKKTETEL SET STORNO=2`
- `INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,FORINTERTEK,`
- `INSERT INTO BLOKKTETEL (BIZONYLATSZAM,VALUTANEM,ARFOLYAM,`
- `INSERT INTO VTEMP (VALUTANEM,ARFOLYAM,BANKJEGY,FORINTERTEK)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
