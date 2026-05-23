# Legacy modul (SZERVER-FEJLESZT): TERROR

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/terror/maketerrlist/unit1.pas` (9855 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/terror/maketerrlist/terror.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · AZ ENSZ TERRORLIST · LET · IDE KATTINS · ADATB · Kis t · KIL · XML K

## Eljárások / függvények (.pas)
`FormActivate`, `StartGombClick`, `TParancs`, `XmlMaking`, `FDBMaking`, `MakeRutin`, `KilepoGombClick`, `Betukiemelo`, `XMLGOMBClick`, `WebBrowser1DocumentComplete`, `TForm1.FormActivate`, `TForm1.StartGombClick`, `TForm1.XmlMaking`, `TForm1.MakeRutin`, `TForm1.FdbMaking`, `TForm1.Tparancs`, `TForm1.WebBrowser1ProgressChange`, `TForm1.WebBrowser1PropertyChange`, `TForm1.KILEPOGOMBClick`, `TForm1.XMLGOMBClick`, `TForm1.WebBrowser1DocumentComplete`, `TForm1.Betukiemelo`

## Érintett adatbázis-táblák
`UNOLIST`

**SQL-műveletek (minta):**
- `DELETE FROM UNOLIST`
- `INSERT INTO UNOLIST (TERROR_NAME)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
