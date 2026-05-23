# Legacy modul (SZERVER): USERBELEP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/userbelep/debug/unit2.pas` (20296 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/userbelep/makedll/userin.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`userbelepes`

## DFM form(ok) / képernyő
`TForm1`, `TUSERFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Panel1 · FELHASZN · FABULYA ZSUZSA · JELSZ · Jelenlegi jelszava: · Felhaszn · Megism · BEL · KIL · EGY FELHASZN · EGY  · AZ  · JELSZAVA: · ISM · ADATOK R

## Eljárások / függvények (.pas)
`MEGSEMTOROLGOMBClick`, `TOROLOKEGOMBClick`, `FormActivate`, `JelszoEditKeyDown`, `Jelszo1EditKeyDown`, `Jelszo2EditKeyDown`, `Jelszo1EditEnter`, `Jelszo1EditExit`, `KonfirmGombClick`, `Kivalasztas`, `M1Enter`, `M1Exit`, `M1Click`, `M2Click`, `M3Click`, `M4Click`, `MegsemGombClick`, `ModIsmeteltEditKeyDown`, `ModJelszoOkeGombClick`, `ModJelszoEditKeyDown`, `NevEditKeyDown`, `Torlorutin`, `TorloRacsDblClick`, `Uparancs`, `UserValasztas`, `UserRacsKeyDown`, `HexaToDec`, `DecitoHexa`, `Kodol`, `Dekodol`

## Érintett adatbázis-táblák
`USERS`

**SQL-műveletek (minta):**
- `SELECT * FROM USERS ORDER BY SORSZAM`
- `DELETE FROM USERS`
- `WHERE USERS=`
- `INSERT INTO USERS (USERS,HEXAPASSWORD,SORSZAM)`
- `UPDATE USERS SET HEXAPASSWORD=`
- `WHERE SORSZAM=`
- `SELECT * FROM USERS`

## Felhasználói üzenetek (üzleti szabály-jelek)
- ÖNMAGADAT NEM TÖRÖLHETED !
- A JELSZÓ NEM MEGFELELŐ
- AZ ISMÉTELT JELSZÓ NEM AZONOS

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
