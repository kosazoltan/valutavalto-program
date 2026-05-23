# Legacy modul: KISUGYFEL

> Forrás (primer): `Anti/VALUTA/DLL/KISUGYFEL/MAKEDLL/Unit2.pas` (28418 karakter) · library: `DLL/KISUGYFEL/MAKEDLL/KISUGYFEL.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kisugyfelrutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · 300.000 FORINT ALATTI KIS · AZ  · SZ · ADATOK RENDBEN · KERES · NEM KELL AZONOSITANI · INDOKA: · UTOLS · MOSTANI V · TOV

## Eljárások / függvények (.pas)
`FormActivate`, `KilepoTimer`, `KugyMegsemGombClick`, `KugyOkeGombClick`, `KugyRacsDblClick`, `KugyRacsCellClick`, `KugyRacsKeyUp`, `ListaGombClick`, `LocalParancs`, `NevEditEnter`, `NevEditExit`, `NevEditKeyDown`, `NoChooseGOMBClick`, `ParameterBeolvasas`, `RemoteInsert`, `Remoteparancs`, `SaveLocalUgyfel`, `UpdateVtemp`, `UgyfelKiertekeles`, `UgyfeletValasztott`, `VtempAlapraAllitas`, `Angolra`, `Datumctrl`, `DoubleKill`, `Getnapdiff`, `Hunstrtodate`, `HutoGb`, `Tomorito`, `Ftform`, `TOVABBGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`, `LASTNUM`, `UGYFEL`, `UTOLSOBLOKKOK`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE NEV LIKE`
- `SELECT * FROM LASTNUM`
- `UPDATE LASTNUM SET`
- `INSERT INTO`
- `SELECT* FROM UGYFEL`
- `WHERE TOROLVE=1`
- `SELECT * FROM UGYFEL`
- `SELECT * FROM UTOLSOBLOKKOK`
- `UPDATE UTOLSOBLOKKOK SET UTOLSOUGYFELSZAM=`
- `INSERT INTO UGYFEL (UGYFELSZAM,NEV,SZULETESIHELY,SZULETESIIDO,`
- `UPDATE VTEMP SET UGYFELTIPUS=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
