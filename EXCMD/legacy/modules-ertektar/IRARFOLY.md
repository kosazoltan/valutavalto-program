# Legacy modul (ÉRTÉKTÁR): IRARFOLY **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/irarfoly/debug/unit2.pas` (23063 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/irarfoly/makedll/irarfoly.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`irodaarfolyamrutin`

## DFM form(ok) / képernyő
`TForm1`, `TIRODAARFOLYAMOK`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · IRODAK ARFOLYAMAI · ALAP · VALUTA · NEMEK · ELSZ · FOLYAMOK · ELAD · 1. kedvezm · 2. kedvezm · 3. kedvezm · E21 · D21 · V21 · S21 · UV21 · US21 · BV21 · BS21 · EGYEDI · K1PANEL · K2PANEL · K3PANEL

## Eljárások / függvények (.pas)
`FormActivate`, `INDITOTIMERTimer`, `BitBtn1Click`, `EgyirodatValaszt`, `EgyarfolyamlapDisplay`, `dnemDekoder`, `Intdekodol`, `MASIRODAGOMBClick`, `NYOMTATOGOMBClick`, `TombBetoltes`, `GetPenztarszamok`, `GetAlapadatok`, `PT1Click`, `PT1MouseMove`, `Shape1MouseMove`, `TIRODAARFOLYAMOK.FormActivate`, `TIRODAARFOLYAMOK.INDITOTIMERTimer`, `TIRODAARFOLYAMOK.BitBtn1Click`, `TirodaArfolyamok.EgyirodatValaszt`, `TIrodaarfolyamok.EgyarfolyamlapDisplay`, `TIrodaarfolyamok.dnemDekoder`, `TIrodaarfolyamok.Intdekodol`, `TIRODAARFOLYAMOK.MASIRODAGOMBClick`, `TIRODAARFOLYAMOK.NYOMTATOGOMBClick`, `TirodaArfolyamok.GetPenztarszamok`, `TIrodaArfolyamok.TombBetoltes`, `TIRODAARFOLYAMOK.PT1Click`, `TIrodaArfolyamok.GetAlapAdatok`, `TIRODAARFOLYAMOK.PT1MouseMove`, `TIRODAARFOLYAMOK.Shape1MouseMove`

## Érintett adatbázis-táblák
`HARDWARE`, `IRODAK`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK WHERE (CLOSED<>`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBÁS PÉNZTÁRSZÁM !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
