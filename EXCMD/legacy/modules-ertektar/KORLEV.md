# Legacy modul (ÉRTÉKTÁR): KORLEV

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/korlev/debug/unit2.pas` (24795 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/korlev/makedll/korlev.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`korlevelrutin`

## DFM form(ok) / képernyő
`TForm1`, `TKORLEVEL`

**Feliratok/gombok (Caption):** Form1 · KIL · KORLEVEL · A LET · IKTAT · LEV · bet

## Eljárások / függvények (.pas)
`BitBtn1Click`, `FormActivate`, `KorlevelLetoltes`, `KorlevelOlvasas`, `Korparancs`, `LevelRegisztralas`, `EgyNyelv`, `MessKijelzes`, `Korleveldownload`, `LeveletValasztott`, `WinExecAndWait32`, `Hundatetostr`, `OLVASOGOMBClick`, `LEVELRACSDblClick`, `LEVELRACSKeyDown`, `KILEPOTimer`, `Readregist`, `LASTYEARGOMBClick`, `FormCreate`, `Nulele`, `ARCHIVEGOMBClick`, `korlevelrutin`, `TKORLEVEL.FormActivate`, `TKorlevel.KorlevelLetoltes`, `TKorlevel.Korleveldownload`, `TKorlevel.LevelRegisztralas`, `TKorlevel.KorlevelOlvasas`, `TKORLEVEL.OLVASOGOMBClick`, `TKORLEVEL.LEVELRACSDblClick`, `TKORLEVEL.LEVELRACSKeyDown`

## Érintett adatbázis-táblák
`ADATOK`, `ARCHIVE`, `HARDWARE`, `IKTATO`, `KORLEVEL`, `LASTYEAR`, `PARAMETERS`, `PENZTAROSOK`, `SIGNAL`

**SQL-műveletek (minta):**
- `SELECT * FROM KORLEVEL`
- `WHERE SORSZAM=`
- `DELETE FROM IKTATO`
- `INSERT INTO IKTATO (DATUM,SORSZAM,TARTALOM,IKTATOSZAM,FILENEV)`
- `UPDATE PARAMETERS SET LASTSORSZAM=`
- `SELECT * FROM PARAMETERS`
- `SELECT * FROM IKTATO`
- `UPDATE PARAMETERS SET SOFFICEPATH=`
- `SELECT * FROM SIGNAL`
- `WHERE (DOLGSORSZAM=`
- `INSERT INTO SIGNAL (DOLGSORSZAM,LETTERNUM,MIKOR)`
- `UPDATE PENZTAROSOK SET LASTREADLETTER=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
