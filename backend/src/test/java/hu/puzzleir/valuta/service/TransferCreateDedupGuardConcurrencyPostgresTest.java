package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-028 6. kör (Codex HIGH — módszertani követelmény): a TransferCreateDedupGuard
 * VALÓDI Spring-proxy-határokkal és VALÓDI Postgres-zárakkal futó konkurencia-tesztje.
 * A unit-szintű (kézzel példányosított) tesztek a @Transactional(REQUIRES_NEW)
 * szemantikát nem tudják bizonyítani — ez a teszt két tényleges párhuzamos szálról/
 * tranzakcióból hívja az acquire()-t.
 *
 * <p>CI-ben fut (lokálisan a Docker-hiány miatt a Testcontainers-baseline része);
 * a névkonvenció szándékosan *Test (az *IT-t a CI nem futtatja — FK-068 tanulság).</p>
 */
@Testcontainers
@Import(TransferCreateDedupGuard.class)
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class TransferCreateDedupGuardConcurrencyPostgresTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private TransferCreateDedupGuard guard;
    @Autowired private IdempotencyRecordRepository repository;
    @Autowired private JdbcTemplate jdbcTemplate;

    private final UUID companyId = UUID.randomUUID();
    private static final String KEY = "fkh028-concurrency-key";

    @BeforeEach
    void setUp() {
        repository.deleteAll();
        // A V175-ös unique index pótlása (a create-drop séma a Flyway-indexet nem hozza létre)
        // — az insert-race ág DB-oldali garanciája ettől valódi.
        jdbcTemplate.execute("CREATE UNIQUE INDEX IF NOT EXISTS idempotency_record_unique_idx "
                + "ON idempotency_record (company_id, endpoint, idempotency_key)");
    }

    private void seedRecord(IdempotencyRecord.Status status, Instant createdAt, Instant completedAt) {
        repository.save(IdempotencyRecord.builder()
                .companyId(companyId)
                .endpoint(TransferCreateDedupGuard.ENDPOINT)
                .idempotencyKey(KEY)
                .requestHash(KEY)
                .status(status)
                .createdAt(createdAt)
                .completedAt(completedAt)
                .expiresAt(Instant.now().plus(1, ChronoUnit.HOURS))
                .build());
    }

    /** Két párhuzamos acquire ugyanarra a kulcsra — pontosan EGY nyerhet. */
    private void assertExactlyOneWins() throws Exception {
        CountDownLatch startGun = new CountDownLatch(1);
        AtomicInteger successes = new AtomicInteger();
        AtomicInteger conflicts = new AtomicInteger();
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Runnable attempt = () -> {
                try {
                    startGun.await(10, TimeUnit.SECONDS);
                    guard.acquire(companyId, KEY);
                    successes.incrementAndGet();
                } catch (ConflictException e) {
                    conflicts.incrementAndGet();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            };
            Future<?> a = executor.submit(attempt);
            Future<?> b = executor.submit(attempt);
            startGun.countDown();
            a.get(30, TimeUnit.SECONDS);
            b.get(30, TimeUnit.SECONDS);
        } finally {
            executor.shutdownNow();
        }

        assertThat(successes.get())
                .as("Pontosan EGY szál foglalhatja el a kulcsot")
                .isEqualTo(1);
        assertThat(conflicts.get())
                .as("A másik szál konfliktust kap")
                .isEqualTo(1);
        assertThat(repository.findByCompanyIdAndEndpointAndIdempotencyKey(
                        companyId, TransferCreateDedupGuard.ENDPOINT, KEY))
                .hasValueSatisfying(rec ->
                        assertThat(rec.getStatus()).isEqualTo(IdempotencyRecord.Status.PROCESSING));
    }

    @Test
    @DisplayName("HIGH: FAILED rekord konkurens újrafoglalása — a FOR UPDATE zár alatt pontosan egy szál nyer")
    void concurrentReacquireOfFailedRecord_exactlyOneWins() throws Exception {
        seedRecord(IdempotencyRecord.Status.FAILED,
                Instant.now().minus(1, ChronoUnit.MINUTES), Instant.now().minus(1, ChronoUnit.MINUTES));
        assertExactlyOneWins();
    }

    @Test
    @DisplayName("HIGH: lejárt-COMPLETED rekord konkurens újrafoglalása — pontosan egy szál nyer")
    void concurrentReacquireOfExpiredCompletedRecord_exactlyOneWins() throws Exception {
        seedRecord(IdempotencyRecord.Status.COMPLETED,
                Instant.now().minus(10, ChronoUnit.MINUTES), Instant.now().minus(10, ChronoUnit.MINUTES));
        assertExactlyOneWins();
    }

    @Test
    @DisplayName("Insert-race: rekord nélkül induló két konkurens acquire — a unique index dönt, egy nyer")
    void concurrentFreshInsert_exactlyOneWins() throws Exception {
        assertExactlyOneWins();
    }
}
