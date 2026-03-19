# AI Execution Masterplan - Teljes Atalakitas es/vagy Fokozatos Implementalas

Verzio: 1.0
Datum: 2026-03-14
Statusz: Vegrehajthato mesterterv AI modellekhez

---

## 0. Cel es hasznalati mod

Ez a dokumentum ket uzemmodot tamogat:

1. Incremental mode (ajanlott):
- A jelenlegi kodbazisra epites.
- Kamera + arfolyam + offline-first + szinkron megerositese.
- Uzleti logika sertetlenseg maximalis vedelme.

2. Full transformation mode:
- Modularis ujraszervezes uj bounded context-ekkel.
- Strangler pattern szerint fokozatos atallassal.
- Legacy modulok kontrollalt kivezetese.

Fontos: Uzleti kockazat miatt production celra az incremental mode az alapertelmezett.

Kapcsolodo gepileg feldolgozhato task graph:
- `docs/AI_TASK_GRAPH.yaml`

---

## 1. Nem alkudhato kovetelmenyek (hard constraints)

1. Offline mukodes kotelezo minden penztari kritikus tranzakciohoz.
2. Kamera rogzitese folyamatos a nyitvatartasi idoben, helyi tarolassal.
3. Kameraadat legalabb 50 nap retention helyben + kozpontban.
4. Penzugyi tranzakcios adatok helyi pending masolata minimum 31 napig, szerveroldali archivuma minimum 8 evig megorzendo.
5. Arfolyam kozponti szerkesztes + publikacio + irodakra terites.
6. Vetel/eladas/ertektar/foertektar uzleti logika nem serulhet.
7. Idempotens szinkron kotelezo (duplikalt vegrehajtas tilos).
8. Audit trail kotelezo minden kritikus muveletre.
9. Rollback-kepes release folyamat kotelezo.

---

## 2. Javasolt celarchitektura (reference architecture)

## 2.1. Edge (irodai) reteg

- Electron Desktop App (penztar-client)
- Local DB (SQLite vagy PostgreSQL local node)
- Local Queue (outbox/inbox)
- Kamera local recorder service
- Device bridge (nyomtato/scanner/camera IPC)
- Sync agent

## 2.2. Kozponti reteg

- Spring Boot backend (modularis monolit)
- PostgreSQL primary (HA + PITR)
- Object storage (kamera + scan)
- Message broker (NATS/Kafka opcion)
- Monitoring stack (metrics, logs, traces)

## 2.3. Bounded context-ek

1. IdentityAccess
2. CustomerCompliance
3. RateManagement
4. TradeExecution
5. Treasury
6. CameraEvidence
7. SyncOrchestration
8. Reporting
9. AuditCompliance

---

## 3. Celszerkezet a repository-ben

```text
backend/
  src/main/java/hu/puzzleir/valuta/
    identity/
    compliance/
    rate/
    trade/
    treasury/
    camera/
    sync/
    reporting/
    audit/
    shared/
penztar-client/
  src/
    app/
    modules/
      trade/
      treasury/
      rates/
      camera/
      sync/
    infrastructure/
      api/
      ws/
      localdb/
      ipc/
      queue/
    domain/
      entities/
      services/
      policies/
database/
  migrations/
  schema/
docs/
  AI_EXECUTION_MASTERPLAN.md
```

---

## 4. Kodolasi standardok (AI kotelezo szabalykonyv)

1. Minden valtoztatas feature branch-ben.
2. Minden commit egyetlen temahoz kotott.
3. Minden endpoint valtozas melle OpenAPI update kotelezo.
4. Minden DB migration csak append-only (soha nem editalunk regi migrationt).
5. Minden integracios valtozashoz smoke test kotelezo.
6. Minden critical flow valtozashoz regresszios teszt kotelezo.
7. Soha ne hasznalj destructive SQL-t data migration terv nelkul.
8. Soha ne hasznalj hard delete audit-koteles adatra.

AI vegrehajtas sorren:
1. Kontextus olvasas.
2. Tervezett valtozas lista.
3. Kod.
4. Teszt.
5. Lint/typecheck.
6. Smoke.
7. Dokumentacio update.

---

## 5. Domain invariansok (uzleti logika vedelme)

