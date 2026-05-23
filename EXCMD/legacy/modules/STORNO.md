# Legacy modul: STORNO

> Forrás (primer): `Anti/VALUTA/DLL/STORNO/MAKEDLL/Unit2.pas` (34972 karakter) · library: `DLL/STORNO/MAKEDLL/Storno.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`stornorutin`

## DFM form(ok) / képernyő
`TSTORNOFORM`

**Feliratok/gombok (Caption):** STORNOFORM · MAI BIZONYLAT STORN · Bizonylat: · keres · BIZONYLAT · Valuta v · Valuta elad · VISSZA A MEN · EZT A BIZONYLATOT STORN · UF143 · BIZTOSAN STORN · SZ · V143123456 · IGEN · NEM · EGY BIZONYLAT  · Bizonylatsz · Bizonylat  · Storn · Nyugtasz · STORN · A NAV BIZONYLAT RENDBEN KINYOMODOTT ? · RENDBEN KINYOMODOTT · NEM SIKER · KIS

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `BankKartyaRendezes`, `BizLista`, `BizonylatRacsDblClick`, `EllenTranzakcio`, `ErClick`, `Ervenytelenites`, `FixFizetendo`, `FormActivate`, `FormKeyPress`, `FrClick`, `GongyoletVissza`, `IgenGombClick`, `IndokEditKeyDown`, `KilepoTimer`, `KivalasztottBeolvasas`, `KisUgyfelStorno`, `MegsemGombClick`, `NemGombClick`, `RadiokClick`, `StartGombClick`, `StornoGombClick`, `SureStorno`, `UrClick`, `ValutaParancs`, `ValutaStorno`, `VisszaGombClick`, `VrClick`, `FtForm`, `Nulele`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `BLOKKTETEL`, `HARDWARE`, `JOGISZEMELY`, `PENZTAR`, `QRPARAMS`, `UGYFEL`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `SELECT* FROM PENZTAR`
- `SELECT* FROM HARDWARE`
- `SELECT * FROM BLOKKFEJ`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM UGYFEL`
- `SELECT * FROM JOGISZEMELY`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM BLOKKTETEL`
- `WHERE (FIZETOESZKOZ=2) AND (STORNO=1)`
- `DELETE FROM QRPARAMS`
- `INSERT INTO QRPARAMS (VALUTANEM,BANKJEGY)`

## Felhasználói üzenetek (üzleti szabály-jelek)
- SIKERTELEN OTP-STORNÓ ! Stornó nem kehetséges

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
