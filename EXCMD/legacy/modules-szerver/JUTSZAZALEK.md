# Legacy modul (SZERVER): JUTSZAZALEK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/jutszazalek/debug/unit2.pas` (3335 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/jutszazalek/makedll/jutszaz.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`jutalekszorzo`

## DFM form(ok) / képernyő
`TForm1`, `TSETSZORZO`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · SETSZORZO · Jutal · Kil · IRODA · IRODA MEGNEVEZ · SZORZ

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `IrodaBetolto`, `IrodaBeiro`, `TSETSZORZO.Button1Click`, `TSETSZORZO.FormActivate`, `TSetSzorzo.IrodaBetolto`, `TSetszorzo.Irodabeiro`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE CLOSED=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
