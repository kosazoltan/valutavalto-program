# Legacy modul: ATADOLAP

> Forrás (primer): `Anti/VALUTA/DLL/ATADOLAP/MAKEDLL/unit2.pas` (61908 karakter) · library: `DLL/ATADOLAP/MAKEDLL/Atadolap.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`atadolaprutin`

## DFM form(ok) / képernyő
`TATADOLAPFORM`

**Feliratok/gombok (Caption):** ATADOLAPFORM · NYOMTAT · VISSZA A MEN · ADATFORGALOM A SZERVERREL · sz · EGYEZIK · NEM EGYEZIK · ELT · SZ · VALUTA · NEM · TARTOZ · WU/AFA RENDEL · BANKI BESZ · BANKI KISZ · IKTAT · EGY · TELJES · ENGED · TELEFONSZ · KONKURENCI · VISSZA A F

## Eljárások / függvények (.pas)
`ptszamEDITEnter`, `ptszamEDITExit`, `Elokieg`, `PTEDITKeyDown`, `AllPageErase`, `FormActivate`, `PanelEnter`, `KovetkezoPtPanel`, `KovetkezoPtEdit`, `KovetkezoEtPanel`, `KovetkezoEtEdit`, `PTMEGSEMGOMBClick`, `PTOKEGOMBClick`, `Adatfeliro`, `EtAdatfeliro`, `PtDataKijelzo`, `EtDataKijelzo`, `PtDownLoad`, `ErtekTarSkicc`, `Penztarskicc`, `StartNyomtatas`, `FTPszerverbeBelep`, `Ftform`, `ETSZAMEDITKeyDown`, `ETOKEGOMBClick`, `ETATADPANELEnter`, `EgyEtLapBeolvasasa`, `EgyPTLapBeolvasasa`, `Datumkodolo`, `GetLapfilenev`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
- AZ ÁTADÓLAP DÁTUMA HIBÁS !
- NINCS EGYETLEN KINYOMATLAN ÁTADÓLAP SEM
- NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT
- A KÖZPONTI SZERVER NEM ÉRHETŐ EL

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
