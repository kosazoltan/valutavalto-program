# Legacy modul (VALUTA): IBVALTO

> Forrás (primer): `Anti/VALUTA/IBVALTO/UNIT1.PAS` (66909 karakter)
> VALUTA — FŐ PÉNZTÁR-KLIENS (IBVALTO.DPR, a 109 DLL-t betöltő alkalmazás-héj).

## Exportált API
_(nincs)_

## Eljárások / függvények
`AfaGombClick`, `AlapQrHivas`, `CimletCfgControl`, `ConfidGombClick`, `DisplayMaradtDarabok`, `DsoftlabelClick`, `ElolegGombClick`, `ETradeProgClick`, `F3TerminalGombClick`, `F4AFATablaGombClick`, `F7supervisorGombClick`, `F10AtadoLapGombClick`, `FomenuGombClick`, `FomenuGombEnter`, `FomenuGombExit`, `FormCreate`, `FutofenyGombClick`, `GetHardwareAdatok`, `Getprosadatok`, `HistoryGombClick`, `IRQRutin`, `ValutaParancs`, `IDOTIMERTimer`, `InditoTimerTimer`, `InnovaGombClick`, `KeszletGombClick`, `KilepoGombClick`, `KorlevelgombClick`, `MaiForgalomGombClick`, `MakeTradeTabla`, `MenuInditoTimerTimer`, `NewPhoneEditKeyDown`, `NewPhoneEditEnter`, `NewPhoneEditExit`, `NewPhoneOkeGombClick`, `NoNewPhoneGombClick`, `QrNapnyitas`, `PenztarTelefonPanelClick`, `PtarosBelepOtpbe`, `ReprintGombClick`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `HARDWARE`, `JELENLET`, `PENZTAR`, `PRINTCONTROL`, `QRPARAMS`, `VTEMP`

- `UPDATE HARDWARE SET ERTEKTAR=`
- `UPDATE HARDWARE SET LEZARTNAP=`
- `DELETE FROM VTEMP`
- `SELECT * FROM PENZTAR`
- `INSERT INTO VTEMP (KONVERZIO) VALUES (`
- `UPDATE HARDWARE SET MEGNYITOTTNAP=`
- `DELETE FROM JELENLET WHERE DATUM<>`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PRINTCONTROL`
- `DELETE FROM QRPARAMS`

## Felhasználói üzenetek
- A KÉPERNYÖ FELBONTÁSÁT ÁLLÍTSA 1024x768-RA !
- NINCSENEK MEGADVA A PÉNZTÁR ADATAI !
- NINCS TERRORLISTA !
- Lezáratlan napot észleltem. Rendezze le a zárását
- A nap már le van zárva, de újra beléphet
- Valami hiba van a napnyitásnál - nem lehet nyitni
- A MULT HÓNAP MÉG NINCS LEZÁRVA. KÉREM A ZÁRÁST ELVÉGEZNI !
- Dekád (napi könyvelés) nincs nyomtatva !
- Kezelési díj nincs kinyomtatva !
- Se dekád (napi könyvelés), se kezelési díj nincs kinyomtatva !
- A CIMLET KONFIGURÁCIÓS ÁLLOMÁNYÁT BEÁLLITOTTAM
- Pénztáros nem lépett ki ! Most kiléptetem

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
