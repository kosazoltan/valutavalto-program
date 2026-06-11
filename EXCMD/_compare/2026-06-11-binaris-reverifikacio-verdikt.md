# Anti/forrasok bináris re-verifikáció — verdikt (2026-06-11, 4. kör)

**Mandátum:** a 2026-06-10-es ledger-verdikt nyitott tétele — a legacy binárisok (EXE/DLL)
bájthelyes elemzése és a kinyert funkciókészlet összevetése a mai ERP-vel; a hibásan
implementált vagy el sem készített részek felderítése.

## Módszer és lefedettség

1. **Bináris-elemzés a teljes lokális Anti-fán** (`scripts/legacy-binary-analyzer.py`):
   2 157 Delphi bináris → **287 egyedi TPF0 form-osztály**. Riport:
   `docs/legacy-analysis/generated/legacy-binary-analysis.{json,md}`.
2. **Determinisztikus zaj-szűrés** (`scripts/dev-tools/legacy-form-triage.py` — új,
   újrafuttatható dev-tool): 12 már leképezett-implementált + 10 dev/teszt-zaj
   (csak debug/próba útvonalon élő vagy generikus nevű form) → **265 érdemi form,
   104 modulban**. Riport: `docs/legacy-analysis/generated/legacy-form-triage.md`.
3. **3 párhuzamos felderítő ügynök** modul-szeletekkel (FIREBIRD/SERVER-infra;
   CAMERA/TRADE/HELGA/ERTEKTAR/RECPTOR; maradék kis modulok), kötelező bizonyítási
   teherrel: GAP-állítás csak legalább 3 különböző keresőkifejezéses negatív kereséssel.
4. **Kézi szúrópróba a COVERED-állításokon** (a 3. kör hamis-negatív tanulsága miatt a
   hamis-pozitív lefedettség ellen): 9/9 hivatkozott osztály létezik
   (ReservationService, InventoryRegenerationService, CommissionRateController,
   BankTurnoverPage, CameraExportService, WacService, RateDiscount,
   BookingExportService, StockSnapshotExcelService).

## Eredmény: 0 valódi funkcionális gap

A 265 érdemi form mindegyike két kategória egyikébe esett:

### COVERED (~165 form) — a mai ERP fedi, file-szintű bizonyítékkal

Minden üzleti pillér-funkció megvan: tranzakciók (vétel/eladás/konverzió/sztornó),
zárások (napi/havi/esti + hiányzó-zárás alert), cimletezés (teljes lánc: bevitel,
lista, menü, nyomtatás, kalkulátor), készlet (pillanatkép, regeneráló, beküldő),
átadás-átvétel + átadólap, MNB-jelentés (gyűjtő, lista, NIF), jutalék (számítás,
százalék, szorzó), körlevelek (archívum, visszaigazolás, VIP-szűrés), WU + WAFA
kontroll, súlyozott átlagárfolyam (WacService), árfolyam-eltérítés/kedvezmény
(RateDiscount), ügyfél-adatlap (AML-mezőkkel), foglaló, dolgozó-törzs,
pénztár-törzs, terrorlista-szűrés, napi könyv/könyvelési export.

### INFRA (~100 form) — a mai architektúrában értelmetlen vagy 3rd-party

- **FIREBIRD (51): az `IBConsole.exe`** — a Firebird/InterBase adatbázis-motor
  gyári admin-eszköze, sosem volt a valutaváltó saját üzleti kódja. PostgreSQL váltotta.
- **CAMERA (17):** analóg kamera-lejátszó + QuickReport/Raize 3rd-party UI + F1355
  hardver-konfig — a kamera-linkelés érdemi részét a `CameraExportService` fedi.
- **Halott vertikumok (5):** útdíjmatrica-értékesítés (TAUTOPALYAFORM + megye-térkép),
  mobiltelefon-feltöltés (Telenor/Vodafone), PaySafe-kártya — az 5 pillér scope-on
  kívül, üzletileg megszűnt termékvonalak.
- **Legacy-infra:** altib.exe IB-táblakarbantartó (5), Firebird gbak-backup, FTP
  cert-szinkron (2), IE-alapú beépített böngésző, verzió-frissítő, Excel-COM
  segédeszközök, Tesco/Metro/MoneyGram/OTP-terminál partner-illesztők.

## Megbízhatósági jegyzet

- Az ügynökök 3 saját GAP-jelöltjüket maguk vonták vissza bizonyíték alapján
  (THASZONFELVIVOFORM→ProfitPage; TMATPENZTAR→INFRA; TXTRANZFORM→INFRA) — a
  kötelező bizonyítási teher működött.
- A korábbi (3. kör) hamis-negatív minta ellen a kézi szúrópróba az ELLENKEZŐ
  irányt (hamis COVERED) ellenőrizte: 9/9 találat.

## Konklúzió

A ledger utolsó nyitott input-függő tétele zárva: **a legacy binárisokból nem került
elő implementálatlan üzleti funkció**. A funkcionális paritás a binárisok szintjén is
igazolt; a maradék eltérések tudatos architektúra-döntések (PostgreSQL, IP-kamera,
webes/Electron UI) vagy megszűnt termékvonalak.

> Újrafuttatás: `python scripts/legacy-binary-analyzer.py --anti-root Anti` majd
> `python scripts/dev-tools/legacy-form-triage.py` (a forrást birtokló gépen).
