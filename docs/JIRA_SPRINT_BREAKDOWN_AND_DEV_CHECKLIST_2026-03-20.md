# Valutavalto ERP - Jira sprint bontas es fejlesztoi checklist

Datum: 2026-03-20
Terjedelem: Backend + Frontend + Electron
Sprint hossz: 2 het
Csapat minta: 2 backend, 2 frontend, 2 electron, 1 QA, 1 DevOps/Sec

## 1. Sprint utemezes

1. Sprint 0 (Alapozas es security baseline)
2. Sprint 1 (Core domain API + RBAC + audit)
3. Sprint 2 (Offline sync es penztar kliens alap)
4. Sprint 3 (Camera evidence retention/export)
5. Sprint 4 (Darius/Raiffeisen riport)
6. Sprint 5 (Hardening, pilot, rollout 50 iroda)

## 2. Jira issue format szabaly

Minden issue tartalmazza:
- Type
- Key
- Summary
- Description
- Acceptance Criteria
- Estimate
- Component
- Assignee
- Depends On

## 3. Sprintenkenti Jira backlog

## Sprint 0 - Alapozas es security baseline

Type: Epic
Key: VAL-EPIC-SEC
Summary: Security baseline and delivery guardrails
Description: RBAC matrix, audit policy, secret policy, mandatory gate automation.
Acceptance Criteria: Security baseline dokumentalt, gate PASS reproducible.
Estimate: 8 SP
Component: backend, devops, security
Assignee: DevOps-1
Depends On: none

Type: Story
Key: VAL-S0-BE-01
Summary: RBAC szerepkor matrix es permission catalog
Description: Legacy role mapping atultetese uj szerepkor modelbe.
Acceptance Criteria: Roles and permissions list approved by business owner.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-EPIC-SEC

Type: Story
Key: VAL-S0-BE-02
Summary: Audit event schema es immutable log policy
Description: Audit event taxonomia es tarolasi szabalyok.
Acceptance Criteria: Audit schema migracio es policy dokumentum kesz.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-EPIC-SEC

Type: Story
Key: VAL-S0-FE-01
Summary: Admin UI wireframe role es audit nezethez
Description: Frontend skeleton pages role management es audit viewer oldalhoz.
Acceptance Criteria: Navigalhato wireframe oldal, stakeholder review done.
Estimate: 3 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S0-BE-01

Type: Story
Key: VAL-S0-EL-01
Summary: Electron secure local storage baseline
Description: SQLite titkositasi policy es local key handling terv.
Acceptance Criteria: Dokumentalt es proof-of-concept mukodo local encrypted config.
Estimate: 5 SP
Component: electron
Assignee: EL-1
Depends On: VAL-EPIC-SEC

Type: Task
Key: VAL-S0-DEVOPS-01
Summary: Security gate pipeline hook
Description: scripts/security/run-security-gate.ps1 kotelezo futas CI gateben.
Acceptance Criteria: Pull request pipeline FAIL ha gate FAILED vagy BLOCKED.
Estimate: 3 SP
Component: devops
Assignee: DevOps-1
Depends On: VAL-EPIC-SEC

## Sprint 1 - Core domain API + RBAC + audit

Type: Epic
Key: VAL-EPIC-CORE
Summary: Core domain backend foundation
Description: Transactions, treasury transfers, role-protected endpoints, audit logs.
Acceptance Criteria: Core API endpontok role-protected es auditoltak.
Estimate: 13 SP
Component: backend
Assignee: BE-Lead
Depends On: VAL-S0-BE-01, VAL-S0-BE-02

Type: Story
Key: VAL-S1-BE-01
Summary: Flyway migration offices/users/roles/assignments
Description: Alap IAM schema migraciok es indexek.
Acceptance Criteria: Ures adatbazison migration PASS.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S0-BE-01

Type: Story
Key: VAL-S1-BE-02
Summary: Flyway migration transactions/treasury/storno/seal
Description: Core tranzakcios es penztar ertektar tablak.
Acceptance Criteria: CRUD integracios tesztek zold.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S1-BE-01

Type: Story
Key: VAL-S1-BE-03
Summary: @PreAuthorize policy minden uj controllerre
Description: Role policy enforcement tranzakcio es treasury endpointokon.
Acceptance Criteria: Unauthorized request 403, authorized 2xx.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S1-BE-01

Type: Story
Key: VAL-S1-BE-04
Summary: Audit interceptor and append-only persistence
Description: API hivasi audit metadata tarolasa.
Acceptance Criteria: Ki, mikor, mit, miert mezok minden kritikus muveletnel.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S0-BE-02

