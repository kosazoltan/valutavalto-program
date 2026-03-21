# Valutavalto ERP - End-to-End AI Execution Playbook

Datum: 2026-03-20
Cel: Egyetlen, vegrehajtasi sorrendu utasitascsomag AI ugynoknek a teljes implementaciohoz.
Hatar: backend + frontend + electron + security + rollout

## 1. Beolvasando alapanyagok (nem ujrakeszites)

1. docs/ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md
2. docs/JIRA_SPRINT_BREAKDOWN_AND_DEV_CHECKLIST_2026-03-20.md
3. docs/ANTI_MASTERPLAN_WORKLOG_2026-03-20.md
4. docs/legacy-analysis-part1-core-docs.md
5. docs/legacy-analysis-part4-technical.md

Kotelezo: ezekre epits, ne keszits uj parity elemzest, csak hianyokat potolj.

## 2. Nem targyalhato kovetelmenyek

1. Kamera rogzites helyben, minimum 50 nap retention.
2. Kamera anyaghoz csak jogosult szerepkorok ferhetnek hozza.
3. Export hatosagi lejatszhato formatumban, audit nyomvonallal.
4. Bizonylatok helyi tarolasa minimum 1 honapig offline uzemben.
5. Folyamatos, biztonsagos szinkron kozponti PostgreSQL-be.
6. Darius/Raiffeisen napi riport mukodese kotelezo (fopenztar jogosultsag).
7. Multi-szint szervezeti modell: penztar -> ertektar -> fopenztar.

## 3. Stack dontes (fix)

1. Backend: Java 21 + Spring Boot 3.2 + PostgreSQL + Flyway.
2. Frontend admin: React + TypeScript.
3. Office kliens: Electron + React + SQLite.
4. Kamera node: local recorder service + export service + sync agent.

## 4. Vegrehajtasi sorrend (1 -> N)

## 4.1 Foundation

1. Hozz letre branch-et: feature/e2e-modernization-phase-1.
2. Ellenorizd a jelenlegi build allapotot:
   - backend teszt
   - frontend teszt
   - electron teszt
3. Rogzits baseline eredmenyeket docs alatt.

Kapu:
- Ha baseline bukik, eloszor baseline fix, csak utana uj feature.

## 4.2 Data model es security core

1. Flyway migraciok: users, roles, role_assignments, audit_log.
2. Flyway migraciok: transactions, treasury_transfers, storno_events, seals.
3. Flyway migraciok: camera_segments, camera_exports, camera_hashes.
4. Flyway migraciok: daily_reports, darius_submissions, sync_events, sync_retries, sync_conflicts.
5. Implementald az RBAC enforcementet minden uj endpointon.
6. Implementald az append-only audit irast kritikus muveletekre.

Kapu:
- Integracios tesztek zold.
- Unauthorized hozzaferes 403 minden vedett endpointon.

## 4.3 Offline-first tranzakcios csatorna (Electron + Backend)

1. SQLite outbox tablak letrehozasa electronben.
2. Tranzakcio mentes mindig outbox eventet general.
3. Sync worker implementacio:
   - exponential backoff,
   - dedup,
   - poison queue.
4. Backend sync endpointok:
   - batch push,
   - batch pull,
   - idempotens event feldolgozas.
5. Admin sync monitor endpoint + frontend oldal.

Kapu:
- 24 oras halozatkimaradas szimulacio utan adatvesztes 0.

## 4.4 Kamera evidence pipeline

1. Local segment indexeles public/private csatornara.
2. Hash kepzes minden segmentre.
3. Retention worker: 50 nap + disk pressure policy.
4. Export generator:
   - media,
   - manifest,
   - hash lista,
   - optional player.
5. Backend export API:
   - role gate,
   - kotelezo indoklas,
   - audit.
6. Frontend oldalak:
   - visszajatszas,
   - export inditas,
   - export audit timeline.

Kapu:
- Export hash validacio PASS.
- Jogosulatlan export 403.

## 4.5 Darius/Raiffeisen napi riport

1. Darius adapter interface + implementation.
2. Payload builder, transport, response parser.
3. Riport state machine: queued -> sent -> ack -> failed.
4. Retry mechanizmus failed allapotra.
5. Fopenztari dashboard:
   - napi riport lista,
   - allapot,
   - ujrakuldes.
6. Havi osszesito es export.

Kapu:
- UAT forgatokonyv sikeres.
- Chief treasury role nelkul nincs hozzaferes.

## 4.6 Rollout and hardening

1. Performance tuning (DB index, API latency).
2. Chaos/offline soak tesztek.
3. Pilot 3 iroda.
4. Wave rollout 50 irodara.
5. Incident runbook veglegesites.

