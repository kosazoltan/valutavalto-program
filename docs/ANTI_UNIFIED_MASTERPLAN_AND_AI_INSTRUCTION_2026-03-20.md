# Valutaváltó ERP modernizáció — egységes masterterv + AI végrehajtási utasítás

Dátum: 2026-03-20
Állapot: Végrehajtásra kész (kódszintű legacy bizonyítékokra építve)

## 1. Cél és keret

Egy biztonságos, offline-first, multi-branch valutaváltó rendszer megvalósítása, amely:
- helyben rögzíti a kameraképet,
- legalább 50 napig megőrzi a bizonyítékot,
- jogosultság szerint biztosít visszajátszást/exportot,
- internetkimaradás esetén is üzembiztos,
- központi PostgreSQL-be szinkronizál,
- támogatja a napi/havi treasury riportokat,
- Darius/Raiffeisen napi riport kötelezettséget kezeli,
- kb. 50 iroda skálán stabilan működik.

## 2. Forrás-bizonyíték összefoglaló (reverse engineering)

### Kamera (legacy)
- camera2 és camera3 ágon egyaránt látható 50 napos retention logika.
- Kamerafájl szegmens jelölések: `.C1` (public/pénztári), `.C2` (private/intim).
- Export folyamat: dátumtartomány + opcionális lejátszó másolás.
- Supervisor/jogosultsági feloldó folyamat külön modellben.
- Kamera3 auth szerepkörök közt szerepel területi vezető és kamera ellenőr.

### Treasury / riport / zárás (legacy VALUTA DLL)
- NAPIJEL: napi jelentés és jelszó-élettartam logika.
- NAPZAR: napzárási ellenőrzés és kapcsolt riportműveletek.
- ATADVET: pénztár-értéktár átadás/átvétel, storno/plomba nyomok.
- KORLEV: körlevél és FTP-alapú üzenet/disztribúciós logika.

### Darius / Raiffeisen
- Legacy dokumentáció alapján napi tranzakciós beküldési és havi elszámolási kötelezettség fennáll.
- Technikai nyom: darius.fdb adatforrás.

## 3. Kötelező döntési pont (ellentmondás feloldása)

Meglévő repo állapotfájlban szerepel, hogy Darius integráció nem kell, viszont aktuális üzleti követelmény szerint kötelező a napi Darius/Raiffeisen riport.

Kötelező governance döntés (Go/No-Go):
- GO: Darius integráció és riport modul kötelező scope.
- NO-GO: csak akkor vehető ki, ha írásos business waiver készül és jóváhagyott.

Alapértelmezett ebben a tervben: GO.

## 4. Célarchitektúra (ajánlott)

### 4.1 Szolgáltatások
- Backend: Java 21 + Spring Boot 3.2, PostgreSQL, Flyway.
- Admin web: React + TypeScript.
- Pénztár kliens: Electron + React + SQLite (offline queue + local cache).
- Kamera szolgáltatás (office node):
  - local recorder daemon,
  - local encrypted evidence store,
  - export service,
  - sync agent.

### 4.2 Domain bounded context-ek
- Cashdesk Operations
- Treasury & Vault
- Camera Evidence
- Reporting & Regulatory (Darius/Raiffeisen)
- Identity & Access (RBAC + audit)
- Sync & Replication

### 4.3 Szervezeti hierarchia (jogosultság)
- Pénztár
- Értéktár / központi páncél
- Főpénztár
- Területi vezető
- Kamera ellenőr
- Rendszer admin

## 5. Biztonsági baseline

### 5.1 Kötelező technikai kontrollok
- RBAC + least privilege minden API és UI útvonalon.
- Kamera bizonyíték titkosítva tárolva helyben (AES-256), kulcsrotációval.
- Hash-chain vagy digitális integritás marker minden frame szegmensre.
- Export csak auditált, engedélyezett szerepkörrel.
- Export watermark + export manifest (ki, mikor, mit, milyen ügyhöz).
- TLS minden hálózati csatornán.
- Secret manager használat, hardcoded credential tiltás.

### 5.2 Kötelező gate
- Deploy ajánlás előtt mindig futtatni:
  - powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
- FAILED vagy BLOCKED státusz esetén deploy tiltott.
- Evidence kötelező: security-reports/latest.

## 6. Adatmodell (minimum)

