# Legacy modul: FNYUJSAG

> Forrás (primer): `Anti/VALUTA/DLL/FNYUJSAG/UJTIPUS/MAKEDLL/Unit2.pas` (17211 karakter) · library: `DLL/FNYUJSAG/ALAP/MAKEDLL/Fnyujsag.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`fenyujsagfrissito`

## DFM form(ok) / képernyő
`TFnyujsag`

**Feliratok/gombok (Caption):** Form1 · CSAK SZ · Adatok kik

## Eljárások / függvények (.pas)
`ArfolyamBeolvasas`, `Arfnyitas`, `ArfolyamFileFeliras`, `TextFileFeliras`, `CloseComport`, `sendByteFile`, `Arfform`, `EzdoublePenztar`, `ValsorBeiro`, `FormActivate`, `InditoTimer`, `KILEPOTimer`, `TFnyujsag.FormActivate`, `TFnyujsag.INDITOTimer`, `TFnyUjsag.Arfolyambeolvasas`, `TFnyujsag.ArfolyamFileFelIras`, `TFnyujsag.TextFileFelIras`, `TFnyujsag.ValsorBeiro`, `TFnyujsag.sendByteFile`, `TFnyujsag.CloseCOMPort`, `TFnyUjsag.KILEPOTimer`, `TFnyUjsag.EzdoublePenztar`, `TFnyujsag.arfform`, `TFnyujsag.Arfnyitas`, `TFnyujsag.Szovegkikuldo`, `TFnyujsag.TextFileIras`, `TFnyujsag.SendText`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `MEDIA`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM MEDIA`
- `SELECT * FROM ARFOLYAM WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nem sikerült megnyitni a 
- Nem sikerült beállítani a 

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
