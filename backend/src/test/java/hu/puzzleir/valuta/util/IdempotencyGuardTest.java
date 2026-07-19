package hu.puzzleir.valuta.util;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Audit P0.5 (2026-05-03) regressziovedelem.
 *
 * <p>Bizonyitja:</p>
 * <ul>
 *   <li>(1) ujonnan lattunk key-t -> PROCESSING entry insertelve;</li>
 *   <li>(2) korabbi COMPLETED key + ugyanaz payload -> cache hit;</li>
 *   <li>(3) korabbi COMPLETED key + MAS payload -> 409 ConflictException;</li>
 *   <li>(4) korabbi PROCESSING key (in-flight) -> ValidationException;</li>
 *   <li>(5) korabbi FAILED key -> uj PROCESSING start engedelyezett;</li>
 *   <li>(6) hianyzo idempotencyKey -> no-op (backward compat);</li>
 *   <li>(7) complete()/fail() update-eli a status-t.</li>
 *   <li>(9)-(10) tulhosszu vagy control-charos kulcs -> 400 DB/audit hivas nelkul;</li>
 *   <li>(11)-(14) minden COMPLETED cache-hit utvonal IDEMPOTENCY_CACHE_HIT auditot ir.</li>
 * </ul>
 */
class IdempotencyGuardTest {

    private record FakeDto(String value, int amount) {}

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final String ENDPOINT = "POST /api/v1/transactions/buy";
    private static final String KEY = "client-uuid-123";

    private IdempotencyRecordRepository repository;
    private ObjectMapper objectMapper;
    private AuditLogService auditLogService;
    private IdempotencyGuard guard;

    @BeforeEach
    void setUp() {
        repository = Mockito.mock(IdempotencyRecordRepository.class);
        objectMapper = new ObjectMapper();
        auditLogService = Mockito.mock(AuditLogService.class);
        guard = new IdempotencyGuard(repository, objectMapper, auditLogService);
    }

