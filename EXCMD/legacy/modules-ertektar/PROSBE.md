# Legacy modul (ÉRTÉKTÁR): PROSBE

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/prosbe/debug/unit2.pas` (19382 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/prosbe/makedll/prosbe.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztarosbeleptetes`

## DFM form(ok) / képernyő
`TForm1`, `TPROSBELEP`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · Panel1 · Biztos, hogy · azonos · KOVACSN · KOV · A K · ELT · Regisztr · Kil · A p · A JELSZ · RENDBEN

## Eljárások / függvények (.pas)
`ProstValasztott`, `FormActivate`, `JelszoKodolo`, `PROSRACSKeyDown`, `JELSZOEDITKeyDown`, `HexabolDeci`, `Idkodvalasztas`, `IdKodrendben`, `PROSRACSDblClick`, `PROSRACSCellClick`, `IdtValasztott`, `Evaulate`, `FormCreate`, `GethardWareData`, `RendbenVissza`, `KILEPOGOMBClick`, `jelszoeditEnter`, `jelszoeditExit`, `MEGSEMGOMBClick`, `rendbengombClick`, `ValutaParancs`, `MISTAKEGOMBClick`, `SAMEPERSONGOMBClick`, `IDKODLISTAKeyDown`, `IDKODLISTADblClick`, `FOCIMPANELDblClick`, `Label1DblClick`, `TPROSBELEP.FormCreate`, `TPROSBELEP.FormActivate`, `Tprosbelep.GethardWareData`

## Érintett adatbázis-táblák
`HARDWARE`, `JELENLET`, `PENZTAROSOK`, `UTOLSOBLOKKOK`

**SQL-műveletek (minta):**
- `UPDATE UTOLSOBLOKKOK SET UTPENZTAROS=`
- `SELECT * FROM PENZTAROSOK`
- `SELECT * FROM HARDWARE`
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
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
