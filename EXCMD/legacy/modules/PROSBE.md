# Legacy modul: PROSBE

> Forrás (primer): `Anti/VALUTA/DLL/PROSBE/MAKEDLL/Unit2.pas` (19922 karakter) · library: `DLL/PROSBE/MAKEDLL/Prosbe.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztarosbeleptetes`

## DFM form(ok) / képernyő
`TPROSBELEP`

**Feliratok/gombok (Caption):** Biztos, hogy · azonos · KOVACSN · KOV · A K · ELT · Regisztr · Kil · A p · A JELSZ · RENDBEN

## Eljárások / függvények (.pas)
`ProstValasztott`, `FormActivate`, `JelszoKodolo`, `PROSRACSKeyDown`, `JELSZOEDITKeyDown`, `HexabolDeci`, `Nul3`, `Idkodvalasztas`, `IdKodrendben`, `PROSRACSDblClick`, `PROSRACSCellClick`, `IdtValasztott`, `Evaulate`, `FormCreate`, `GethardWareData`, `RendbenVissza`, `KILEPOGOMBClick`, `jelszoeditEnter`, `jelszoeditExit`, `MEGSEMGOMBClick`, `rendbengombClick`, `ValutaParancs`, `MISTAKEGOMBClick`, `SAMEPERSONGOMBClick`, `IDKODLISTAKeyDown`, `IDKODLISTADblClick`, `FOCIMPANELDblClick`, `Label1DblClick`, `TPROSBELEP.FormCreate`, `TPROSBELEP.FormActivate`

## Érintett adatbázis-táblák
`HARDWARE`, `JELENLET`, `PENZTAROSOK`, `UTOLSOBLOKKOK`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE UTOLSOBLOKKOK SET UTPENZTAROS=`
- `SELECT * FROM PENZTAROSOK`
- `UPDATE PENZTAROSOK SET JELSZO=`
- `WHERE PENZTAROSSZAM=`
- `UPDATE PENZTAROSOK SET IDKOD=`
- `UPDATE HARDWARE SET PENZTAROSNEV=`
- `SELECT * FROM JELENLET`
- `WHERE (DATUM=`
- `INSERT INTO JELENLET (DATUM,PENZTAROSNEV,IDKOD,BELEPES)`

## Felhasználói üzenetek (üzleti szabály-jelek)
- JELSZÓ RENDBEN. A PROGRAM INDULHAT !
- SAJNOS ÖN NEM ISMERI A JELSZÓT !
- ELRONTOTTA A JELSZÓT ! PROBÁLKOZZON ÚJRA
- NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
