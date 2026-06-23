package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Competitor;
import hu.puzzleir.valuta.entity.Currency;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FK-041/II — FINDING 6 adat-integritás: a versenytárs-árfolyam upsert egyedisége valós PostgreSQL-en.
 *
 * <p>Bizonyítja, hogy a {@code V335} UNIQUE index (competitor_id, currency_id, rate_date) +
 * a service {@code INSERT ... ON CONFLICT DO UPDATE} upsert-je RACE-FREE: párhuzamos beküldés
 * ugyanarra a (versenyhely, valuta, mai dátum) hármasra sem hoz létre duplikált sort, és nem dob
 * hibát. Külön ellenőrzi, hogy a UNIQUE constraint a séma szintjén tényleg él (nyers duplikátum
 * elutasítva), és hogy az UPDATE-ág megőrzi a {@code created_by}/{@code created_at} eredeti értékét.</p>
 *
 * <p>A séma a JPA entitásokból (ddl-auto=create-drop) jön, így a {@code CompetitorRate}
 * {@code @UniqueConstraint} fedezete is verifikált. Docker-igényes — lokálisan jellemzően skip,
 * CI-ben fut (lásd {@link WorkerRepositoryPostgresLockIT} mintáját).</p>
 */
@Testcontainers
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class CompetitorRateConcurrencyIT {

    private static final String SOURCE = "COMPETITOR_WATCHER";

    /** Egyedi, 3 karakteres valutakód-szekvencia (T01, T02, …) a UNIQUE(code) ütközés ellen. */
    private static final AtomicInteger CURRENCY_SEQ = new AtomicInteger();

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired
    private CompetitorRateRepository competitorRateRepository;

    @Autowired
    private CompetitorRepository competitorRepository;

    @Autowired
    private CurrencyRepository currencyRepository;

    @Autowired
    private TransactionTemplate transactionTemplate;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("Párhuzamos upsert ugyanarra a (versenyhely, valuta, ma) hármasra: pontosan EGY sor, nincs hiba")
    void concurrentUpsertSameKeyProducesSingleRow() throws Exception {
        Seed seed = seedCompetitorAndCurrency();
        LocalDate today = LocalDate.now();
        int threads = 8;

        CountDownLatch startGate = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threads);
        List<Future<?>> futures = new ArrayList<>();

        try {
            for (int i = 0; i < threads; i++) {
                final long worker = 100L + i;
                final BigDecimal buy = new BigDecimal("390.00").add(new BigDecimal(i));
                final BigDecimal sell = new BigDecimal("400.00").add(new BigDecimal(i));
                futures.add(executor.submit(() -> {
                    await(startGate);
                    // Minden szál saját tranzakcióban commitol — a service @Transactional útját utánozva.
                    transactionTemplate.executeWithoutResult(status ->
                            competitorRateRepository.upsertCompetitorRate(
                                    seed.competitorId, seed.currencyId, today, buy, sell, SOURCE, worker));
                }));
            }

            startGate.countDown(); // egyszerre indítjuk a 8 párhuzamos upsert-et
            for (Future<?> f : futures) {
                f.get(20, TimeUnit.SECONDS); // bármely szál hibája itt felszínre kerül
            }
        } finally {
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS))
                    .as("a konkurencia-teszt executor szálai nem maradhatnak életben")
                    .isTrue();
        }

        Integer rows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM competitor_rates WHERE competitor_id = ? AND currency_id = ? AND rate_date = ?",
                Integer.class, seed.competitorId, seed.currencyId, today);
        assertThat(rows)
                .as("8 párhuzamos upsert után PONTOSAN egy sor lehet a hármasra (nincs duplikáció)")
                .isEqualTo(1);
    }

    @Test
    @DisplayName("ON CONFLICT UPDATE: frissíti az árfolyamot, de megőrzi a created_by/created_at eredeti értékét")
    void upsertOnConflictUpdatesValuesPreservesCreatedByAndCreatedAt() {
        Seed seed = seedCompetitorAndCurrency();
        LocalDate today = LocalDate.now();

        // 1. INSERT — eredeti rögzítő worker=11, a created_at a DB NOW()-ja.
        transactionTemplate.executeWithoutResult(status ->
                competitorRateRepository.upsertCompetitorRate(
                        seed.competitorId, seed.currencyId, today,
                        new BigDecimal("390.000000"), new BigDecimal("400.000000"), SOURCE, 11L));

        Timestamp createdAtAfterInsert = jdbcTemplate.queryForObject(
                "SELECT created_at FROM competitor_rates WHERE competitor_id = ? AND currency_id = ? AND rate_date = ?",
                Timestamp.class, seed.competitorId, seed.currencyId, today);

        // 2. UPSERT ugyanarra a kulcsra, MÁSIK worker=22, új értékekkel → ON CONFLICT UPDATE ág.
        transactionTemplate.executeWithoutResult(status ->
                competitorRateRepository.upsertCompetitorRate(
                        seed.competitorId, seed.currencyId, today,
                        new BigDecimal("391.000000"), new BigDecimal("399.000000"), SOURCE, 22L));

        Integer rows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM competitor_rates WHERE competitor_id = ? AND currency_id = ? AND rate_date = ?",
                Integer.class, seed.competitorId, seed.currencyId, today);
        assertThat(rows).as("upsert UPDATE-ág: nem keletkezik új sor").isEqualTo(1);

        jdbcTemplate.query(
                "SELECT buy_rate, sell_rate, created_by, created_at FROM competitor_rates "
                        + "WHERE competitor_id = ? AND currency_id = ? AND rate_date = ?",
                rs -> {
                    assertThat(rs.getBigDecimal("buy_rate")).isEqualByComparingTo("391.000000");
                    assertThat(rs.getBigDecimal("sell_rate")).isEqualByComparingTo("399.000000");
                    assertThat(rs.getLong("created_by"))
                            .as("UPDATE-nél az EREDETI rögzítő created_by-ja marad (nem a frissítő worker)")
                            .isEqualTo(11L);
                    assertThat(rs.getTimestamp("created_at"))
                            .as("UPDATE nem írja felül a created_at-ot")
                            .isEqualTo(createdAtAfterInsert);
                },
                seed.competitorId, seed.currencyId, today);
    }

    @Test
    @DisplayName("A séma UNIQUE constraintje él: nyers (ON CONFLICT nélküli) duplikátum INSERT elutasítva")
    void uniqueConstraintRejectsRawDuplicateInsert() {
        Seed seed = seedCompetitorAndCurrency();
        LocalDate today = LocalDate.now();

        transactionTemplate.executeWithoutResult(status ->
                competitorRateRepository.upsertCompetitorRate(
                        seed.competitorId, seed.currencyId, today,
                        new BigDecimal("390.000000"), new BigDecimal("400.000000"), SOURCE, 11L));

        assertThatThrownBy(() -> transactionTemplate.executeWithoutResult(status ->
                jdbcTemplate.update(
                        "INSERT INTO competitor_rates "
                                + "(id, competitor_id, currency_id, buy_rate, sell_rate, rate_date, source, created_by, created_at) "
                                + "VALUES (gen_random_uuid(), ?, ?, ?, ?, ?, ?, ?, NOW())",
                        seed.competitorId, seed.currencyId,
                        new BigDecimal("388.000000"), new BigDecimal("402.000000"), today, SOURCE, 22L)))
                .as("a (competitor_id, currency_id, rate_date) UNIQUE index megsértése elszáll")
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private Seed seedCompetitorAndCurrency() {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = Long.toString(System.nanoTime());

            Competitor competitor = competitorRepository.save(Competitor.builder()
                    .name("Rivál Change " + suffix)
                    .isActive(true)
                    .createdAt(now)
                    .build());

            // 3 karakteres, garantáltan egyedi valutakód a UNIQUE(code) ütközés ellen (T01, T02, …).
            String code = String.format("T%02d", CURRENCY_SEQ.incrementAndGet());
            Currency currency = currencyRepository.save(Currency.builder()
                    .code(code)
                    .name("Teszt valuta " + suffix)
                    .decimalPlaces(2)
                    .active(true)
                    .displayOrder(100)
                    .createdAt(now)
                    .build());

            return new Seed(competitor.getId(), currency.getId());
        });
    }

    private static final class Seed {
        final UUID competitorId;
        final Long currencyId;

        Seed(UUID competitorId, Long currencyId) {
            this.competitorId = competitorId;
            this.currencyId = currencyId;
        }
    }

    private static void await(CountDownLatch latch) {
        try {
            if (!latch.await(10, TimeUnit.SECONDS)) {
                throw new AssertionError("Időtúllépés a teszt-startkapu várásánál");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new AssertionError("Megszakítva a teszt-startkapu várásánál", e);
        }
    }
}