    @Test
    @DisplayName("(1) uj key -> PROCESSING entry save-elve, cachedResult == null")
    void newKey_createsProcessingRecord() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.empty());
            when(repository.save(any(IdempotencyRecord.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            IdempotencyGuard.Acquired<FakeDto> acquired =
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);

            assertThat(acquired.cachedResult()).isNull();
            assertThat(acquired.record()).isNotNull();
            assertThat(acquired.record().getStatus()).isEqualTo(IdempotencyRecord.Status.PROCESSING);
            assertThat(acquired.record().getRequestHash()).isNotBlank();
            verify(repository, times(1)).save(any(IdempotencyRecord.class));
        }
    }

    @Test
    @DisplayName("(2) COMPLETED key + ugyanaz payload -> cache hit")
    void completedKey_samePayload_cacheHit() throws Exception {
        FakeDto cached = new FakeDto("buy", 100);
        String hash = computeHash(new FakeDto("buy", 100));
        IdempotencyRecord existing = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(hash)
                .status(IdempotencyRecord.Status.COMPLETED)
                .responseJson(objectMapper.writeValueAsString(cached))
                .createdAt(Instant.now().minusSeconds(60))
                .completedAt(Instant.now().minusSeconds(50))
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(existing));

            IdempotencyGuard.Acquired<FakeDto> acquired =
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);

            assertThat(acquired.cachedResult()).isEqualTo(cached);
            verify(repository, Mockito.never()).save(any());
        }
    }

    @Test
    @DisplayName("(3) COMPLETED key + MAS payload -> 409 ConflictException")
    void completedKey_differentPayload_throws409() throws Exception {
        IdempotencyRecord existing = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.COMPLETED)
                .responseJson(objectMapper.writeValueAsString(new FakeDto("buy", 100)))
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(existing));

            assertThatThrownBy(() ->
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 999), FakeDto.class))
                    .isInstanceOf(ConflictException.class)
                    .hasMessageContaining("different request payload");
        }
    }

    @Test
    @DisplayName("(4) PROCESSING key in-flight -> 409-re mappelhető ConflictException")
    void processingKey_inFlight_throwsConflict() {
        IdempotencyRecord existing = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.PROCESSING)
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(existing));

            assertThatThrownBy(() ->
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class))
                    .isInstanceOf(ConflictException.class)
                    .hasMessageContaining("feldolgozas alatt");
        }
    }

    @Test
    @DisplayName("(5) FAILED key -> uj PROCESSING start engedelyezett (lock + double-check)")
    void failedKey_allowsRetry() {
        IdempotencyRecord failed = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.FAILED)
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(failed));
            // Codex P1 PR #358 follow-up: a FAILED branch most pesszimista lock-ot kerdez.
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(failed));
            when(repository.save(any(IdempotencyRecord.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            IdempotencyGuard.Acquired<FakeDto> acquired =
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);

            assertThat(acquired.cachedResult()).isNull();
            assertThat(acquired.record().getStatus()).isEqualTo(IdempotencyRecord.Status.PROCESSING);
            verify(repository, times(1)).save(any());
            verify(repository, times(1))
                    .findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(COMPANY_ID, ENDPOINT, KEY);
        }
    }

    @Test
    @DisplayName("Codex P1 PR #358: FAILED retry race — second caller meglatja a PROCESSING-et a lock utan")
    void failedKeyRetryRace_secondCallerSeesProcessing_throwsConflict() {
        IdempotencyRecord failedBeforeLock = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.FAILED)
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        // Egy masik retry mar PROCESSING-re allitotta a lock megszerzese elott.
        IdempotencyRecord nowProcessing = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.PROCESSING)
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(failedBeforeLock));
            // A FOR UPDATE az atomi double-check-et szimulalja: a masik retry mar update-elte.
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(nowProcessing));

            assertThatThrownBy(() ->
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class))
                    .as("FAILED retry race: a masik retry mar PROCESSING-en — mi varjuk a 4xx-et")
                    .isInstanceOf(ConflictException.class)
                    .hasMessageContaining("feldolgozas alatt");
            verify(repository, Mockito.never()).save(any());
        }
    }

    @Test
    @DisplayName("(6) hianyzo idempotencyKey -> no-op (backward compat)")
    void blankKey_noOp() {
        IdempotencyGuard.Acquired<FakeDto> acquired =
                guard.tryAcquire(null, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);
        assertThat(acquired.cachedResult()).isNull();
        assertThat(acquired.record()).isNull();

        IdempotencyGuard.Acquired<FakeDto> acquired2 =
                guard.tryAcquire("  ", ENDPOINT, new FakeDto("buy", 100), FakeDto.class);
        assertThat(acquired2.record()).isNull();
        verify(repository, Mockito.never()).save(any());
    }

    @Test
    @DisplayName("(7) complete() update-eli a status-t COMPLETED-re + JSON-t")
    void complete_updatesStatusAndJson() throws Exception {
        IdempotencyRecord rec = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .status(IdempotencyRecord.Status.PROCESSING)
                .requestHash("dummy")
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        IdempotencyGuard.Acquired<FakeDto> acquired =
                new IdempotencyGuard.Acquired<>(rec, null, FakeDto.class);
        FakeDto result = new FakeDto("buy", 250);

        guard.complete(acquired, result);

        assertThat(rec.getStatus()).isEqualTo(IdempotencyRecord.Status.COMPLETED);
        assertThat(rec.getResponseJson()).isEqualTo(objectMapper.writeValueAsString(result));
        assertThat(rec.getCompletedAt()).isNotNull();
        verify(repository, times(1)).save(rec);
    }

    @Test
    @DisplayName("(8) fail() update-eli a status-t FAILED-re — engedi a kesobbi retry-t")
    void fail_updatesStatusToFailed() {
        IdempotencyRecord rec = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .status(IdempotencyRecord.Status.PROCESSING)
                .requestHash("dummy")
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        IdempotencyGuard.Acquired<FakeDto> acquired =
                new IdempotencyGuard.Acquired<>(rec, null, FakeDto.class);

        guard.fail(acquired);

        assertThat(rec.getStatus()).isEqualTo(IdempotencyRecord.Status.FAILED);
        assertThat(rec.getCompletedAt()).isNotNull();
        verify(repository, times(1)).save(rec);
    }

    @Test
    @DisplayName("(9) 255-nel hosszabb kulcs -> ValidationException, DB-hivas nelkul")
    void overlongKey_throwsValidation_withoutRepositoryAccess() {
        String longKey = "k".repeat(300);

        assertThatThrownBy(() ->
                guard.tryAcquire(longKey, ENDPOINT, new FakeDto("buy", 100), FakeDto.class))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Idempotency-Key");
        Mockito.verifyNoInteractions(repository, auditLogService);
    }

    @Test
    @DisplayName("(10) control karaktert tartalmazo kulcs -> ValidationException")
    void controlCharKey_throwsValidation() {
        assertThatThrownBy(() ->
                guard.tryAcquire("abc\ndef", ENDPOINT, new FakeDto("buy", 100), FakeDto.class))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Idempotency-Key");
        Mockito.verifyNoInteractions(repository, auditLogService);
    }

    @Test
    @DisplayName("(11) COMPLETED cache-hit -> IDEMPOTENCY_CACHE_HIT audit-esemeny irodik")
    void completedCacheHit_writesAuditEvent() throws Exception {
        FakeDto cached = new FakeDto("buy", 100);
        IdempotencyRecord existing = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.COMPLETED)
                .responseJson(objectMapper.writeValueAsString(cached))
                .createdAt(Instant.now().minusSeconds(60))
                .completedAt(Instant.now().minusSeconds(50))
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(existing));

            guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);

            verify(auditLogService, times(1)).log(
                    eq("IDEMPOTENCY_CACHE_HIT"),
                    eq("IDEMPOTENCY"),
                    anyString(),
                    any(),
                    isNull(),
                    isNull(),
                    isNull(),
                    contains(ENDPOINT),
                    isNull(),
                    isNull());
        }
    }

    @Test
    @DisplayName("(12) uj kulcs acquire (nem replay) -> NINCS audit-esemeny")
    void newKeyAcquire_writesNoAuditEvent() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.empty());
            when(repository.save(any(IdempotencyRecord.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);

            Mockito.verifyNoInteractions(auditLogService);
        }
    }

    @Test
    @DisplayName("(13) FAILED-lock utani COMPLETED cache-hit -> audit-esemeny ott is irodik")
    void failedLockPathCompletedCacheHit_writesAuditEvent() throws Exception {
        FakeDto cached = new FakeDto("buy", 100);
        IdempotencyRecord failedBeforeLock = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.FAILED)
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        IdempotencyRecord nowCompleted = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.COMPLETED)
                .responseJson(objectMapper.writeValueAsString(cached))
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(failedBeforeLock));
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.of(nowCompleted));

            IdempotencyGuard.Acquired<FakeDto> acquired =
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);

            assertThat(acquired.cachedResult()).isEqualTo(cached);
            verify(auditLogService, times(1)).log(
                    eq("IDEMPOTENCY_CACHE_HIT"),
                    eq("IDEMPOTENCY"),
                    anyString(),
                    any(),
                    isNull(),
                    isNull(),
                    isNull(),
                    contains(ENDPOINT),
                    isNull(),
                    isNull());
        }
    }

    @Test
    @DisplayName("(14) race read-back COMPLETED cache-hit -> audit-esemeny ott is irodik")
    void racePathCompletedCacheHit_writesAuditEvent() throws Exception {
        FakeDto cached = new FakeDto("buy", 100);
        IdempotencyRecord completedByOther = IdempotencyRecord.builder()
                .companyId(COMPANY_ID).endpoint(ENDPOINT).idempotencyKey(KEY)
                .requestHash(computeHash(new FakeDto("buy", 100)))
                .status(IdempotencyRecord.Status.COMPLETED)
                .responseJson(objectMapper.writeValueAsString(cached))
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndEndpointAndIdempotencyKey(COMPANY_ID, ENDPOINT, KEY))
                    .thenReturn(Optional.empty())
                    .thenReturn(Optional.of(completedByOther));
            when(repository.save(any(IdempotencyRecord.class)))
                    .thenThrow(new org.springframework.dao.DataIntegrityViolationException("dup"));

            IdempotencyGuard.Acquired<FakeDto> acquired =
                    guard.tryAcquire(KEY, ENDPOINT, new FakeDto("buy", 100), FakeDto.class);

            assertThat(acquired.cachedResult()).isEqualTo(cached);
            verify(auditLogService, times(1)).log(
                    eq("IDEMPOTENCY_CACHE_HIT"),
                    eq("IDEMPOTENCY"),
                    anyString(),
                    any(),
                    isNull(),
                    isNull(),
                    isNull(),
                    contains(ENDPOINT),
                    isNull(),
                    isNull());
        }
    }

    private String computeHash(Object o) {
        try {
            String body = objectMapper.writeValueAsString(o);
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(body.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