Type: Story
Key: VAL-S1-FE-01
Summary: Role management oldal implementacio
Description: Role assignment admin felulet backend integracioval.
Acceptance Criteria: Role list, assignment, revoke, audit trail link mukodik.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S1-BE-03

Type: Story
Key: VAL-S1-FE-02
Summary: Audit viewer oldal implementacio
Description: Szurt audit lista datum, user, action alapon.
Acceptance Criteria: Pagination, filter, detail panel mukodik.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S1-BE-04

Type: Story
Key: VAL-S1-EL-01
Summary: Electron login + token refresh + role cache
Description: Biztonsagos bejelentkezes es local role cache.
Acceptance Criteria: Offline fallback role cache olvasas es token refresh tesztelt.
Estimate: 5 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S1-BE-03

## Sprint 2 - Offline sync es penztar kliens alap

Type: Epic
Key: VAL-EPIC-OFFLINE
Summary: Offline-first transaction pipeline
Description: Outbox, idempotencia, retry, conflict policy, local SQLite queue.
Acceptance Criteria: 24h network cut scenario adatvesztes nelkul PASS.
Estimate: 21 SP
Component: backend, electron
Assignee: EL-Lead
Depends On: VAL-EPIC-CORE

Type: Story
Key: VAL-S2-BE-01
Summary: Sync API endpoint csomag (batch pull/push)
Description: Event alapu sync endpointok dedup logikaval.
Acceptance Criteria: Ugyanaz event tobbszor kuldve idempotens.
Estimate: 8 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S1-BE-02

Type: Story
Key: VAL-S2-BE-02
Summary: Sync events es retries adatmodell
Description: sync_events, sync_retries, sync_conflicts tablak + service.
Acceptance Criteria: Retry policy allapotgep tesztek zold.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S2-BE-01

Type: Story
Key: VAL-S2-EL-01
Summary: SQLite outbox tabla es producer layer
Description: Minden offline tranzakcio outbox esemenyt general.
Acceptance Criteria: Offline muveletek sorban mentodnek es visszakuldhetok.
Estimate: 8 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S2-BE-01

Type: Story
Key: VAL-S2-EL-02
Summary: Sync worker retry with exponential backoff
Description: Hatterszinkron idozitett futtatasa hibaturo modon.
Acceptance Criteria: Retry limit, poison queue, user notification mukodik.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-S2-EL-01, VAL-S2-BE-02

Type: Story
Key: VAL-S2-FE-01
Summary: Admin sync monitor dashboard
Description: Irodankenti sync status, queue depth, error trend nezet.
Acceptance Criteria: Last sync time, failed count, retry count lathato.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S2-BE-02

Type: Story
Key: VAL-S2-EL-03
Summary: Penztar tranzakcio alap kepernyok parity MVP
Description: Vetel/eladas alap folyamata offline validacioval.
Acceptance Criteria: Tranzakcio mentheto offline, sync utan kozpontban megjelenik.
Estimate: 8 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S2-EL-01

## Sprint 3 - Camera evidence retention/export

Type: Epic
Key: VAL-EPIC-CAM
Summary: Camera evidence service
Description: Segment index, retention 50 nap, export package, hash verification.
Acceptance Criteria: Kamera export audit trail es hash validacio PASS.
Estimate: 21 SP
Component: backend, electron, frontend
Assignee: BE-Lead
Depends On: VAL-EPIC-OFFLINE

Type: Story
Key: VAL-S3-BE-01
Summary: camera_segments es camera_exports schema
Description: Segment metadata, hash, export manifest tarolas.
Acceptance Criteria: Migration + repository tesztek PASS.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S1-BE-02

Type: Story
Key: VAL-S3-BE-02
Summary: Camera export API role gate and reason code
Description: Export kereses indoklas kotelezo mezo, role check.
Acceptance Criteria: Missing reason 400, unauthorized 403.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S3-BE-01, VAL-S1-BE-03

Type: Story
Key: VAL-S3-EL-01
Summary: Local recorder segment indexer
Description: Public/private segment metadata irasa local indexbe.
Acceptance Criteria: Segment metadata folytonos, hiany eseten alert.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-S3-BE-01

Type: Story
Key: VAL-S3-EL-02
Summary: Retention worker 50 nap + disk pressure policy
Description: Takaritas retention szabaly szerint audit eventtel.
Acceptance Criteria: 50 napnal regebbi segment torlodik policy szerint.
Estimate: 8 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S3-EL-01

