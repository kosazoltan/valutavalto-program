# Legacy modul (SZERVER): IRTMK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/irtmk/debug/unit2.pas` (34688 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/irtmk/makedll/irtmk.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`irodakarbantarto`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · KFT · IROD · IRODA SZ · IRODA MEGNEVEZ · IRODA NEVE: · IRODA C · BOLT NEVE: · IRODA ST · TELEFON: · BANKKOD: · KFT: · szombaton  z · vas · TART · van valuta forgalom · van Western Uni · van elektromos kereskedelem · ADATM · KIL · csak  · IRODASZ

## Eljárások / függvények (.pas)
`KILEPESGOMBClick`, `FormActivate`, `KFTCOMBOChange`, `KORZETCOMBOChange`, `KORZETCOMBOClick`, `KFTCOMBOClick`, `IrodaValtozott`, `IRODARACSCellClick`, `ScanEtarszam`, `IRODARACSKeyUp`, `ELOIRODABOXClick`, `DataReadOnly`, `ADATMODOSITOGOMBClick`, `Wparancs`, `AdatbazisKrealas`, `MakemainCurr`, `MakeElohavi`, `MakeElonapi`, `ArtIrodaKezelo`, `ArtIrodaValtozott`, `ArtParancs`, `MODMEGSEMGOMBClick`, `NEVEDITEnter`, `NEVEDITExit`, `NEVEDITKeyDown`, `MODOKEGOMBClick`, `Getvaros`, `UJPENZTARGOMBClick`, `IRODASZAMEDITEnter`, `IRODASZAMEDITKeyDown`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE (ERTEKTAR=`
- `WHERE CLOSED=`
- `UPDATE IRODAK SET KESZLETNEV=`
- `WHERE UZLET=`
- `INSERT INTO IRODAK (UZLET,KESZLETNEV,EXCELNEV,IRODACIM,BOLTNEV,TELEFON,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Hibás pénztárszám !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