### 6.1 Központi PostgreSQL
- offices, users, roles, role_assignments
- transactions, transaction_legs, denominations
- treasury_transfers, seals, storno_events
- camera_segments, camera_segment_hashes, camera_exports
- sync_events, sync_conflicts, sync_retries
- daily_reports, monthly_reports, darius_submissions
- audit_log (immutable append-only)

### 6.2 Lokális SQLite (irodai kliens)
- local_transactions
- local_camera_index
- outbound_queue
- sync_checkpoint
- local_audit_ring

## 7. Kamera bizonyíték életciklus

### 7.1 Rögzítés
- Public és private stream külön logical channel.
- Segmentálás fix időablakban.
- Minden segmenthez:
  - timestamp,
  - officeId,
  - cameraId,
  - opcionális bizonylatszám link,
  - hash.

### 7.2 Megőrzés
- Alap retention: 50 nap.
- Disk-pressure policy: ha kritikus telítettség, priorizált takarítás az audit policy szerint.
- Legfrissebb/nyitott szegmens törlése tiltott.

### 7.3 Visszajátszás/export
- Role gate + indoklás kötelező mező.
- Export csomag:
  - media,
  - manifest.json,
  - hash lista,
  - optional player.
- Export napló immutable auditba kerül.

## 8. Offline-first és szinkron stratégia

- Outbox pattern minden kritikus domain eseményre.
- Idempotens üzenetkezelés (eventId + dedup index).
- Retry backoff + poison queue.
- Conflict policy:
  - tranzakciók: üzleti kulcs alapú feloldás,
  - kamera index: append-only,
  - riport állapot: explicit state machine.
- Sync SLA:
  - tranzakció meta: közel valós idő,
  - kamera meta: periódikus batch,
  - nagy media: sávszélesség-kímélő tömbös feltöltés.

## 9. Darius/Raiffeisen modul

### 9.1 Funkcionális követelmény
- Napi riport összeállítás és beküldés.
- Beküldési állapotkövetés (queued, sent, ack, failed).
- Havi lezárás/összesítő.
- Főpénztár jogosultságú felület.

### 9.2 Technikai interfész
- Adapter réteg (DariusAdapter):
  - payload builder,
  - signing/credential handling,
  - transport,
  - response parser.
- Teljes audit trail kötelező.

## 10. Stack opciók és ajánlás

### Opció A (ajánlott)
- Backend: Spring Boot + PostgreSQL
- Office client: Electron + SQLite
- Camera node: Java service
- Előny: jelenlegi repo stackhez illeszkedik, alacsonyabb migrációs kockázat.

### Opció B
- Backend: Spring Boot
- Office client: natív JavaFX
- Előny: egységesebb JVM stack
- Hátrány: meglévő React/Electron ökoszisztéma újraírási költség.

### Opció C
- Backend: .NET
- Office client: Electron
- Hátrány: platformszintű átállási kockázat nagy.

Választás: Opció A.

## 11. Fázisolt végrehajtási terv

### Fázis 0 — Stabil alap és biztonság
- Legacy viselkedés-katalógus véglegesítése.
- RBAC mátrix fixálás.
- Security gate baseline zöldre hozás.

Kilépési feltétel:
- Security gate PASS, kritikus sebezhetőség nélkül.

### Fázis 1 — Domain és adatmodell
- PostgreSQL séma + Flyway migrációk.
- Audit és sync táblák létrehozása.
- Core API-k (tranzakció, treasury, role).

Kilépési feltétel:
- Integrációs tesztek zöldek, migráció idempotens.

### Fázis 2 — Offline pénztár kliens
- SQLite outbox + sync engine.
- Tranzakciós képernyők és helyi validáció.
- Árfolyam TTL és AML ellenőrzés kötelező.

Kilépési feltétel:
- 24h hálózatkimaradás szimuláció mellett adatvesztés nélkül működik.

### Fázis 3 — Kamera evidence
- Recorder daemon + retention + repair.
- Visszajátszás és export pipeline.
- Szerepkör alapú hozzáférés + audit.

Kilépési feltétel:
- 50 napos retention policy tesztelt, export hash validáció zöld.

### Fázis 4 — Darius/Raiffeisen riport
- Daily report generálás és beküldés.
- Retry + hibakezelés + dashboard.
- Havi zárási riport.

Kilépési feltétel:
- UAT szerint napi riport folyamat üzletileg elfogadott.

### Fázis 5 — Rollout 50 irodára
- Pilot (3 iroda) -> wave deployment.
- Telemetria + incident runbook.
- Operációs tréning.

Kilépési feltétel:
- SLA célok teljesülnek, kritikus incidens trend csökken.

