# Legacy modul (SZERVER-FEJLESZT): KORLEVEL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/korlevel/zsuzsa/unit1.pas` (57610 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/korlevel/zsuzsa/korlevel.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `Tsuperform`, `TREADTIMEFORM`, `TGETVIPFORM`, `TARCHIVEFORM`, `TGETIDKOD`, `TLASTYEARFORM`

**Feliratok/gombok (Caption):** dek@nySoft · Verzi · Kiv · ____________________ · JELSZ · imagepanel · WWW · EGY K · KIV · KIL · SUPERVISORI MEN · IKTAT · A 2016  · VISSZA A MEN · A K · MOMENT .... · E-mailek sz · Valutav · Arhiv · Vissza a f · CHANGE · EXPRESSZ · VIP · Archive levelek olvas · AZ AL

## Eljárások / függvények (.pas)
`ArchiveGombClick`, `ArChangeGombClick`, `ArExpresszGombClick`, `ArVIPGombClick`, `ArExitGombClick`, `LastYearGombClick`, `DirMake`, `DolgozokTombbe`, `FormActivate`, `JelszoEditKeyDown`, `KijeloloGombClick`, `KilepoGombClick`, `KilepoTimer`, `ListaBackGombClick`, `ListazoGombClick`, `LyEXITGombClick`, `LyVIPGombClick`, `LYExpresszGombClick`, `LYChangeGombClick`, `MenuBe`, `Makexml`, `OlvasasRegisztracio`, `OlvasasRutin`, `OlvasogombClick`, `P1MouseMove`, `Paracontrol`, `ReadGombClick`, `RemoveTiltott`, `ServerParancs`, `SetRemotefile`

## Érintett adatbázis-táblák
`ADATOK`, `ADDRESS`, `PENZTAROSOK`, `TILTOTT`, `VIPLEVEL`, `ZALOGLEVEL`

**SQL-műveletek (minta):**
- `SELECT * FROM ADATOK`
- `INSERT INTO`
- `UPDATE ADATOK SET`
- `SELECT * FROM`
- `WHERE STORNO<2`
- `SELECT * FROM PENZTAROSOK`
- `SELECT * FROM VIPLEVEL`
- `WHERE (DOLGSORSZAM=`
- `SELECT * FROM TILTOTT`
- `INSERT INTO ZALOGLEVEL (IKTATOSZAM,DATUM,TARTALOM,`
- `UPDATE ADATOK SET UTZALOGSORSZAM=`
- `SELECT * FROM ADDRESS WHERE SORSZAM>1`

## Felhasználói üzenetek (üzleti szabály-jelek)
- SIKERTELEN SZÉTKÜLDES
- NINCS INTERNET !
- Nem találom a WININET.DLL könyvtárt !
- Központi szerver nem érhető el !
- Nem tud belépni a könyvtárba !
- Nem tud belépni a 
- Nem tud belépni a ZALOGLEVEL könyvtárba !
- TELEPITENI KELL A LIBREOFFICE ALKALMAZÁST !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