1. Tranzakcio azonosito globalisan egyedi.
2. Tranzakcio allapotgep:
- CREATED -> VALIDATED -> EXECUTED -> (SYNCED | FAILED_SYNC)
- STORNO csak EXECUTED-re engedett.
3. Ertektari mozgas nem eredmenyezhet negativ keszletet jovahagyas nelkul.
4. Arfolyam publikacio csak APPROVED sablonbol mehet.
5. Egy valuta + workgroup + aktiv idointervallum kombinacio csak egy aktiv arfolyam lehet.
6. Kamera felvetel torles csak retention policy altal.
7. Audit event nem modosithato, csak append.
8. Penzugyi tranzakcio, bizonylat es archiv rekord hard delete nem engedett; csak soft-archive vagy append-only naplozas megengedett.

---

## 6. Adatmodell (minimum szukseges tablak)

## 6.1. Sync/outbox

```sql
CREATE TABLE sync_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    idempotency_key VARCHAR(120) NOT NULL UNIQUE,
    payload JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    retry_count INTEGER NOT NULL DEFAULT 0,
    next_retry_at TIMESTAMP
);

CREATE INDEX idx_sync_outbox_status_next_retry
ON sync_outbox(status, next_retry_at);
```

## 6.2. Sync/inbox

```sql
CREATE TABLE sync_inbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key VARCHAR(120) NOT NULL UNIQUE,
    source_node_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload_hash VARCHAR(128) NOT NULL,
    received_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'RECEIVED'
);
```

## 6.3. Kamera meta

```sql
CREATE TABLE camera_recording (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL,
    camera_id VARCHAR(50) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    local_path VARCHAR(500) NOT NULL,
    remote_path VARCHAR(500),
    encrypted BOOLEAN NOT NULL DEFAULT true,
    file_size_bytes BIGINT,
    checksum_sha256 VARCHAR(128),
    retention_until DATE NOT NULL,
    upload_status VARCHAR(30) NOT NULL DEFAULT 'PENDING'
);

CREATE INDEX idx_camera_recording_branch_time
ON camera_recording(branch_id, start_time);
```

## 6.4. Arfolyam publikacio

```sql
CREATE TABLE rate_publication (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    publication_code VARCHAR(40) NOT NULL UNIQUE,
    workgroup_id UUID NOT NULL,
    published_by BIGINT NOT NULL,
    published_at TIMESTAMP NOT NULL DEFAULT NOW(),
    effective_from TIMESTAMP NOT NULL,
    version_no BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE rate_publication_item (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    publication_id UUID NOT NULL REFERENCES rate_publication(id) ON DELETE CASCADE,
    currency_code VARCHAR(10) NOT NULL,
    buy_rate NUMERIC(18,6) NOT NULL,
    sell_rate NUMERIC(18,6) NOT NULL,
    rounding_rule INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX uq_rate_active_workgroup_version
ON rate_publication(workgroup_id, version_no);
```

---

## 7. API contract szabvany

## 7.1. Idempotency header kotelezo

- Header: `Idempotency-Key`
- Formatum: UUIDv7 vagy ULID
- Hianyaban: `400 BAD_REQUEST`

## 7.2. Hibavalasz schema

```json
{
  "timestamp": "2026-03-14T11:00:00Z",
  "path": "/api/v1/trade/execute",
  "code": "BUSINESS_RULE_VIOLATION",
  "message": "Negative stock would occur",
  "details": {
    "branchId": "...",
    "currency": "EUR"
  },
  "traceId": "..."
}
```

## 7.3. Arfolyam publikacio endpoint

```http
POST /api/v1/rate-management/publications
Authorization: Bearer <JWT>
Idempotency-Key: <uuid>
Content-Type: application/json

{
  "workgroupId": "...",
  "effectiveFrom": "2026-03-14T12:00:00Z",
  "items": [
    {
      "currencyCode": "EUR",
      "buyRate": 394.20,
      "sellRate": 398.10,
      "roundingRule": 1
    }
  ]
}
```

Valasz:

```json
{
  "publicationId": "...",
  "versionNo": 184,
  "status": "ACTIVE"
}
```

---

## 8. Event contract szabvany

## 8.1. Kozos envelope

```json
{
  "eventId": "uuid",
  "eventType": "RATE_PUBLISHED",
  "source": "hq-backend",
  "occurredAt": "2026-03-14T11:00:00Z",
  "idempotencyKey": "uuid",
  "payload": {}
}
```

## 8.2. RATE_PUBLISHED payload

```json
{
  "publicationId": "...",
  "workgroupId": "...",
  "versionNo": 184,
  "effectiveFrom": "2026-03-14T12:00:00Z",
  "rates": [
    { "currencyCode": "EUR", "buyRate": 394.2, "sellRate": 398.1 }
  ]
}
```

## 8.3. TRADE_EXECUTED payload