## 12. Tesztstratégia

- Unit tesztek domain logikára.
- Integrációs tesztek DB + API + sync.
- E2E szerepkörös jogosultság tesztek.
- Kamera export forenzikus validáció.
- Offline-chaos tesztek.
- Performance és soak teszt 50 irodás mintán.

## 13. AI ügynök végrehajtási utasítás (copy-paste képes)

Az alábbi utasítás egy AI coding agentnek adható közvetlen végrehajtásra.

---

Feladat:
A teljes valutaváltó rendszer modernizációját valósítsd meg a meglévő repositoryban, a dokumentumban definiált célarchitektúra szerint, offline-first, multi-branch, biztonságkritikus működéssel.

Kötelező szabályok:
1. Ne töröld a legacy bizonyítékot adó dokumentumokat.
2. Minden új backend endpoint role-protected legyen.
3. Minden kritikus művelet auditált legyen (ki, mikor, mit, miért).
4. Kamera export csak jogosultsággal és indoklással fusson.
5. Retention policy: alapértelmezetten 50 nap.
6. Darius napi riport modul kötelező scope.
7. Offline-first sync: outbox + idempotencia + retry.
8. Hardcoded secret tiltott.

Végrehajtási sorrend:
1. Hozd létre a szükséges PostgreSQL sémát Flyway migrációkkal.
2. Implementáld a Role/Permission modellt és audit logot.
3. Implementáld a treasury és tranzakciós core API-kat.
4. Implementáld az offline sync réteget (SQLite outbox, dedup, retry).
5. Implementáld a kamera evidence modult (record index, retention, export manifest, hash).
6. Implementáld a Darius/Raiffeisen daily reporting adaptert és state machinet.
7. Készíts admin felületeket:
   - szerepkör-kezelés,
   - kamera visszajátszás/export,
   - napi riport státusz.
8. Írj teszteket minden fázisra (unit/integration/e2e/offline).
9. Futtasd a projekt tesztjeit és buildet.
10. Deploy ajánlás előtt futtasd:
    - powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
11. Ha gate FAILED/BLOCKED, javítsd a hibákat és ismételd, amíg PASS.
12. Készíts rövid release note-ot a változásokról.

Elvárt kimenet:
- Futó backend + frontend + office kliens,
- dokumentált RBAC,
- bizonyítható 50 nap retention,
- bizonyítható napi Darius riport folyamat,
- PASS security gate evidence.

---

## 14. Definition of Done

- Funkcionális:
  - tranzakció, treasury, napzárás, riport folyamatok működnek.
- Biztonsági:
  - role-gate és audit teljes körű, security gate PASS.
- Operációs:
  - offline mód adatvesztés nélkül, sync konzisztens.
- Compliance:
  - kamera retention/export és Darius riport üzletileg validált.

## 15. Végrehajtás közbeni kötelező ellenőrző parancsok

- Backend teszt: cd backend && ./mvnw test
- Frontend teszt: cd frontend-react && npm test
- Pénztár kliens teszt: cd penztar-client && npm test
- Security gate: powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1

## 16. Current rendszer kódszintű állapotfelmérés (2026-03-20)

Megjegyzés: ez a blokk nem dokumentum-összefoglaló, hanem forráskód alapú állapotkép a jelenlegi implementációról.

### 16.1 Bizonyíték-alapú meglévő képességek (current)

- Tranzakciós magfolyamatok (vétel, eladás, konverzió, sztornó, részleges visszaváltás) implementáltak, endpoint szinten role-gate + idempotencia védelemmel.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/controller/TransactionController.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- AML és azonosítási küszöb logika jelen van (300 000 HUF limit), POS integrációval együtt.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- 24 órás árfolyam-frissesség (TTL) és max-deviation validáció implementált.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/ExchangeRateService.java`
- Treasury/értéktár átadás-átvétel komplex iránylogikával (F/U/UF/FF), counter-tranzakcióval és cash balance frissítéssel implementált.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/controller/TransferController.java`
- Napi jelentés generálás és submit státuszkezelés implementált branch szinten.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/DailyReportService.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/controller/DailyReportController.java`
- Office oldali offline-first működés: lokális SQLite queue (`pending_*` táblák), stabil idempotency kulcsok, periodikus szinkronmotor.
  - Bizonyíték: `penztar-client/electron/sqlite.ts`
  - Bizonyíték: `penztar-client/electron/sync-engine.ts`
- Kamera lokális rögzítés + retention + lokális export + takarítás implementált.
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/config/CameraProperties.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/CameraRecordingService.java`
  - Bizonyíték: `backend/src/main/java/hu/puzzleir/valuta/service/CameraCleanupService.java`
  - Bizonyíték: `penztar-client/electron/camera.ts`

