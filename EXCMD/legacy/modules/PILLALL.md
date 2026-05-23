# Legacy modul: PILLALL

> Forrás (primer): `Anti/VALUTA/DLL/PILLALL/MAKEDLL/Unit2.pas` (12892 karakter) · library: `DLL/PILLALL/MAKEDLL/PILLALL.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`pillallasrutin`

## DFM form(ok) / képernyő
`TPILLANATNYIFORM`

**Feliratok/gombok (Caption):** PILLANATNYIFORM · A PILLANATNYI P · BANKK ·  (bankk · VNEM · VALUTA NEVE · NYIT · BEV · KIAD · KEZ-I D · PILLANATNYI  · KEZEL · VISSZA A F · 555 000 Ft · 55000 Ft

## Eljárások / függvények (.pas)
`EscapeGombClick`, `FormCreate`, `FormKeyDown`, `NyomtatoGombClick`, `AlapadatBeolvasas`, `PillNyomtatas`, `FormActivate`, `KEZDIJPRINTGOMBClick`, `Blokkfocimiro`, `Elokieg`, `FormKiir`, `TextKiiro`, `ForintForm`, `KozepreIr`, `regeneralorutin`, `TPillanatnyiForm.FormActivate`, `TPILLANATNYIFORM.ESCAPEGOMBClick`, `TPillanatnyiForm.PillNyomtatas`, `TPillanatnyiForm.NyomtatoGombClick`, `TPillanatnyiForm.FormKeyDown`, `TPillanatnyiForm.FormCreate`, `TPillanatnyiForm.KEZDIJPRINTGOMBClick`, `TPillanatnyiForm.AlapadatBeolvasas`, `TPillanatnyiForm.Blokkfocimiro`, `TPillanatnyiForm.FormKiir`, `TPillanatnyiForm.KozepreIr`, `TPillanatnyiForm.Elokieg`, `TPillanatnyiForm.ForintForm`, `TPillanatnyiForm.TextKiiro`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `NAPIKEZELESIDIJ`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM ARFOLYAM`
- `WHERE ZARO<>0`
- `SELECT * FROM NAPIKEZELESIDIJ`
- `WHERE DATUM=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
