# Legacy modul (SZERVER-FEJLESZT): SUMTRADE

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/sumtrade/unit4.pas` (10108 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/sumtrade/electrad.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TGETIDOSZAK`, `TMEXCEL`, `TUJADATGYUJTO`, `TEREDMENYKIJELZES`

**Feliratok/gombok (Caption):** ELEKTROMOS KERESKED · AZ E-KERESKEDELEM ADATAINAK GY · GETIDOSZAK · -TOL · -IG · AZ E-KERESKEDELEM ID · RENDBEN · MEXCEL · VISSZA A KEZD · Excelt · UJADATGYUJTO · ADATOK  · EREDMENYKIJELZES · -t · -ig · IRODA · NYIT · PAYSAFE · SZ · ST · 2011.02.01 · 2011.02.16 · KIL · EXCELT

## Eljárások / függvények (.pas)
`FormActivate`, `INDITOTimer`, `Sparancs`, `TUJADATGYUJTO.FormActivate`, `TUJADATGYUJTO.INDITOTimer`, `TUJadatGyujto.Sparancs`

## Érintett adatbázis-táblák
`SUMTRADE`

**SQL-műveletek (minta):**
- `DELETE FROM SUMTRADE`
- `SELECT * FROM`
- `WHERE (DATUM>=`
- `INSERT INTO SUMTRADE (ERTEKTAR,IRODASZAM,NYITO,MATRICA,TELEFON,`
- `SELECT * FROM SUMTRADE`
- `WHERE ERTEKTAR=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
