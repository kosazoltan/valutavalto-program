# Legacy modul (ÉRTÉKTÁR): ATADOLAP

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/atadolap/debug/unit2.pas` (21065 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/atadolap/makedll/atadolap.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`atadolaprutin`

## DFM form(ok) / képernyő
`TForm1`, `TATADOLAPFORM`

**Feliratok/gombok (Caption):** Form1 · EREDM · INDIT · KILEP · ATADOLAPFORM · VISSZA A F · NYOMTAT · sz · EGYEZIK · NEM EGYEZIK · ELT · SZ · VALUTA · NEM · TARTOZ · WU/AFA RENDEL · BANKI BESZ · BANKI KISZ · IKTAT · EGY · VISSZA A MEN · KIL

## Eljárások / függvények (.pas)
`TombBetolto`, `Elokieg`, `FormActivate`, `Dekodolas`, `EtAdatfeliro`, `EtDataKijelzo`, `Puttext`, `ETSZAMEDITKeyDown`, `ETOKEGOMBClick`, `Nulele`, `GetAlapaDAT`, `KITOLTOGOMBClick`, `KILEPESGOMBClick`, `INDITOTimer`, `EDITEnter`, `EDITExit`, `AllFilesErase`, `ETMEGSEMGOMBClick`, `LETOLTOGOMBClick`, `BACKGOMBClick`, `BitBtn1Click`, `TATADOLAPFORM.FormActivate`, `TATADOLAPFORM.INDITOTimer`, `TAtadolapForm.GetAlapadat`, `TATADOLAPFORM.KitoltoGombClick`, `TATADOLAPFORM.EDITEnter`, `TATADOLAPFORM.EDITExit`, `TATADOLAPFORM.ETSZAMEDITKeyDown`, `TATADOLAPFORM.ETOkeGombClick`, `TATADOLAPFORM.LETOLTOGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS RÖGZITETT ÜZENET
- Atadólap rögzítve

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
