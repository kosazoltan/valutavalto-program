# Legacy modul: PROSTMK

> Forrás (primer): `Anti/VALUTA/DLL/PROSTMK/MAKEDLL/Unit2.pas` (20815 karakter) · library: `DLL/PROSTMK/MAKEDLL/Prostmk.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztaroskarbantartas`

## DFM form(ok) / képernyő
`TPROSFORM`

**Feliratok/gombok (Caption):** PROSFORM · ID-k · VISSZA · JELSZ · MEGISM · ADATOK RENDBEN · ADATM · Mit szeretne m · HERGER · Nev · Jelszav · Semmit · BIZTOS, HOGY T · IGEN T

## Eljárások / függvények (.pas)
`Adatbeolvaso`, `Penztarosnyitas`, `GetAktualAdatok`, `EscapeGombClick`, `FormCreate`, `KartonCancelGombClick`, `KartonOkeGombClick`, `IbValutaParancs`, `PasswordEditKeyDown`, `Password2EditKeyDown`, `ProsnevEditChange`, `ProsnevEditEnter`, `ProsnevEditExit`, `TorlesNemGombClick`, `TorlesIgenGombClick`, `PWstringbolHexapw`, `HexapwbolPwstring`, `FormActivate`, `BitBtn1Click`, `IDKODLISTADblClick`, `PenztarostValasztott`, `VISSZAGOMBClick`, `MODOSITASGOMBClick`, `UjPenztaros`, `BitBtn4Click`, `BitBtn2Click`, `BitBtn3Click`, `IDKODLISTAKeyUp`, `PENZTAROSTORLOGOMBClick`, `supervisorjelszo`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAROSOK`, `UTOLSOBLOKKOK`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAROSOK`
- `SELECT * FROM UTOLSOBLOKKOK`
- `UPDATE PENZTAROSOK SET PENZTAROSNEV=`
- `WHERE PENZTAROSSZAM=`
- `INSERT INTO PENZTAROSOK (PENZTAROSSZAM,PENZTAROSNEV,JELSZO,IDKOD)`
- `UPDATE UTOLSOBLOKKOK SET UTPENZTAROS=`
- `UPDATE PENZTAROSOK SET`
- `DELETE FROM PENZTAROSOK WHERE PENZTAROSSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nem egyezik a megismételt jelszó
- NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
