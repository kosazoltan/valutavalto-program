# Legacy modul (SZERVER): HOVALASZ

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/hovalasz/debug/unit2.pas` (4524 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/hovalasz/makedll/hovalasz.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`hovalasztorutin`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2

## Eljárások / függvények (.pas)
`FormActivate`, `EvComboChange`, `HoOkeGombClick`, `HoMegsemGOMBClick`, `RecParancs`, `Nulele`, `TForm2.FormActivate`, `TForm2.EVCOMBOChange`, `TForm2.HOOKEGOMBClick`, `TForm2.HOMEGSEMGOMBClick`, `TForm2.Nulele`, `TForm2.Recparancs`

## Érintett adatbázis-táblák
`IDOSZAK`

**SQL-műveletek (minta):**
- `DELETE FROM IDOSZAK`
- `INSERT INTO IDOSZAK (STARTDATE,ENDDATE)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