```json
{
  "transactionId": "...",
  "branchId": "...",
  "type": "BUY",
  "currencyCode": "EUR",
  "foreignAmount": 1500.00,
  "hufAmount": 591300.00,
  "executedAt": "2026-03-14T11:01:00Z"
}
```

---

## 9. Kamera subsystem implementacios terv (vegrehajthato)

## 9.1. Edge recorder folyamat

1. App startkor kamera discovery.
2. Konfig validacio (resolution/fps).
3. Segment writer inditas (1 oras rotacio).
4. Frame capture loop.
5. Encrypted write + checksum update.
6. Segment close + metadata persist.
7. Upload queue-ba helyezes.

## 9.2. Java service skeleton

```java
@Service
@RequiredArgsConstructor
public class CameraRecorderService {

    private final CameraSegmentRepository segmentRepository;
    private final CameraEncryptionService encryptionService;

    public UUID startSegment(String cameraId, UUID branchId, Instant startTime) {
        CameraSegment segment = CameraSegment.start(cameraId, branchId, startTime);
        segmentRepository.save(segment);
        return segment.getId();
    }

    public void appendFrame(UUID segmentId, byte[] jpegFrame, Instant frameTime) {
        // 1) encrypt
        byte[] encrypted = encryptionService.encryptFrame(segmentId, jpegFrame);
        // 2) append file
        // 3) update in-memory checksum + counters
        // 4) periodic flush
    }

    public void closeSegment(UUID segmentId, Instant endTime) {
        // final checksum, size, status=COMPLETED
    }
}
```

## 9.3. Retention worker

```java
@Scheduled(cron = "0 15 2 * * *")
@Transactional
public void enforceRetention() {
    LocalDate today = LocalDate.now(ZoneOffset.UTC);
    List<CameraRecording> expired = repo.findExpired(today);
    for (CameraRecording item : expired) {
        storage.deleteLocal(item.getLocalPath());
        storage.deleteRemoteIfExists(item.getRemotePath());
        audit.log("CAMERA_RETENTION_DELETE", item.getId().toString());
        repo.delete(item);
    }
}
```

## 9.4. Tesztek

- Unit: encryption, checksum, retention policy
- Integration: segment lifecycle + DB metadata
- E2E: transaction -> recording link lookup by receipt

---

## 10. Arfolyam subsystem implementacios terv (vegrehajthato)

## 10.1. Workflow

1. DRAFT letrehozas
2. APPROVE (4-eye opcion)
3. PUBLISH (version increment)
4. Event broadcast + sync fallback
5. Branch apply + ack

## 10.2. Publikalasi tranzakcio (Java)

```java
@Transactional
public RatePublicationResult publish(RatePublishCommand cmd) {
    RateTemplate template = templateRepo.lockApproved(cmd.templateId());
    long nextVersion = publicationRepo.nextVersion(template.getWorkgroupId());

    RatePublication publication = RatePublication.create(
        template.getWorkgroupId(),
        nextVersion,
        cmd.effectiveFrom(),
        currentUserId()
    );

    publicationRepo.save(publication);
    publicationItemRepo.saveAll(mapItems(publication.getId(), template.getItems()));

    eventOutbox.enqueue(
        "RATE_PUBLISHED",
        publication.getId().toString(),
        publication.toEventPayload(),
        cmd.idempotencyKey()
    );

    audit.log("RATE_PUBLISHED", publication.getId().toString());
    return new RatePublicationResult(publication.getId(), nextVersion, "ACTIVE");
}
```

## 10.3. Client oldali apply (TypeScript)

```ts
export async function applyRatePublication(msg: RatePublishedEvent): Promise<void> {
  const current = await localRateStore.getVersion(msg.workgroupId);
  if (current >= msg.versionNo) return;

  await localDb.transaction(async (tx) => {
    await tx.rateItems.replaceForWorkgroup(msg.workgroupId, msg.rates, msg.versionNo);
    await tx.rateVersion.upsert(msg.workgroupId, msg.versionNo, msg.effectiveFrom);
    await tx.outboxAck.insert({ eventId: msg.eventId, ackAt: new Date().toISOString() });
  });
}
```

---

## 11. Offline-first szinkron protokoll

## 11.1. Kulcs elvek

1. Minden kuldes idempotens.
2. Minden fogadas deduplikalt.
3. Retry exponential backoff.
4. Poison message kulon dead-letter tarolo.

## 11.2. Retry policy

```yaml
retryPolicy:
  maxAttempts: 12
  initialDelaySec: 5
  multiplier: 2
  jitter: true
  maxDelaySec: 900
  deadLetterAfterAttempts: 12
```