Type: Story
Key: VAL-S3-EL-03
Summary: Export package generator with hash manifest
Description: Media + manifest + hash list + optional player csomag.
Acceptance Criteria: Ujrajatszas es hash ellenorzes sikeres.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-S3-EL-01, VAL-S3-BE-02

Type: Story
Key: VAL-S3-FE-01
Summary: Kamera visszajatszas es export admin UI
Description: Datumtartomany, kamera tipus, role based action.
Acceptance Criteria: Export inditas csak jogosult userrel megy.
Estimate: 8 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S3-BE-02

Type: Story
Key: VAL-S3-FE-02
Summary: Export audit timeline UI
Description: Ki, mikor, melyik irodabol, milyen ugyhivatasra exportalt.
Acceptance Criteria: Audit timeline oldalon szures es details panel mukodik.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S3-BE-02

## Sprint 4 - Darius/Raiffeisen riport

Type: Epic
Key: VAL-EPIC-DARIUS
Summary: Daily and monthly regulatory reporting
Description: Darius adapter, status tracking, retry, chief treasury dashboard.
Acceptance Criteria: Daily report send flow UAT szerint megfelel.
Estimate: 21 SP
Component: backend, frontend
Assignee: BE-Lead
Depends On: VAL-EPIC-CORE

Type: Story
Key: VAL-S4-BE-01
Summary: daily_reports es darius_submissions schema
Description: Report allapotgep, request/response audit mezok.
Acceptance Criteria: queued-sent-ack-failed allapotok konzisztensen tarolodnak.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S1-BE-02

Type: Story
Key: VAL-S4-BE-02
Summary: Darius adapter payload builder and transport
Description: Riport payload generalas, alairas, kuldes, parser.
Acceptance Criteria: Sandbox endpointtel sikeres roundtrip teszt.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S4-BE-01

Type: Story
Key: VAL-S4-BE-03
Summary: Daily report scheduler and retry policy
Description: Napi utemezett futas, hiba eseten retry.
Acceptance Criteria: Failed kuldes automatikusan ujraprobalhato.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S4-BE-02

Type: Story
Key: VAL-S4-FE-01
Summary: Fopenztari napi riport dashboard
Description: Report lista, status, resend, details nezet.
Acceptance Criteria: Csak chief treasury role fer hozza.
Estimate: 8 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S4-BE-03

Type: Story
Key: VAL-S4-FE-02
Summary: Havi osszesito es export oldal
Description: Monthly report summary and export actions.
Acceptance Criteria: Havi riport CSV/PDF export elerheto jogosultsaggal.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S4-BE-03

Type: Task
Key: VAL-S4-QA-01
Summary: Darius E2E UAT script
Description: End-to-end tesztforgatokonyv napi kuldeshez.
Acceptance Criteria: UAT script approval business ownertol.
Estimate: 3 SP
Component: qa
Assignee: QA-1
Depends On: VAL-S4-FE-01, VAL-S4-BE-03

## Sprint 5 - Hardening, pilot, rollout

Type: Epic
Key: VAL-EPIC-ROLL
Summary: Production hardening and staged rollout
Description: Performance, chaos, pilot wave, observability, runbook.
Acceptance Criteria: Pilot 3 iroda stabil 2 hetig, rollout decision gate PASS.
Estimate: 21 SP
Component: all
Assignee: Tech-Lead
Depends On: VAL-EPIC-DARIUS, VAL-EPIC-CAM

Type: Story
Key: VAL-S5-BE-01
Summary: Performance tuning indexes and query profiling
Description: Slow query javitas, index tuning, cache policy.
Acceptance Criteria: P95 API latency target teljesul.
Estimate: 5 SP
Component: backend
Assignee: BE-2
Depends On: VAL-EPIC-CORE

Type: Story
Key: VAL-S5-EL-01
Summary: Offline chaos test harness
Description: Random network cut and restore teszt runner electronre.
Acceptance Criteria: 24h chaos run adatvesztes nelkul PASS.
Estimate: 8 SP
Component: electron
Assignee: EL-2
Depends On: VAL-EPIC-OFFLINE

Type: Story
Key: VAL-S5-FE-01
Summary: Operacios dashboard polish and incident view
Description: Unified admin health dashboard error trenddel.
Acceptance Criteria: Critical alerts es incident drilldown elerheto.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-S2-FE-01, VAL-S3-FE-02, VAL-S4-FE-01

