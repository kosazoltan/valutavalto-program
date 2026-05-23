# Legacy modul (ÉRTÉKTÁR): PROSTMK

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/prostmk/debug/unit2.pas` (20624 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/prostmk/makedll/prostmk.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztaroskarbantartas`

## DFM form(ok) / képernyő
`TForm1`, `TPROSFORM`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · PROSFORM · ID-k · VISSZA · JELSZ · MEGISM · ADATOK RENDBEN · ADATM · Mit szeretne m · HERGER · Nev · Jelszav · Semmit · BIZTOS, HOGY T · IGEN T

## Eljárások / függvények (.pas)
`Adatbeolvaso`, `Penztarosnyitas`, `GetAktualAdatok`, `EscapeGombClick`, `FormCreate`, `KartonCancelGombClick`, `KartonOkeGombClick`, `IbValutaParancs`, `PasswordEditKeyDown`, `Password2EditKeyDown`, `ProsnevEditChange`, `ProsnevEditEnter`, `ProsnevEditExit`, `TorlesNemGombClick`, `TorlesIgenGombClick`, `PWstringbolHexapw`, `HexapwbolPwstring`, `FormActivate`, `BitBtn1Click`, `IDKODLISTADblClick`, `PenztarostValasztott`, `VISSZAGOMBClick`, `MODOSITASGOMBClick`, `UjPenztaros`, `BitBtn4Click`, `BitBtn2Click`, `BitBtn3Click`, `IDKODLISTAKeyUp`, `PENZTAROSTORLOGOMBClick`, `supervisorjelszo`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAROSOK`, `UTOLSOBLOKKOK`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAROSOK`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM UTOLSOBLOKKOK`
- `UPDATE PENZTAROSOK SET PENZTAROSNEV=`
- `WHERE PENZTAROSSZAM=`
- `INSERT INTO PENZTAROSOK (PENZTAROSSZAM,PENZTAROSNEV,JELSZO,IDKOD)`
- `UPDATE UTOLSOBLOKKOK SET LASTPENZTAROS=`
- `UPDATE PENZTAROSOK SET`
- `DELETE FROM PENZTAROSOK WHERE PENZTAROSSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nem egyezik a megismételt jelszó
- NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
