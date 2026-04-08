# Bence — Modern Szoftver Üzleti Logika Elemzés
**Dátum:** 2026-04-07
**Elemző:** Bence (SecOps)
**Scope:** `D:\repo\valutavalto-program\` — Java Spring Boot backend + React frontend + Electron pénztár kliens
**Production:** https://excvaluta.com

---

## ÖSSZEFOGLALÓ

A modern rendszer alaparchitektúrája érett és jól strukturált. A core tranzakciókezelés (vétel/eladás/sztornó), AML, NAV zárás, árfolyam-menedzsment, foglalások és a legtöbb riport modul üzletileg helyes. Azonban **6 kritikus hiányosság**, **4 befejezetlen fejlesztés** és **több kisebb logikai gép** azonosítható, amelyek production kockázatot hordoznak.

---

## 1. KRITIKUS HIÁNYOSSÁGOK (production kockázat)

### 1.1 BackupService — Fake pg_dump (KRITIKUS)
**Fájl:** `BackupService.java:70`
**Probléma:** A mentés nem futtat valódi `pg_dump`-ot. Csak egy placeholder `.sql` fájlt ír (`-- Backup: UUID...`). A restore sem tölt be semmit.
```java
// Szimulált mentés — valós környezetben pg_dump futtatás
String content = String.format("-- Backup: %s\n-- Típus: %s...", ...);
Files.writeString(targetPath, content);
```
**Kockázat:** Adatvesztés — az adminok azt hiszik van mentés, de nincs. Production incidens esetén nincs visszaállás.

### 1.2 ArchivingService — Stub végrehajtás (KRITIKUS)
**Fájl:** `ArchivingService.java:52`
**Probléma:** Az archiválási logika teljesen hiányzik. A `executeTask()` státuszt vált `RUNNING → COMPLETED`, de tényleges adatmozgatás, tömörítés, exportálás NEM történik.
```java
// Placeholder: tényleges archiválás később
task.setArchiveLocation("archive/" + task.getEntityType() + "/" + taskId);
```
**Kockázat:** Az adatbázis folyamatosan növekszik, az archivált adatok soha nem kerülnek más tárolóba. Téves sikerstátusz.

### 1.3 POS Terminál — Borgun és Worldline drivers hiányoznak (KRITIKUS)
**Fájl:** `PosTerminalService.java:412,426`
**Probléma:** A Borgun és Worldline POS driver valódi implementáció helyett file-bridge artifaktot ír ki. Mindkettő `TODO: éles driver` megjegyzéssel.
```java
// ============ BORGUN IMPLEMENTÁCIÓ (TODO: éles driver) ============
// ... bridge artifact file írás, APPROVED-ot ad vissza mindig
```
**Kockázat:** Ha ezek a terminálok production irodán vannak konfigurálva, minden bankkártyás tranzakció sikeres lesz fakén — pénzügyi veszteség.

### 1.4 NAV Integráció — Bridge mód (file artifact) nem valódi COM kommunikáció
**Fájl:** `NavIntegrationService.java`
**Probléma:** A NAV pénztárgép integráció nem valódi serial/COM kommunikációt folytat. Csak JSON fájlokat ír egy `nav-integration/{comPort}` mappába. A `receiveReceiptNumber()` UUID-alapú fake számot generál.
```java
String receipt = "REC-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
```
**Kockázat:** A NAV pénztárgép nem kap valós adatot → adóhatósági megfelelőségi probléma. Az irodák tévesen azt hiszik, a NAV-ba ment az adat.

### 1.5 AML Munkaszüneti napok kezelése hiányzik
**Fájl:** `AmlService.java:646`
**Probléma:** A göngyölési ablakszámításnál a magyar munkaszüneti napok nincsenek figyelembe véve. A rendszer naptári napokkal számol, nem munkanapokkal.
```java
// TODO: Magyar munkaszüneti napok kezelése (március 15., nagypéntek, stb.)
```
**Kockázat:** Egyes AML határidők hibásan számolódnak a hatóság felé.

### 1.6 Notification — Email/push értesítések nincsenek bekötve
**Fájlok:** `ClosingControlService.java:75`, `NavClosingDiscrepancyService.java:159`
**Probléma:** Két kritikus ponton (zárási eltérés, NAV eltérés) az értesítési logika üres komment:
```java
// TODO(notification): Email/push notification küldés az irodának — NotificationService integráció szükséges
// TODO: Valódi email/push notification küldése
```
**Kockázat:** Az operátorok nem értesülnek az eltérésekről, ha nem néznek manuálisan a rendszerbe.

---

## 2. BEFEJEZETLEN FEJLESZTÉSEK

### 2.1 DailyReportService — Kezelési díj nyitó egyenleg hardkódolt nulla
**Fájl:** `DailyReportService.java:360`
```java
.handlingFeeOpening(BigDecimal.ZERO) // TODO: kezelési díj subledger snapshot-ból
```
**Hatás:** A napi kezelési díj nyitó egyenleg mindig 0 jelenik meg a riportban, még ha volt is előző nap átvitt egyenleg.

### 2.2 WorkerCommissionPage — CSV export nincs implementálva
**Fájl:** `frontend-react/.../WorkerCommissionPage.tsx:66`
```tsx
// TODO: Implement CSV export
```
**Hatás:** A pénztáros jutalék riport nem exportálható CSV-be, manuális munkát igényel.

### 2.3 CameraPlaybackPage — Branch selector statikus
**Fájl:** `frontend-react/.../CameraPlaybackPage.tsx:52`
```tsx
branchId: '', // TODO: branch selector
```
**Hatás:** A kamera visszajátszás branch-szelektor nem működik — minden lekérés üres branchId-val megy.

### 2.4 StornoPage — Pending approval betöltése hiányzik
**Fájl:** `frontend-react/.../StornoPage.tsx:52`
```tsx
// TODO: betölteni a pending approval-t
```
**Hatás:** A frontend nem tölt be várakozó sztornó-jóváhagyásokat, az operátorok kézzel kell navigáljanak.

---

## 3. ÜZLETI LOGIKAI HIÁNYOSSÁGOK

### 3.1 WesternUnion CUSTOMER_IN / CUSTOMER_OUT típusok nincsenek implementálva
**Fájl:** `WesternUnionService.java`
**Probléma:** A napi riportban `CUSTOMER_IN` és `CUSTOMER_OUT` típusonként csak számlálás van, de nincs `recordCustomerIn()` / `recordCustomerOut()` metódus. Ezeket rögzíteni nem lehet az API-n keresztül.
**Hatás:** Hiányos WU nyilvántartás — a customer irányú tranzakciók nem kerülnek be.

### 3.2 WesternUnion — AML nem fut IC tranzakciókon
**Fájl:** `WesternUnionService.java:recordIcIn()/recordIcOut()`
**Probléma:** Az IC_IN és IC_OUT (irodák közötti) mozgásokon nincs AML ellenőrzés. Csak SEND/RECEIVE kapja.
**Kockázat:** Nagy összegű belső átcsoportosítás AML-filter nélkül mehet át.

### 3.3 Foglalás (Reservation) — EBC sztornó dupla visszafizetés nincs kassza-szinten ellenőrizve
**Fájl:** `ReservationService.java`
**Probléma:** Az EBC stornó esetén (`_visszatipus=3`) a dupla visszafizetés (2 × deposit) megy, de a kassza egyenleg-ellenőrzés csak az eredeti összegre végez `validateCurrencyStock` jellegű ellenőrzést.
**Kockázat:** Ha a kassza nem tartalmaz elegendő HUF-ot a dupla visszafizetéshez, az exception csak futásidőben jön.

### 3.4 Trade service — cross-tenant nincsen teljes mértékben leellenőrizve
**Fájl:** `TradeService.java:proposeTrade()`
**Probléma:** A `validateTradeProposalAccess` ellenőrzi a from/to branch ownership-et, de ha két különböző cég irodái szerepelnek egy trade-ben (pl. üzemeltetési hiba esetén), az üzlet rögzítésre kerülhet.
**Hatás:** Potenciális inter-company data exposure tranzakciókon keresztül.

### 3.5 HRK nettó negatív egyenleg csak WARNING, nem BLOCK
**Fájl:** `HrkMonthlyClosingService.java`
**Probléma:** Ha a havi HRK nettó negatív (több ment bankba mint jött), a rendszer csak `log.warn()`-t ír, nem blokkolja a zárást.
**Hatás:** Könyvelési eltérés hallgatólagosan átengedve.

### 3.6 VatRefund sorszám generálás — `System.nanoTime() % 100000` ütközésveszély
**Fájl:** `VatRefundService.java:generateSerialNumber()`
```java
return type.name() + "-" + datePart + "-" + System.nanoTime() % 100000;
```
**Probléma:** Azonos ezredmásodpercen belül két párhuzamos kérés ugyanolyan sorszámot generálhat.
**Hatás:** Duplikált bizonylat-sorszám → NAV ütközés lehetséges.

### 3.7 Storno limits — Iroda szinten 3, pénztáros szinten 2, de nincs szuper-visor bypass log
**Fájl:** `StornoService.java`
**Probléma:** Ha supervisort kérnek le, nincs audit trail arról, ki engedélyezte és milyen jogosultsággal. A jóváhagyás csak `StornoApproval` entitásba kerül, de a supervisor azonosítója nem kötődik a végső tranzakcióhoz.
**Kockázat:** Ellenőrzési hézag — audit loggal nem visszakövethető a supervisor jóváhagyó.

---

## 4. ARCHITEKTÚRÁLIS MEGFIGYELÉSEK

### 4.1 Electron pénztár kliens — `sql.js` in-memory DB, nem WAL SQLite
**Fájl:** `penztar-client/electron/sqlite.ts`
**Probléma:** A `sql.js` WebAssembly SQLite memóriában fut, csak explicit `saveDatabase()` hívásnál menti fájlba. Ha az Electron folyamat váratlanul leáll (crash), az utolsó `saveDatabase()` óta rögzített pending tranzakciók elvesznek.
**Kockázat:** Offline tranzakcióvesztés, ami aztán szinkronizáláskor hiányos.

### 4.2 Sync engine — 30s polling, nincs retry backoff
**Fájl:** `penztar-client/electron/sync-engine.ts`
**Probléma:** A szinkronizáció fix 30 másodpercenként fut. Hálózati hiba esetén nincs exponential backoff — azonnal újrapróbál.
**Hatás:** Hálózati problémánál az Electron kliens felesleges kéréseket küld.

### 4.3 LicenseService — nincs futásidejű license enforcement tranzakciókon
**Fájl:** `LicenseService.java`
**Probléma:** A licenc-ellenőrzés GET endpoint-on lekérdezhető, de a `TransactionService.executeBuy/Sell()` nem hívja meg. Lejárt licenccel is indítható tranzakció.
**Kockázat:** License bypass — lejárt licenc esetén a rendszer nem blokkol.

### 4.4 NAV Zárás — ÁFA számítás csak kezelési díjra, nem tranzakció típusonként
**Fájl:** `NavClosingService.java`
**Probléma:** A 27%-os ÁFA kizárólag a kezelési díjra van kalkulálva. Egyes tranzakció típusok (pl. ÁFA visszatérítés — `VatRefundTransaction`) külön ÁFA kezelést igényelnek, de ezek nem kerülnek be a NAV zárásba.

---

## 5. HIÁNYZÓ FUNKCIÓK (backend endpoint létezik, frontend/integráció hiányzik)

| Funkció | Backend | Frontend / Integráció |
|---|---|---|
| Valódi pg_dump backup | Stub | - |
| Archiválás végrehajtás | Stub | - |
| Borgun POS driver | Bridge artifact | - |
| Worldline POS driver | Bridge artifact | - |
| NAV pénztárgép COM kommunikáció | Bridge artifact | - |
| WU CUSTOMER_IN/OUT rögzítés | Hiányzó service metódus | - |
| Kamera playback branch selector | - | TODO komment |
| Storno pending approval betöltés | OK | TODO komment |
| Worker commission CSV export | OK | TODO komment |
| AML notification értesítés | TODO komment | - |
| Closing control notification | TODO komment | - |

---

## 6. PRIORITIZÁLT JAVÍTÁSI LISTA

| Prioritás | Tétel | Indok |
|---|---|---|
| P0 | BackupService valódi pg_dump | Adatvesztés kockázat |
| P0 | POS Borgun/Worldline driver tisztázás | Pénzügyi veszteség kockázat |
| P0 | NAV integráció tényleges COM implementálás | Adóhatósági megfelelőség |
| P1 | ArchivingService implementálás | DB növekedés |
| P1 | LicenseService enforcement TransactionService-ben | License bypass |
| P1 | VatRefund sorszám UUID/sequence alapra cserélés | Duplikált bizonylat kockázat |
| P1 | AML és Closing notification implementálás | Operatív vakság |
| P2 | WU CUSTOMER_IN/OUT metódusok | Hiányos nyilvántartás |
| P2 | WU IC AML ellenőrzés | Belső mozgások monitorizálása |
| P2 | HRK negatív nettó blokkolás | Könyvelési konzisztencia |
| P2 | Storno supervisor audit trail | Ellenőrzési hézag |
| P3 | Electron crash-safe SQLite (WAL mode) | Adatvesztés offline módban |
| P3 | Sync engine exponential backoff | Hálózati overhead |
| P3 | Frontend TODO-k (branch selector, storno, commission export) | UX hiányosság |

---

## ELFOGADÁSI KRITÉRIUM TELJESÍTVE

Fájl mentve: `D:\openclaw\.openclaw\workspace\shared\reviews\bence-modern-uzleti-logika-elemzes-2026-04-07.md`

**Elemzett fájlok:**
- `backend/src/main/java/hu/puzzleir/valuta/service/` — teljes service réteg (~120 service class)
- `backend/src/main/java/hu/puzzleir/valuta/controller/` — ~120 controller class áttekintve
- `frontend-react/src/` — pages, components áttekintve
- `penztar-client/electron/` — sync-engine.ts, sqlite.ts, main.ts áttekintve