## 11.3. Sync worker pseudocode

```text
loop every 5 sec:
  pending = outbox.findReady(limit=100)
  for event in pending:
    response = send(event)
    if response == 200/201:
      outbox.markSent(event)
    else if response in [409, 422] and idempotentConflict:
      outbox.markSent(event)
    else:
      outbox.scheduleRetry(event)
```

---

## 12. Security hardening terv

1. JWT + refresh token rotacio.
2. Device-bound token penztargephez.
3. mTLS opcion branch-gateway es kozpont kozott.
4. AES-256-GCM local titkositas kamera es scan fajlokra.
5. Kulcskezeles: kulcsok rendszeres forgatasa.
6. Sensitive mezok hash + maszkelt logolas.
7. Audit trail append-only tablaban.

## 12.1. Audit event schema

```json
{
  "auditId": "uuid",
  "actorId": "worker-123",
  "actorRole": "HEAD_TREASURER",
  "action": "RATE_PUBLISHED",
  "resourceType": "RATE_PUBLICATION",
  "resourceId": "...",
  "before": {},
  "after": {},
  "ip": "...",
  "userAgent": "...",
  "createdAt": "..."
}
```

---

## 13. Observability es SRE baseline

## 13.1. Metrikak

- Trade latency p95/p99
- Sync lag branch-enkent
- Outbox backlog meret
- Kamera uptime kameraID szerint
- Kamera upload sikeresseg
- Rate publication propagation ido

## 13.2. Riasztasi szabalyok

1. Kamera offline > 2 perc (warning)
2. Kamera offline > 10 perc (critical)
3. Outbox backlog > 5000 event (critical)
4. Sync lag > 15 perc (critical)
5. DB connection error rate > 5% (critical)

---

## 14. CI/CD pipeline kovetelmenyek

## 14.1. Backend pipeline

1. `mvn -q -DskipTests=false test`
2. static analysis
3. migration dry-run
4. container build
5. smoke deploy to staging
6. contract tests

## 14.2. Electron pipeline

1. `npm ci`
2. `npm run typecheck`
3. `npm run test`
4. `npm run build`
5. IPC contract check
6. signed artifact

## 14.3. IPC contract gate

Parancs:

```bash
npm run check:ipc
```

Sikertelen, ha preload invoke csatornahoz nincs main handler.

---

## 15. Vegrehajtasi fazisok (12-20 het)

## Fazis A - Stabilizacio (2-3 het)

Kimenet:
- CI gate-k egysitese
- IPC contract gate aktiv
- Sync alap outbox/inbox bevezetese

Feladatok:
1. Outbox/inbox tablakat migralni.
2. Sync worker skeleton implementalni.
3. Regresszios tesztcsomag bovites.

DoD:
- Nincs regresszio critical flow-ban.
- Outbox dead-letter logika tesztelve.

## Fazis B - Kamera production grade (3-5 het)

Kimenet:
- Folyamatos rogzites, encrypted tarolas, retention.

Feladatok:
1. Segment writer productionositas.
2. Upload queue + retry.
3. Playback API + search by receipt.
4. Audit log bevezetes.

DoD:
- 72 oras soak test hiba nelkul.
- Retention worker validalt.

## Fazis C - Rate management end-to-end (3-4 het)

Kimenet:
- DRAFT/APPROVE/PUBLISH workflow.
- Branch update WS + polling fallback.

Feladatok:
1. Versioned publication modell.
2. Publish event outbox.
3. Branch apply + ACK.

DoD:
- Arfolyam terites < 30 sec median.
- Version conflict kezeles tesztelt.

## Fazis D - Treasury hardening (2-4 het)

Kimenet:
- Keszlet invariansok megerositese.
- Reconciliation folyamat.

Feladatok:
1. Negative stock guard.
2. Storno policy formalizalas.
3. Daily close consistency check.

DoD:
- Ledger consistency report pass.

## Fazis E - Rollout 100 penztarig (2-4 het)

Kimenet:
- Hullamos rollout + visszaallas.

Feladatok:
1. Pilot 5 iroda.
2. Wave1 20 iroda.
3. Wave2 40 iroda.
4. Wave3 teljes fleet.

DoD:
- RTO/RPO gyakorlat sikeres.
- Minden wave utan postmortem checklist pass.

---

## 16. AI agent szigoru vegrehajtasi utasitasok (copy-paste runbook)

