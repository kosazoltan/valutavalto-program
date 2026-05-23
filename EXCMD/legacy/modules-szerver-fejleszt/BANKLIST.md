# Legacy modul (SZERVER-FEJLESZT): BANKLIST

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/banklist/unit1.pas` (20568 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/banklist/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · BitBtn1 · BitBtn2 · Panel1 · Panel2 · Panel3 · Panel4 · Panel5 · Panel6 · Panel7

## Eljárások / függvények (.pas)
`BitBtn2Click`, `BitBtn1Click`, `BankParancs`, `BankDataTorles`, `Menet`, `JMenet`, `VFileRead`, `Regisztralas`, `IrodanevBeolvasas`, `JogiRegisztralas`, `JogiFileread`, `TForm1.BitBtn2Click`, `TForm1.BitBtn1Click`, `TForm1.BankDataTorles`, `TForm1.BankParancs`, `TForm1.Menet`, `TForm1.regisztralas`, `TForm1.VFileRead`, `TForm1.IrodanevBeolvasas`, `TForm1.JMenet`, `TForm1.JogiFileRead`, `TForm1.Jogiregisztralas`

## Érintett adatbázis-táblák
`IRODAK`, `JOGI`, `JOGIBEST`, `JOGIEAST`, `JOGIPANN`, `JOGIZLOG`, `MAGAN`, `TERMBEST`, `TERMEAST`, `TERMPANN`, `TERMZLOG`

**SQL-műveletek (minta):**
- `DELETE FROM TERMBEST`
- `DELETE FROM TERMEAST`
- `DELETE FROM TERMPANN`
- `DELETE FROM TERMZLOG`
- `DELETE FROM JOGIBEST`
- `DELETE FROM JOGIEAST`
- `DELETE FROM JOGIPANN`
- `DELETE FROM JOGIZLOG`
- `SELECT * FROM MAGAN`
- `SELECT * FROM`
- `WHERE (SZULETESIIDO LIKE`
- `WHERE (SORSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- KÉSZEN VAGYOK

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
