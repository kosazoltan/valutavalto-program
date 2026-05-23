# Legacy modul (SZERVER): SUMWUAFA

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/sumwuafa/debug/unit2.pas` (12049 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/sumwuafa/makedll/sumwuafa.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`summawuniafa`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2

## Eljárások / függvények (.pas)
`FormActivate`, `Wparancs`, `SumAdatNullazo`, `WuniDataBeolvasas`, `WuniDataOsszeadas`, `Sumkibe`, `AdatFeliro`, `KorzetSum`, `KFTsum`, `Cegsum`, `KILEPOTimer`, `TForm2.FormActivate`, `TForm2.KorzetSum`, `TForm2.Kftsum`, `TForm2.Cegsum`, `TForm2.SumadatNullazo`, `TForm2.WunidataBeolvasas`, `TForm2.WuniDataOsszeadas`, `TForm2.SumKibe`, `TForm2.Adatfeliro`, `TForm2.Wparancs`, `TForm2.KILEPOTimer`

## Érintett adatbázis-táblák
`WUNIGYUJTO`

**SQL-műveletek (minta):**
- `SELECT * FROM WUNIGYUJTO`
- `WHERE ERTEKTAR=`
- `WHERE (IRODASZAM=0) AND (CEGBETU=`
- `WHERE (IRODASZAM=0) AND (ERTEKTAR=0)`
- `WHERE (IRODASZAM=0) AND (ERTEKTAR=0) AND (CEGBETU=`
- `INSERT INTO WUNIGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
