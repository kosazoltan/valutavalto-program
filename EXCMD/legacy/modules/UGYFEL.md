# Legacy modul: UGYFEL

> Forrás (primer): `Anti/VALUTA/DLL/UGYFEL/MAKEDLL/Unit2.pas` (109921 karakter) · library: `DLL/UGYFEL/MAKEDLL/Ugyfel.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`ugyfelrutin`

## DFM form(ok) / képernyő
`TUGYFELINPUT`

**Feliratok/gombok (Caption):** GETUGYFEL · Le · Anyja neve: · Sz · Okm · List · Kiemelt · F5 · Ir · Utca - h · Lakc · Az  · Tartozkod ·  K · HU · TERM · Nem kiemelt k ·  Belf · Jogi szem · Okirat · Megbizott neve: · Megbizott beosz · JOGI SZEM ·   TULAJDONOSOK   · Ad

## Eljárások / függvények (.pas)
`AlapraAllitas`, `KPolgarGombClick`, `AzonositoGombClick`, `PolgarGombClick`, `BelGombClick`, `BelRadioClick`, `EditBeolvasas`, `FillTulNevEdits`, `FillJogiEdits`, `FillNaturedits`, `FinalRegistration`, `FormActivate`, `FormCreate`, `GetJogiData`, `GetJogiDataFromEdits`, `GetJogiDataFromDbase`, `GetMegbizo`, `GetMegbizott`, `GetnaturData`, `GetNaturDataFromdbase`, `GetNaturDAtafromEdits`, `Getorszagkod`, `GetTeaorszam`, `GetTulajDataFromedits`, `GombClear`, `IgenAzonositGombClick`, `IrszamEditChange`, `JogiAdatOkeGombClick`, `JogiGombClick`, `JogiListaGombclick`

## Érintett adatbázis-táblák
`HARDWARE`, `JOGISZEMELY`, `PARTNERPARA`, `TEAORTABLA`, `UGYFEL`, `UJTULAJOK`, `UTOLSOBLOKKOK`, `VTEMP`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET SECURLEVEL=`
- `UPDATE VTEMP SET SECURLEVEL=1`
- `UPDATE VTEMP SET KULFOLDI=`
- `UPDATE JOGISZEMELY SET TEAOR=`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM UGYFEL WHERE UGYFELSZAM=`
- `UPDATE VTEMP SET MEGJEGYZES=`
- `SELECT * FROM VTEMP`
- `SELECT * FROM UJTULAJOK WHERE UGYFELSZAM=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM UGYFEL`
- `WHERE (TOROLVE=1) AND (KULFOLDI=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- LEGALÁBB EGY TULAJDONOSNAK KELL LENNIE
- MÉG NINCS KIJELÖLVE A MEGBIZOTT SZEMÉLY
- A MEGBIZOTT ADATAI RENDBEN ?

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
