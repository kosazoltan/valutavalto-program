# Legacy modul (SZERVER-FEJLESZT mély): USERIN

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/userbelep/debug/unit2.pas` (20296 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/userbelep/makedll/userin.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`userbelepes`

## Eljárások / függvények
`MEGSEMTOROLGOMBClick`, `TOROLOKEGOMBClick`, `FormActivate`, `JelszoEditKeyDown`, `Jelszo1EditKeyDown`, `Jelszo2EditKeyDown`, `Jelszo1EditEnter`, `Jelszo1EditExit`, `KonfirmGombClick`, `Kivalasztas`, `M1Enter`, `M1Exit`, `M1Click`, `M2Click`, `M3Click`, `M4Click`, `MegsemGombClick`, `ModIsmeteltEditKeyDown`, `ModJelszoOkeGombClick`, `ModJelszoEditKeyDown`, `NevEditKeyDown`, `Torlorutin`, `TorloRacsDblClick`, `Uparancs`, `UserValasztas`, `UserRacsKeyDown`, `HexaToDec`, `DecitoHexa`, `Kodol`, `Dekodol`

## DFM Caption-ök
Form1 · INDIT · KILEP · Panel1 · FELHASZN · FABULYA ZSUZSA · JELSZ · Jelenlegi jelszava: · Felhaszn · Megism · BEL · KIL · EGY FELHASZN · EGY  · AZ  · JELSZAVA: · ISM · ADATOK R

## Adatbázis-táblák
`USERS`

- `SELECT * FROM USERS ORDER BY SORSZAM`
- `DELETE FROM USERS`
- `WHERE USERS=`
- `INSERT INTO USERS (USERS,HEXAPASSWORD,SORSZAM)`
- `UPDATE USERS SET HEXAPASSWORD=`
- `WHERE SORSZAM=`
- `SELECT * FROM USERS`

## Felhasználói üzenetek
- ÖNMAGADAT NEM TÖRÖLHETED !
- A JELSZÓ NEM MEGFELELŐ
- AZ ISMÉTELT JELSZÓ NEM AZONOS

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