Type: Task
Key: VAL-S5-DEVOPS-01
Summary: Pilot rollout runbook es backup/restore drill
Description: Deploy wave script, rollback plan, DB restore gyakorlat.
Acceptance Criteria: Dry run dokumentalt evidence-szel.
Estimate: 5 SP
Component: devops
Assignee: DevOps-1
Depends On: VAL-EPIC-ROLL

Type: Task
Key: VAL-S5-QA-01
Summary: Release readiness checklist and sign-off
Description: Smoke, regression, security gate, UAT eredmenyek osszegzese.
Acceptance Criteria: Go-live sign-off dokumentum kesz.
Estimate: 3 SP
Component: qa
Assignee: QA-1
Depends On: VAL-S5-BE-01, VAL-S5-EL-01, VAL-S5-FE-01

## 4. Fejlesztokent kioszthato implementacios checklist

## BE-1 checklist
- [ ] VAL-S0-BE-01 role matrix implementalasa es review.
- [ ] VAL-S1-BE-01 IAM Flyway migraciok.
- [ ] VAL-S1-BE-03 role protection minden uj controlleren.
- [ ] VAL-S2-BE-01 sync API batch pull/push idempotens endpointok.
- [ ] VAL-S3-BE-02 camera export API reason code + role gate.
- [ ] VAL-S4-BE-01 daily_reports schema.
- [ ] VAL-S4-BE-03 napi scheduler + retry.
- [ ] Sajat issuekhoz unit + integration tesztek.

## BE-2 checklist
- [ ] VAL-S0-BE-02 audit schema es policy.
- [ ] VAL-S1-BE-02 transactions/treasury Flyway.
- [ ] VAL-S1-BE-04 audit interceptor.
- [ ] VAL-S2-BE-02 sync retries/conflicts adatmodell.
- [ ] VAL-S3-BE-01 camera metadata schema.
- [ ] VAL-S4-BE-02 Darius adapter implementacio.
- [ ] VAL-S5-BE-01 performance tuning.
- [ ] Sajat issuekhoz unit + integration tesztek.

## FE-1 checklist
- [ ] VAL-S0-FE-01 role/audit wireframe.
- [ ] VAL-S1-FE-01 role management oldal.
- [ ] VAL-S3-FE-01 kamera visszajatszas es export UI.
- [ ] VAL-S4-FE-02 havi osszesito oldal.
- [ ] VAL-S5-FE-01 ops dashboard polish.
- [ ] Component unit tesztek + E2E smoke flow frissites.

## FE-2 checklist
- [ ] VAL-S1-FE-02 audit viewer oldal.
- [ ] VAL-S2-FE-01 sync monitor dashboard.
- [ ] VAL-S3-FE-02 export audit timeline.
- [ ] VAL-S4-FE-01 fopenztari napi riport dashboard.
- [ ] Frontend role-guard regression tesztek.

## EL-1 checklist
- [ ] VAL-S0-EL-01 secure local storage baseline.
- [ ] VAL-S1-EL-01 login + token refresh + role cache.
- [ ] VAL-S2-EL-01 sqlite outbox producer.
- [ ] VAL-S2-EL-03 tranzakcio MVP kepernyok offline validacioval.
- [ ] VAL-S3-EL-02 retention worker 50 nap policy.
- [ ] Offline storage migration tesztek.

## EL-2 checklist
- [ ] VAL-S2-EL-02 sync worker retry/backoff/poison queue.
- [ ] VAL-S3-EL-01 recorder segment indexer.
- [ ] VAL-S3-EL-03 export package generator hash manifesttel.
- [ ] VAL-S5-EL-01 offline chaos test harness.
- [ ] File integrity es export replay tesztek.

## QA-1 checklist
- [ ] VAL-S4-QA-01 Darius E2E UAT forgatokonyv.
- [ ] VAL-S5-QA-01 release readiness sign-off.
- [ ] Sprint vegi regression matrix frissites.
- [ ] Security gate evidence ellenorzes minden release candidatehoz.

## DevOps-1 checklist
- [ ] VAL-S0-DEVOPS-01 security gate CI hook.
- [ ] VAL-S5-DEVOPS-01 pilot rollout runbook.
- [ ] Observability baseline: log, metric, alert policy.
- [ ] Backup/restore drill bizonyitekok tarolasa.

## 5. Sprint Definition of Done

- Minden issue acceptance criteria teljesult.
- Relevans tesztek lefutottak es sikeresek.
- Security gate PASS evidence elerheto.
- Dokumentacio frissitve (API, runbook, release note).
- Product owner elfogadas megtortent sprint review-n.

