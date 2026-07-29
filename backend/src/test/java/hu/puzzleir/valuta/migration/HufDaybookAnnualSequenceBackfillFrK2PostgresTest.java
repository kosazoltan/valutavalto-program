package hu.puzzleir.valuta.migration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.service.HufDaybookSequenceService;

import javax.sql.DataSource;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;

/**
 * FKH-022 kiegészítés FR-K2 (RED-fázis): a HUF naplókönyv éves sorszám backfill,
 * kiterjesztve a {@code transfer} táblára is.
 *
 * <p>A backfill hordozója a repo bevett mintája szerint Flyway SQL-migráció
 * (precedens: V303 transfer-serial backfill + TransferSerialSequenceServicePostgresIT).
 * A tesztek a migrációs fájlt NÉV-MINTA alapján keresik (fájlnévben "daybook" + "backfill"),
 * így a végleges V-szám nem rögzített — a teszt a verziószámtól függetlenül érvényes.</p>
 *
 * <p>RED-állapot: a backfill migráció, a {@code transfer.annual_journal_sequence} oszlop
 * és a sztornó-sorszám oszlopok ({@code storno_journal_sequence}) még nem léteznek.</p>
 */
@Testcontainers
@Import(HufDaybookSequenceService.class)
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class HufDaybookAnnualSequenceBackfillFrK2PostgresTest {

    private static final LocalDate DAY = LocalDate.of(2026, 7, 1);
    private static final int YEAR = 2026;

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private TransferRepository transferRepository;
    @Autowired private HufDaybookSequenceService hufDaybookSequenceService;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private DataSource dataSource;

    @BeforeEach
    void createSequenceTable() {
        // A huf_daybook_sequence tábla nem entity — a V360 hozza létre (idempotens).
        new ResourceDatabasePopulator(new ClassPathResource("db/migration/V360__huf_daybook_sequence.sql"))
                .execute(dataSource);
    }

    // =====================================================================
    // FR-K2 / 1. G-W-T: közös, created_at szerinti időrendi sorszámozás
    // mindkét táblán (nem táblánként külön számozva)
    // =====================================================================
    @Test
    @DisplayName("FR-K2/1: backfill — shipment és transfer FF/UF bizonylatok EGY közös created_at időrendben kapnak sorszámot; meglévő sorszám nem íródik át")
    void backfillAssignsCommonChronologicalSequenceAcrossShipmentAndTransfer() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K2T1"));
        assertThat(seed).isNotNull();
        UUID companyId = seed.company().getId();

        transactionTemplate.executeWithoutResult(status -> {
            // Meglévő, élő úton (V360 után) kiosztott sorszám: a backfill NEM írhatja át.
            saveShipment(seed, "FF-000001", "FF", DAY.atTime(7, 0), 1, null);
            // Backfillelendő, vegyes forrású, összefésült időrend:
            saveShipment(seed, "FF-000002", "FF", DAY.atTime(8, 0), null, null);
            saveTransfer(seed, "UF-000101", DAY.atTime(8, 30), false, null);
            saveTransfer(seed, "FF-000102", DAY.atTime(9, 0), false, null);
            saveShipment(seed, "UF-000003", "UF", DAY.atTime(9, 30), null, null);
        });
        upsertLastValue(companyId, 1);

        assertTransferSequenceColumnExists();
        runBackfillMigration();

        assertThat(shipmentSequence(companyId, "FF-000001"))
                .as("A meglévő (élő úton kapott) sorszám backfill után is változatlan")
                .isEqualTo(1);
        assertThat(shipmentSequence(companyId, "FF-000002"))
                .as("Az időrendben első NULL-os bizonylat a meglévő maximum után folytat")
                .isEqualTo(2);
        assertThat(transferSequence(companyId, "UF-000101"))
                .as("A transfer-bizonylat a KÖZÖS időrendben kap sorszámot (nem külön transzfer-számsor)")
                .isEqualTo(3);
        assertThat(transferSequence(companyId, "FF-000102")).isEqualTo(4);
        assertThat(shipmentSequence(companyId, "UF-000003"))
                .as("A transfer utáni shipment a közös sorban következik — a két tábla összefésülve számozódik")
                .isEqualTo(5);
        assertThat(readLastValue(companyId))
                .as("A huf_daybook_sequence.last_value a backfill után a legmagasabb kiosztott érték")
                .isEqualTo(5);
    }

    // =====================================================================
    // FR-K2 / 2. G-W-T: backfill után az élő kiosztás folytat, nincs ütközés
    // =====================================================================
    @Test
    @DisplayName("FR-K2/2: backfill után az élő sorszám-kiosztás a last_value-ból folytat, ütközés nélkül")
    void liveAllocationContinuesAfterBackfillWithoutCollision() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K2T2"));
        assertThat(seed).isNotNull();
        UUID companyId = seed.company().getId();

        transactionTemplate.executeWithoutResult(status -> {
            saveShipment(seed, "FF-000010", "FF", DAY.atTime(7, 0), null, null);
            saveTransfer(seed, "UF-000110", DAY.atTime(8, 0), false, null);
        });

        assertTransferSequenceColumnExists();
        runBackfillMigration();

        assertThat(readLastValue(companyId))
                .as("A backfill a számlálót is szinkronba hozza (2 kiosztott sorszám)")
                .isEqualTo(2);

        Integer next = transactionTemplate.execute(status ->
                hufDaybookSequenceService.next(companyId, YEAR));
        assertThat(next)
                .as("Az élő kiosztás közvetlenül a backfill legutolsó sorszáma után folytat")
                .isEqualTo(3);

        List<Integer> all = new ArrayList<>(allAssignedSequences(companyId));
        all.add(next);
        assertThat(all)
                .as("A backfillelt és az élő sorszámok halmazában nincs duplikátum")
                .doesNotHaveDuplicates();
    }

    // =====================================================================
    // FR-K2 / 3. G-W-T: a sztornó-sor SAJÁT sorszámot kap mindkét táblatípusban
    // =====================================================================
    @Test
    @DisplayName("FR-K2/3: a sztornó-sor saját, önálló sorszámot kap (cancelled_at szerinti időrendi helyén), nem az eredeti bizonylat sorszámát ismétli")
    void stornoRowsGetOwnSequenceInBothTables() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K2T3"));
        assertThat(seed).isNotNull();
        UUID companyId = seed.company().getId();

        transactionTemplate.executeWithoutResult(status -> {
            // Shipment: létrejött 08:00, sztornózva 10:00
            saveShipment(seed, "FF-000020", "FF", DAY.atTime(8, 0), null, DAY.atTime(10, 0));
            // Transfer: létrejött 09:00, sztornózva 11:00 (is_cancelled=true)
            saveTransfer(seed, "UF-000120", DAY.atTime(9, 0), true, DAY.atTime(11, 0));
        });

        assertTransferSequenceColumnExists();
        assertStornoSequenceColumnsExist();
        runBackfillMigration();

        Integer shipmentOriginal = shipmentSequence(companyId, "FF-000020");
        Integer transferOriginal = transferSequence(companyId, "UF-000120");
        Integer shipmentStorno = shipmentStornoSequence(companyId, "FF-000020");
        Integer transferStorno = transferStornoSequence(companyId, "UF-000120");

        assertThat(shipmentOriginal).as("Eredeti shipment (08:00) a közös sorban").isEqualTo(1);
        assertThat(transferOriginal).as("Eredeti transfer (09:00) a közös sorban").isEqualTo(2);
        assertThat(shipmentStorno)
                .as("A shipment sztornó-sor SAJÁT sorszáma (a cancelled_at=10:00 időrendi helyén)")
                .isEqualTo(3);
        assertThat(transferStorno)
                .as("A transfer sztornó-sor SAJÁT sorszáma (a cancelled_at=11:00 időrendi helyén)")
                .isEqualTo(4);
        assertThat(shipmentStorno).isNotEqualTo(shipmentOriginal);
        assertThat(transferStorno).isNotEqualTo(transferOriginal);
        assertThat(readLastValue(companyId)).isEqualTo(4);
    }

    // =====================================================================
    // FR-K2 / 4. G-W-T: egyidejű backfill + élő next() nem ad duplikált sorszámot
    // =====================================================================
    @Test
    @DisplayName("FR-K2/4: párhuzamos backfill-futás és élő next() hívások nem eredményeznek duplikált sorszámot (ON CONFLICT DO UPDATE)")
    void concurrentBackfillAndLiveAllocationDoNotDuplicate() throws Exception {
        Seed seed = transactionTemplate.execute(status -> seedBase("K2T4"));
        assertThat(seed).isNotNull();
        UUID companyId = seed.company().getId();

        int backfillRows = 20;
        transactionTemplate.executeWithoutResult(status -> {
            for (int i = 0; i < backfillRows; i++) {
                saveShipment(seed, String.format("FF-%06d", 200 + i), "FF",
                        DAY.atTime(8, 0).plusMinutes(i), null, null);
            }
        });

        assertTransferSequenceColumnExists();
        Resource backfill = locateBackfillMigration();

        int liveWorkers = 8;
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(4);
        List<Future<Integer>> liveFutures = new ArrayList<>();
        Future<?> backfillFuture;
        try {
            backfillFuture = executor.submit(() -> {
                assertThat(start.await(10, TimeUnit.SECONDS)).isTrue();
                new ResourceDatabasePopulator(backfill).execute(dataSource);
                return null;
            });
            for (int i = 0; i < liveWorkers; i++) {
                liveFutures.add(executor.submit(() -> {
                    assertThat(start.await(10, TimeUnit.SECONDS)).isTrue();
                    return transactionTemplate.execute(status ->
                            hufDaybookSequenceService.next(companyId, YEAR));
                }));
            }

            start.countDown();
            backfillFuture.get(60, TimeUnit.SECONDS);
            List<Integer> allocated = new ArrayList<>();
            for (Future<Integer> future : liveFutures) {
                allocated.add(future.get(30, TimeUnit.SECONDS));
            }

            List<Integer> all = new ArrayList<>(allAssignedSequences(companyId));
            all.addAll(allocated);
            assertThat(all)
                    .as("Backfill + élő kiosztás uniója: %d backfill + %d élő sorszám, duplikátum nélkül",
                            backfillRows, liveWorkers)
                    .hasSize(backfillRows + liveWorkers)
                    .doesNotHaveDuplicates();
        } finally {
            executor.shutdownNow();
            assertThat(executor.awaitTermination(10, TimeUnit.SECONDS))
                    .as("A konkurencia-teszt szálai nem maradhatnak életben")
                    .isTrue();
        }
    }

    // ============================ HELPEREK ============================

    /** A backfill Flyway-migráció név-minta alapú felkutatása (V-szám független). */
    private Resource locateBackfillMigration() {
        try {
            Resource[] all = new PathMatchingResourcePatternResolver()
                    .getResources("classpath*:db/migration/V*.sql");
            List<Resource> hits = Arrays.stream(all)
                    .filter(r -> {
                        String name = r.getFilename();
                        if (name == null) {
                            return false;
                        }
                        String lower = name.toLowerCase();
                        return lower.contains("daybook") && lower.contains("backfill");
                    })
                    .toList();
            if (hits.size() != 1) {
                fail("RED (FR-K2): a HUF naplókönyv sorszám-backfill Flyway-migráció még nem létezik "
                        + "(elvárt: pontosan 1 db db/migration/V*__*daybook*backfill*.sql fájl, talált: "
                        + hits.size() + ")");
            }
            return hits.get(0);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private void runBackfillMigration() {
        new ResourceDatabasePopulator(locateBackfillMigration()).execute(dataSource);
    }

    private void assertTransferSequenceColumnExists() {
        Integer count = jdbcTemplate.queryForObject("""
                SELECT count(*) FROM information_schema.columns
                WHERE table_name = 'transfer' AND column_name = 'annual_journal_sequence'
                """, Integer.class);
        assertThat(count)
                .as("RED (FR-K2): a transfer.annual_journal_sequence oszlop (entity-mező + migráció) még nem létezik")
                .isEqualTo(1);
    }

    private void assertStornoSequenceColumnsExist() {
        for (String table : List.of("shipment_request", "transfer")) {
            Integer count = jdbcTemplate.queryForObject("""
                    SELECT count(*) FROM information_schema.columns
                    WHERE table_name = ? AND column_name = 'storno_journal_sequence'
                    """, Integer.class, table);
            assertThat(count)
                    .as("RED (FR-K2/3): a %s.storno_journal_sequence oszlop (a sztornó-sor saját sorszáma) még nem létezik", table)
                    .isEqualTo(1);
        }
    }

    private Integer shipmentSequence(UUID companyId, String requestNumber) {
        return jdbcTemplate.queryForObject(
                "SELECT annual_journal_sequence FROM shipment_request WHERE company_id = ? AND request_number = ?",
                Integer.class, companyId, requestNumber);
    }

    private Integer shipmentStornoSequence(UUID companyId, String requestNumber) {
        return jdbcTemplate.queryForObject(
                "SELECT storno_journal_sequence FROM shipment_request WHERE company_id = ? AND request_number = ?",
                Integer.class, companyId, requestNumber);
    }

    private Integer transferSequence(UUID companyId, String transferNumber) {
        return jdbcTemplate.queryForObject(
                "SELECT annual_journal_sequence FROM transfer WHERE company_id = ? AND transfer_number = ?",
                Integer.class, companyId, transferNumber);
    }

    private Integer transferStornoSequence(UUID companyId, String transferNumber) {
        return jdbcTemplate.queryForObject(
                "SELECT storno_journal_sequence FROM transfer WHERE company_id = ? AND transfer_number = ?",
                Integer.class, companyId, transferNumber);
    }

    /** Az adott cég összes (nem NULL) kiosztott éves sorszáma mindkét táblából, sztornóval együtt. */
    private List<Integer> allAssignedSequences(UUID companyId) {
        List<Integer> result = new ArrayList<>(jdbcTemplate.queryForList(
                "SELECT annual_journal_sequence FROM shipment_request "
                        + "WHERE company_id = ? AND annual_journal_sequence IS NOT NULL",
                Integer.class, companyId));
        result.addAll(jdbcTemplate.queryForList(
                "SELECT annual_journal_sequence FROM transfer "
                        + "WHERE company_id = ? AND annual_journal_sequence IS NOT NULL",
                Integer.class, companyId));
        return result;
    }

    private int readLastValue(UUID companyId) {
        Integer value = jdbcTemplate.queryForObject("""
                SELECT last_value FROM huf_daybook_sequence
                WHERE company_id = ? AND sequence_year = ?
                """, Integer.class, companyId, YEAR);
        return value == null ? 0 : value;
    }

    private void upsertLastValue(UUID companyId, int lastValue) {
        jdbcTemplate.update("""
                INSERT INTO huf_daybook_sequence (company_id, sequence_year, last_value)
                VALUES (?, ?, ?)
                ON CONFLICT (company_id, sequence_year)
                DO UPDATE SET last_value = EXCLUDED.last_value
                """, companyId, YEAR, lastValue);
    }

    private void saveShipment(Seed seed, String requestNumber, String prefix,
                              LocalDateTime createdAt, Integer annualSequence, LocalDateTime cancelledAt) {
        ShipmentRequest request = ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(seed.company().getId())
                .serialPrefix(prefix)
                .serialNumber(Long.parseLong(requestNumber.substring(3)))
                .annualJournalSequence(annualSequence)
                .fromBranchId(seed.branchA().getId())
                .toBranchId(seed.branchB().getId())
                .requestedById(seed.worker().getId())
                .requestDate(createdAt.toLocalDate())
                .carrierName("Teszt Szallito")
                .sealNumber("PL-1")
                .cancelledAt(cancelledAt)
                .createdAt(createdAt)
                .build();
        shipmentRequestRepository.save(request);
    }

    private void saveTransfer(Seed seed, String transferNumber, LocalDateTime createdAt,
                              boolean isCancelled, LocalDateTime cancelledAt) {
        transferRepository.save(Transfer.builder()
                .transferNumber(transferNumber)
                .companyId(seed.company().getId())
                .fromBranch(seed.branchA())
                .toBranch(seed.branchB())
                .fromWorker(seed.worker())
                .transferType(Transfer.TransferType.CASH)
                .status(Transfer.TransferStatus.COMPLETED)
                .transferDate(createdAt.toLocalDate())
                .transferTime(createdAt.toLocalTime())
                .currency(seed.huf())
                .amount(new BigDecimal("100000.0000"))
                .hufValue(new BigDecimal("100000.00"))
                .direction(Transfer.TransferDirection.F)
                .isCancelled(isCancelled)
                .cancelledAt(cancelledAt)
                .createdAt(createdAt)
                .build());
    }

    private Seed seedBase(String tag) {
        LocalDateTime now = DAY.atTime(6, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Company company = companyRepository.save(Company.builder()
                .code(tag + "-" + suffix)
                .name("FR-K2 backfill company " + tag)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(tag + "-BT-" + suffix)
                .name("FR-K2 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(tag + "-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(tag + "-BS-" + suffix)
                .name("Active")
                .createdAt(now)
                .build());
        Branch branchA = seedBranch(company, tag + "-A-" + suffix, branchType, country, branchStatus, now);
        Branch branchB = seedBranch(company, tag + "-B-" + suffix, branchType, country, branchStatus, now);
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branchA)
                .code(("W" + suffix).substring(0, Math.min(10, ("W" + suffix).length())))
                .name("FR-K2 Teszt Dolgozo")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF")
                        .name("Forint")
                        .symbol("Ft")
                        .decimalPlaces(0)
                        .active(true)
                        .createdAt(now)
                        .build()));
        return new Seed(company, branchA, branchB, worker, huf);
    }

    private Branch seedBranch(Company company, String code, Dictionary branchType,
                              Dictionary country, Dictionary branchStatus, LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code(code)
                .company(company)
                .bankCode("K2BANK")
                .branchType(branchType)
                .name("FR-K2 Branch " + code)
                .address("Teszt utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .isActive(true)
                .openingDate(DAY)
                .createdAt(now)
                .build());
    }

    private record Seed(Company company, Branch branchA, Branch branchB, Worker worker, Currency huf) {
    }
}