### 16.2 Legacy vs current parity mátrix (funkcionális és strukturális)

| Terület | Legacy elvárás | Current kódállapot | Parity | Kockázat |
|---|---|---|---|---|
| Tranzakciós core (vétel/eladás/konverzió/sztornó) | Teljes üzleti lánc | Implementált, role-gate + idempotencia + AML + POS | KOZEL TELJES | KOZEPES |
| Átadás-átvétel (ATADVET logika) | Direction-függő pénzmozgások | F/U/UF/FF modellezett, counter tx-ek és balance update-ek megvannak | KOZEL TELJES | KOZEPES |
| Napi jelentés alapfolyamat | Napi összesítés + beküldés | Generálás + submit van, de külső Darius csatorna nincs | RESZLEGES | MAGAS |
| Darius/Raiffeisen kötelező napi riport | Kötelező regulatory beküldés | Darius adapter/transport/scheduler nem azonosítható | HIANYOS | KRITIKUS |
| FTP bridge | Legacy kompatibilitás | `FtpSyncService` jelenleg mock/log implementáció | RESZLEGES | MAGAS |
| Branch sync backend | Valós adatcsere fiókok között | `SyncService` és `SynchronizationService` szimulációs/simplified jellegű | RESZLEGES | MAGAS |
| Office offline queue + retry | Offline működés adatvesztés nélkül | Erős implementáció: pending táblák + periodikus sync + idempotencia | ERSEN JELEN VAN | KOZEPES |
| Kamera retention (50 nap) | Kötelező megőrzés | Backend default 50 nap + ütemezett cleanup, Electron local cleanup is van | TELJES | KOZEPES |
| Kamera központi feltöltés | Központi bizonyíték-tár | `CameraUploadService` valós feltöltése pending, mock útvonal | HIANYOS | MAGAS |
| Kamera titkosítás/integritás | Forenzikus védelem | Config szinten van encryption paraméter, de használat nem látható | HIANYOS | KRITIKUS |
| Tranzakció-kamera automatikus összelinkelés | Receipt/time alapú bizonyíték lánc | Linker service létezik, de nincs bekötve a tranzakció mentési flow-ba | RESZLEGES | MAGAS |
| Jogosultsági modellek (területi vezető/kamera ellenőr) | Fine-grained role modell | Több camera endpoint `MANAGER/ADMIN` szintű, dedikált legacy role-ek nem látszanak végigvezetve | RESZLEGES | KOZEPES |

### 16.3 Kritikus gap-ek (zárás előtti P0)

1. Darius/Raiffeisen napi riport csatorna hiányzik a kötelező compliance scope-hoz.
2. Kamera központi feltöltés jelenleg mock, ezért end-to-end evidence lánc nem zárt.
3. Kamera titkosítás csak konfigurációs deklaráció, futó kriptográfiai pipeline nem látszik.
4. Branch szinkron backend oldalon több helyen szimulációs jellegű, nem teljes adatcsere.
5. Kamera-tranzakció automatikus linkelés nincs bekötve a transaction mentésbe.

### 16.4 Priorizált zárási terv (current hardening)

P0 (blokkoló):
- Darius adapter + state machine (`queued -> sent -> ack -> failed`) + retry scheduler.
- Kamera upload valós transport (chunk/hash), központi tárolás és visszaellenőrzés.
- Kamera titkosítás tényleges bekapcsolása (segment szint) és kulcskezelés.
- Transaction save flow-ban automatikus `CameraTransactionLinker` hívás.
- Sync backend valós branch adatcsere endpointokkal, nem csak szimulációval.

P1 (stabilizáció):
- Kamera export backend oldali manifest/hash validáció és role + reason enforcement.
- Legacy szerepkörök explicit modellezése (`TERULETI_VEZETO`, `KAMERA_ELLENOR`) UI+API oldalon.
- Outbox/inbox jelenlegi skeleton kiterjesztése több event típusra, nem csak rate publish.

P2 (optimalizáció):
- Monitoring dashboard KPI-k: queue depth, dead-letter trend, kamera pending upload, report SLA.
- Incident runbook és automatikus replay tooling a FAILED ágakra.


