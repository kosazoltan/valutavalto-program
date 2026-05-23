# Legacy modul (SZERVER-FEJLESZT): PERMIT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/permit/unit2.pas` (23724 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/permit/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TKONTROLFORM`

**Feliratok/gombok (Caption):** AZ ENGED · VALUTA: · TRANZAKCI · Ki az enged · KEZEL · MINDKETT · ENGED · 100 FT/ · Felez · Elenged · Cs · EUR · JUTAL · ENGEDELYEZOGOMB · KILEPOGOMB · KEDVEZM · ENGEDM · KIL · KONTROLFORM · Button1 · BARFPANEL · BKDIJPANEL · JARFPANEL · JKDIJPANEL

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `IrodakBetoltese`, `Nul3`, `PENZTARCOMBOChange`, `StartGombClick`, `IndatumTomb`, `InDnemTomb`, `NAPCOMBOChange`, `EGYNAPRADIOClick`, `TOTHORADIOClick`, `OSSZESRADIOClick`, `FILTERRADIOClick`, `OSSZVALRADIOClick`, `OSSZTRANZRADIOClick`, `JobbRacsOpen`, `EGYVALRADIOClick`, `DNEMCOMBOChange`, `EGYTRANZRADIOClick`, `TRANZCOMBOChange`, `ERADIOClick`, `URADIOClick`, `FRADIOClick`, `JRADIOClick`, `ONLYFEERADIOClick`, `FELEZESRADIOClick`, `ELENGEDESRADIOClick`, `CSOKKENTESRADIOClick`, `ONLYRATERADIOClick`, `Dekodolas`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE (STATUS=`
- `SELECT * FROM`
- `WHERE ENGEDMENYTIPUS>8`
- `WHERE (ENGEDMENYTIPUS>8) AND (DATUM=`
- `WHERE DATUM=`
- `WHERE`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS ADAT A KÉRT HÓNAPRÓL

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
