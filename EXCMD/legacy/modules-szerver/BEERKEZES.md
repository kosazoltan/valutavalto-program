# Legacy modul (SZERVER): BEERKEZES

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/beerkezes/debug/unit2.pas` (8524 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/beerkezes/makedll/beerk.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`beerkezettadatok`

## DFM form(ok) / képernyő
`TForm1`, `TATTEKINTES`

**Feliratok/gombok (Caption):** INDIT · KILEP · ATTEKINTES · BE

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `kilepoTimer`, `adatSzolgaltato`, `TATTEKINTES.Button1Click`, `TATTEKINTES.FormActivate`, `TAttekintes.SetDatabaseFilter`, `TAttekintes.Adatszolgaltato`, `TAttekintes.ReceptParancs`, `Tattekintes.Displayselect`, `TATTEKINTES.kilepoTimer`

## Érintett adatbázis-táblák
`ADATATADO`, `IDOSZAK`

**SQL-műveletek (minta):**
- `DELETE FROM ADATATADO`
- `INSERT INTO ADATATADO (SZURO)`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
