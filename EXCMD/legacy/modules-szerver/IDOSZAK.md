# Legacy modul (SZERVER): IDOSZAK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/idoszak/debug/unit2.pas` (5596 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/idoszak/makedll/idoszak.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getidoszakrutin`

## DFM form(ok) / képernyő
`TForm1`, `TIDOSZAKBEFORM`

**Feliratok/gombok (Caption):** Form1 · KIL · BitBtn2 · Panel1 · IDOSZAKBEFORM · -T · -IG · ID

## Eljárások / függvények (.pas)
`IDSZOKEGOMBClick`, `IDSZCANCELGOMBClick`, `FormActivate`, `AParancs`, `EVCOMBOChange`, `TOLCOMBOChange`, `IGCOMBOChange`, `TIDOSZAKBEFORM.FormActivate`, `TIdoszakBeForm.AParancs`, `TIdoszakBeForm.IdszOkeGombClick`, `TIDOSZAKBEFORM.IDSZCANCELGOMBClick`, `TIDOSZAKBEFORM.EVCOMBOChange`, `TIDOSZAKBEFORM.TOLCOMBOChange`, `TIDOSZAKBEFORM.IGCOMBOChange`

## Érintett adatbázis-táblák
`IDOSZAK`

**SQL-műveletek (minta):**
- `DELETE FROM IDOSZAK`
- `INSERT INTO IDOSZAK (STARTDATE,ENDDATE)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
