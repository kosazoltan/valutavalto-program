# Legacy modul (ÉRTÉKTÁR): IDOSZAK

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/idoszak/debug/unit2.pas` (7508 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/idoszak/makedll/idoszak.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`idoszakrutin`

## DFM form(ok) / képernyő
`TForm1`, `THONAPKEROFORM`

**Feliratok/gombok (Caption):** Form1 · MODALRESULT · INDIT · KILEP · HONAPKEROFORM · ADJA MEG A K · -T · -IG · ID

## Eljárások / függvények (.pas)
`Nulele`, `FormActivate`, `HoComboChange`, `IdszCancelGOMBClick`, `IdszOkeGombClick`, `IgNapComboChange`, `NapComboTolto`, `Adatrogzites`, `TolnapComboChange`, `ValutaParancs`, `FormCreate`, `IDSZOKEGOMBEnter`, `IDSZOKEGOMBExit`, `IDSZOKEGOMBMouseMove`, `THonapKeroForm.FormActivate`, `THonapKeroForm.IdszCancelGombClick`, `THonapKeroForm.HoComboChange`, `THonapKeroForm.IdszOkeGombClick`, `THonapKeroForm.AdatRogzites`, `THonapKeroForm.ValutaParancs`, `THonapKeroForm.NapComboTolto`, `THonapKeroForm.TolNapComboChange`, `THonapKeroForm.IgnapComboChange`, `THONAPKEROFORM.FormCreate`, `THONAPKEROFORM.IDSZOKEGOMBEnter`, `THONAPKEROFORM.IDSZOKEGOMBExit`, `THonapKeroForm.Nulele`, `THONAPKEROFORM.IDSZOKEGOMBMouseMove`

## Érintett adatbázis-táblák
`IDOSZAK`

**SQL-műveletek (minta):**
- `DELETE FROM IDOSZAK`
- `INSERT INTO IDOSZAK (KERTEV,KERTHO,TOLNAP,IGNAP,TOLSTRING,IGSTRING)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