Kapu:
- SLA celok teljesulnek.
- Kritikus incidencia trend nem romlik.

## 5. Feladatszalak komponensenkent

## 5.1 Backend kotelezo teendok

1. Flyway migration csomagok.
2. RBAC enforcement.
3. Audit append-only.
4. Sync API idempotencia.
5. Camera export API.
6. Darius adapter + scheduler.
7. Integration test suite bovites.

## 5.2 Frontend kotelezo teendok

1. Role management admin.
2. Audit viewer.
3. Sync monitor dashboard.
4. Camera replay/export UI.
5. Export audit timeline.
6. Fopenztari riport dashboard.

## 5.3 Electron kotelezo teendok

1. Secure local storage.
2. SQLite outbox.
3. Sync worker.
4. Tranzakcios offline workflow.
5. Camera segment indexer.
6. Retention worker.
7. Export package generator.

## 6. Hibakezelesi szabalyok AI ugynoknek

1. Ha teszt bukik, celzott javitas -> ujrafuttatas -> tovabblepes.
2. Ne ugord at a bukott teszteket skip-pel.
3. Minden modositasi blokk utan futtasd a relevans teszteket.
4. Security gate FAILED/BLOCKED eseten deployment tilos.

## 7. Minosegkapuk minden sprint vegen

1. Code quality: lint + typecheck + test PASS.
2. Security: gate PASS evidence elerheto.
3. Functional: acceptance criteria teljesult.
4. Operability: runbook friss.

## 8. Kotelezo parancsok

1. Backend teszt: cd backend && ./mvnw test
2. Frontend teszt: cd frontend-react && npm test
3. Electron teszt: cd penztar-client && npm test
4. Security gate: powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1

## 9. Atadasi csomag Definition of Done

1. Fut minden relevans teszt.
2. Security gate PASS.
3. Kamera retention/export bizonyithato.
4. Darius napi riport folyamat bizonyithato.
5. Dokumentacio frissitve:
   - architecture
   - runbook
   - release notes
   - known risks

## 10. Vegrehajtasi prompt AI coding agenthez

Feladatod:
A repositoryban a fent leirt sorrend szerint implementald a teljes modernizaciot ugy, hogy minden sprintkapu teljesuljon. Minden munkablokk utan futtasd a relevans teszteket. Ha teszt hiba van, javitsd azonnal, futtasd ujra, es csak utana haladj tovabb. A biztonsagi gate-et release javaslat elott kotelezo futtatni. FAILED vagy BLOCKED gate eseten deploymentet ne javasolj.

## 11. Delta mod (ha a rendszer mar reszben implementalt)

Ez a repository mar tartalmaz mukodo tranzakcios, offline es kamera alapokat, ezert teljes ujraepites helyett parity-closing mod javasolt.

### 11.1 Elso koros ellenorzes

1. Azonositsd a mock/simplified komponenseket es kulon backlogra bontsd:
   - `FtpSyncService` (mock)
   - `SyncService`/`SynchronizationService` (simplified)
   - `CameraUploadService` (mock upload)
2. Ellenorizd a compliance blokkolokat:
   - Darius/Raiffeisen adapter hiany
   - kamera titkositas csak config szinten
   - kamera-tranzakcio linker bekotes hianya

### 11.2 Prioritasi sorrend (delta)

1. P0: compliance es evidence-lanc zaras
2. P1: role-finomitas es audit/monitoring bovitese
3. P2: operacios optimalizacio es automatizalt replay

### 11.3 Konkreten vegrehajtando delta-lepesek

1. Darius state machine implementacio (`queued/sent/ack/failed`) + retry scheduler.
2. Kamera central upload mock kivaltasa valos transport implementacioval.
3. Kamera titkositas tenyleges hasznalata a segment pipeline-ban.
4. Transaction commit utan automatikus camera-link (`CameraTransactionLinker`) trigger.
5. Simplified backend sync vegpontok cserelese valos rekordszintu sync-re.
6. Frontend role matrix hardening legacy kamera-szerepkorokre.

### 11.4 Delta Definition of Done

Megjegyzés (valós állapot): ez egy célállapot definíció, jelenleg még NEM teljesül teljeskörűen.

1. Nincs mock/simplified komponens a kritikus (P0) folyamokban.
2. Darius napi riport allapotgep valos, visszakeresheto audit trail-lel.
3. Kamera evidence lanc (rogzites -> titkositas -> retention -> upload -> visszakereses) vegig igazolhato.
4. Security gate PASS + relevans backend/frontend/electron tesztek PASS.