1. Soha ne erintsd a mar deployolt migration fajlokat.
2. Uj migration csak uj verzioval.
3. Minden endpoint valtozas utan OpenAPI diff check.
4. Minden domain service valtozas utan:
- unit test
- integration test
- smoke test
5. Minden frontend IPC valtozas utan `npm run check:ipc` kotelezo.
6. Ha teszt bukik:
- celzott javitas
- ujrafuttatas
- csak utana tovabblepes
7. Ha konfliktus van domain invarianssal, invarians az erossebb.
8. Ha ketertelmu uzleti szabaly: stop + dokumentalt kerdeslista.

---

## 17. Prompt template nagy modellekhez

## 17.1. Feature implementacios prompt

```text
Feladat: <feature-nev>
Kontextus: docs/AI_EXECUTION_MASTERPLAN.md megfelelo fejezet
Korlatozasok:
- Nem torheto uzleti invarians
- Migration append-only
- Idempotencia kotelezo
Teendok:
1) Kod valtoztatasok listaja
2) Fajlonkenti patch
3) Tesztek
4) Smoke
5) Dokumentacio update
Kimenet:
- Modositott fajlok listaja
- Futtatott parancsok
- Teszteredmenyek
- Nyitott kockazatok
```

## 17.2. Bugfix prompt

```text
Hiba: <hiba leiras>
Elvart viselkedes: <elvart>
Aktualis viselkedes: <aktualis>
Szigoru utasitas:
- Eloszor reprodukcio
- Majd minimalis javitas
- Majd regresszios teszt hozzaadas
- Majd teljes ellenorzes
```

---

## 18. Konkret kodreszletek (gyors indulashoz)

## 18.1. Spring idempotency filter

```java
@Component
public class IdempotencyFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
        throws ServletException, IOException {

        if ("POST".equalsIgnoreCase(req.getMethod()) || "PUT".equalsIgnoreCase(req.getMethod())) {
            String key = req.getHeader("Idempotency-Key");
            if (key == null || key.isBlank()) {
                res.setStatus(HttpStatus.BAD_REQUEST.value());
                res.getWriter().write("Missing Idempotency-Key");
                return;
            }
        }
        chain.doFilter(req, res);
    }
}
```

## 18.2. React offline queue hook

```ts
export function useSyncQueue() {
  const [running, setRunning] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function tick() {
      if (cancelled) return;
      setRunning(true);
      try {
        const pending = await queueRepo.findReady(100);
        for (const item of pending) {
          await syncTransport.send(item);
          await queueRepo.markDone(item.id);
        }
      } catch {
        // retry by scheduler
      } finally {
        setRunning(false);
      }
    }

    const id = setInterval(tick, 5000);
    void tick();
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  return { running };
}
```

## 18.3. Kamera kapcsolas tranzakciohoz

```java
public void linkTransactionToRecording(UUID transactionId, String receiptNumber, Instant txTime, UUID branchId) {
    CameraRecording active = recordingRepo.findByBranchAndTime(branchId, txTime)
        .orElseThrow(() -> new IllegalStateException("No active recording segment"));

    CameraTransactionLink link = new CameraTransactionLink();
    link.setRecordingId(active.getId());
    link.setTransactionId(transactionId);
    link.setReceiptNumber(receiptNumber);
    link.setTransactionTime(txTime);
    linkRepo.save(link);
}
```

---

## 19. Elfogadasi kriteriumok (production readiness)

1. 30 nap pilot alatt zero data loss.
2. Kamera segment hiany arany < 0.1%.
3. Sync success ratio > 99.95%.
4. Rate propagation p95 < 60 sec.
5. Critical tranzakcios hibaarany < 0.01%.
6. Daily close consistency pass rate 100%.

---

## 20. Dontesi matrix: incremental vs full transformation

Incremental valaszd, ha:
- fontos a gyors kockazatcsokkentes
- fontos a meglevo logika megtartasa
- limitált a leallas tolerancia

Full transformation valaszd, ha:
- kulon csapatok vannak domainenkent
- eros architecture runway elerheto
- vallalhato a hosszabb atallasi ido

Ajánlas: kezdd incremental mode-ban, de a kodot full transformation kompatibilis struktura szerint epitsd.

---

## 21. Vegso utasitas AI modellnek

Barmely implementacios feladatnal kotelezo output:
1. Mit valtoztattal es miert.
2. Melyik invariansokat vedted.
3. Milyen teszt futott.
4. Milyen kockazat maradt.
5. Mi a rollback terv.

Ha barmelyik pont hianyzik, a feladat NEM tekintheto kesznek.