## 6. Javasolt issue labels

- area/backend
- area/frontend
- area/electron
- area/security
- area/reporting
- area/camera
- type/feature
- type/techdebt
- priority/p0
- priority/p1

## 7. Capacity minta sprintenkent

- BE-1: 8-10 SP
- BE-2: 8-10 SP
- FE-1: 6-8 SP
- FE-2: 6-8 SP
- EL-1: 8-10 SP
- EL-2: 8-10 SP
- QA-1: 4-6 SP
- DevOps-1: 4-6 SP

Megjegyzes: Ha a valos csapatmeret kisebb, a sprint issuek osszevonhatok, de a fuggosegek sorrendje maradjon.

## 8. Current parity gap backlog (kodalapu ujrapriorizalas)

Megjegyzes: ez a blokk a jelenlegi forraskod tenyleges allapotabol indul ki.

Type: Epic
Key: VAL-EPIC-CURRENT-HARDENING
Summary: Legacy parity closure from current codebase
Description: A mar meglevo implementacio hardeningje a hianyzo legacy-kritikus folyamatokra.
Acceptance Criteria: P0 parity gap-ek lezartak, security gate PASS, compliance smoke PASS.
Estimate: 21 SP
Component: backend, frontend, electron
Assignee: BE-Lead
Depends On: VAL-EPIC-CAM, VAL-EPIC-DARIUS

Type: Story
Key: VAL-CH-P0-BE-01
Summary: Darius daily adapter and state machine
Description: queued/sent/ack/failed allapotgep, retry scheduler, audit metadata.
Acceptance Criteria: Napi bekuldes vegigfut szimulalt/teszt endpointon, statusok konzisztensen tarolodnak.
Estimate: 8 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S4-BE-01

Type: Story
Key: VAL-CH-P0-BE-02
Summary: Kamera kozponti upload implementacio
Description: Mock upload lecserelese valos transport pipeline-ra, hibaturo retry-jal.
Acceptance Criteria: Completed szegmens valos feltoltese es visszaigazolt allapotfrissites.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S3-BE-01

Type: Story
Key: VAL-CH-P0-BE-03
Summary: Kamera titkositas aktiv hasznalat
Description: Config-only encryption helyett tenyleges segment titkositas + kulcskezeles.
Acceptance Criteria: Tarolt szegmens plain text-ben nem olvashato, decrypt folyamat tesztelt.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-CH-P0-BE-02

Type: Story
Key: VAL-CH-P0-BE-04
Summary: CameraTransactionLinker bekotese tranzakcio menteshez
Description: Minden transaction commit utan automatikus camera-link kepzes.
Acceptance Criteria: Receipt alapjan visszakeresheto kapcsolt felvetel metadata.
Estimate: 5 SP
Component: backend
Assignee: BE-1
Depends On: VAL-S3-BE-01

Type: Story
Key: VAL-CH-P0-BE-05
Summary: Sync service valos branch adatcsere
Description: Simplified sync implementaciok kivaltasa valos push/pull adatutakkal.
Acceptance Criteria: Nem csak darabszam/szimulacio, hanem tenyleges adatrekord mozgatas igazolhato.
Estimate: 8 SP
Component: backend
Assignee: BE-2
Depends On: VAL-S2-BE-01

Type: Story
Key: VAL-CH-P1-FE-01
Summary: Kamera export reason + audit timeline hardening UI
Description: Jogosultsag, indoklas, hash/manifest visszaellenorzes vizualizalasa.
Acceptance Criteria: Export inditas indoklas nelkul tiltott, audit timeline teljesen kovetheto.
Estimate: 5 SP
Component: frontend
Assignee: FE-1
Depends On: VAL-CH-P0-BE-02

Type: Story
Key: VAL-CH-P1-FE-02
Summary: Legacy kamera role mapping a feluleten
Description: Teruleti vezeto es kamera ellenor szerepkorokhoz dedikalt nezetek/jogok.
Acceptance Criteria: Role matrix szerint UI elemek es route-ok megfeleloen gate-eltek.
Estimate: 5 SP
Component: frontend
Assignee: FE-2
Depends On: VAL-S1-BE-03

Type: Story
Key: VAL-CH-P1-EL-01
Summary: Offline queue observability panel
Description: Pending queue meretek, dead-letter, retry trend local diagnosztikara.
Acceptance Criteria: Support celra reprodukalhato queue allapotkep barmikor exportalhato.
Estimate: 3 SP
Component: electron
Assignee: EL-1
Depends On: VAL-S2-EL-02
