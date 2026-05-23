# Legacy modul (ÉRTÉKTÁR): ARFTMK

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/arftmk/debug/unit2.pas` (15177 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/arftmk/makedll/arftmk.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`arfolyamrutin`

## DFM form(ok) / képernyő
`TForm1`, `TARFOLYAMFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · ARFOLYAMFORM · A VALUTA  · DNEM · VALUTA MEGNEVEZ · ELAD · ELSZ-I  · VISSZA A F

## Eljárások / függvények (.pas)
`Nul3`, `Aparancs`, `Intdekodol`, `AlapadatBeolvasas`, `FormCreate`, `ArfolyamBeolvasas`, `FTPSzerverbeBelep`, `crsTorlese`, `Elokieg`, `Kieg`, `Validalo`, `DuplaSupkod`, `IrodaAdatBeolvasas`, `ESCAPEGOMBClick`, `PTARCOMBOChange`, `arfolyamletoltes`, `supervisorjelszo`, `TARFOLYAMFORM.FormCreate`, `TARFOLYAMFORM.Kieg`, `TARFOLYAMFORM.Elokieg`, `TARFOLYAMFORM.Validalo`, `TARFOLYAMFORM.DuplaSupkod`, `TARFOLYAMFORM.AlapadatBeolvasas`, `TArfolyamForm.IrodaAdatBeolvasas`, `TArfolyamForm.Nul3`, `TARFOLYAMFORM.ESCAPEGOMBClick`, `TARFOLYAMFORM.PTARCOMBOChange`, `TArfolyamform.Arfolyambeolvasas`, `TarfolyamForm.FTPszerverbeBelep`, `TarfolyamForm.crsTorlese`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `IRODAK`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM IRODAK`
- `WHERE (CLOSED<>`
- `DELETE FROM ARFOLYAM`
- `INSERT INTO ARFOLYAM (VALUTANEM,VALUTANEV,ELSZAMOLASIARFOLYAM,`
- `SELECT * FROM ARFOLYAM`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
