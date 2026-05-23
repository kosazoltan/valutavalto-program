# Legacy modul (ÉRTÉKTÁR): PILLALL

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/pillall/debug/unit2.pas` (11643 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/pillall/makedll/pillall.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`pillallasrutin`

## DFM form(ok) / képernyő
`TForm1`, `TPILLANATNYIFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · PILLANATNYIFORM · A PILLANATNYI P · BANKK ·  (bankk · VNEM · VALUTA NEVE · NYIT · PILLANATNYI  · KEZEL · VISSZA A F · 555 000 Ft · 55000 Ft

## Eljárások / függvények (.pas)
`EscapeGombClick`, `FormCreate`, `FormKeyDown`, `NyomtatoGombClick`, `AlapadatBeolvasas`, `PillNyomtatas`, `FormActivate`, `KEZDIJPRINTGOMBClick`, `Blokkfocimiro`, `Elokieg`, `FormKiir`, `TextKiiro`, `ForintForm`, `KozepreIr`, `regeneralorutin`, `TPillanatnyiForm.FormActivate`, `TPILLANATNYIFORM.ESCAPEGOMBClick`, `TPillanatnyiForm.PillNyomtatas`, `TPillanatnyiForm.NyomtatoGombClick`, `TPillanatnyiForm.FormKeyDown`, `TPillanatnyiForm.FormCreate`, `TPillanatnyiForm.KEZDIJPRINTGOMBClick`, `TPillanatnyiForm.AlapadatBeolvasas`, `TPillanatnyiForm.Blokkfocimiro`, `TPillanatnyiForm.FormKiir`, `TPillanatnyiForm.KozepreIr`, `TPillanatnyiForm.Elokieg`, `TPillanatnyiForm.ForintForm`, `TPillanatnyiForm.TextKiiro`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `KEZDIJDATA`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM ARFOLYAM`
- `WHERE ZARO<>0`
- `SELECT * FROM KEZDIJDATA`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
