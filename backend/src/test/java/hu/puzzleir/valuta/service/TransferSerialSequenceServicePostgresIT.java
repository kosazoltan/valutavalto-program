package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import javax.sql.DataSource;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@Import(TransferSerialSequenceService.class)
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class TransferSerialSequenceServicePostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private BranchRepository branchRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private TransferRepository transferRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private TransferSerialSequenceService transferSerialSequenceService;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private DataSource dataSource;

    @BeforeEach
    void setUpSequenceTable() {
        jdbcTemplate.execute("DROP TABLE IF EXISTS transfer_serial_sequence");
    }

    @Test
    @DisplayName("V303 backfill: meglevo tenant/prefix transfer sorszamokbol folytat, a -SZ sztornot kihagyja")
    void migrationBackfillsExistingTenantPrefixMaximumsAndIgnoresStornoSerials() {
        TransferSeed firstTenant = seedTransferSeed("BF-A");
        TransferSeed secondTenant = seedTransferSeed("BF-B");

        transactionTemplate.executeWithoutResult(status -> {
            saveExistingTransfer(firstTenant, "AT-000007");
            saveExistingTransfer(firstTenant, "AT-000011");
            saveExistingTransfer(firstTenant, "AT-000011-SZ");
            saveExistingTransfer(firstTenant, "AV-000003");
            saveExistingTransfer(firstTenant, "FF-000002");
            saveExistingTransfer(secondTenant, "AT-000004");
        });

        runTransferSerialMigration();

        assertThat(readLastValue(firstTenant.company().getId(), "AT")).isEqualTo(11L);
        assertThat(readLastValue(firstTenant.company().getId(), "AV")).isEqualTo(3L);
        assertThat(readLastValue(firstTenant.company().getId(), "FF")).isEqualTo(2L);
        assertThat(readLastValue(secondTenant.company().getId(), "AT")).isEqualTo(4L);

        transactionTemplate.executeWithoutResult(status -> {
            assertThat(transferSerialSequenceService.next(firstTenant.company().getId(), "AT")).isEqualTo(12L);
            assertThat(transferSerialSequenceService.next(firstTenant.company().getId(), "AV")).isEqualTo(4L);
            assertThat(transferSerialSequenceService.next(secondTenant.company().getId(), "AT")).isEqualTo(5L);
        });
    }

    private void runTransferSerialMigration() {
        new ResourceDatabasePopulator(new ClassPathResource("db/migration/V303__transfer_serial_sequence.sql"))
                .execute(dataSource);
    }

    @Test
    @DisplayName("transfer serial: valos PostgreSQL upsert parhuzamos tranzakciokban is egyedi, folyamatos sorszamot ad")
    void nextAllocatesUniqueContinuousNumbersUnderConcurrentPostgresTransactions() throws Exception {
        UUID companyId = seedCompany("SEQ-C");
        runTransferSerialMigration();
        int workers = 16;
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(8);
        List<Future<Long>> futures = new ArrayList<>();

        try {
            for (int i = 0; i < workers; i++) {
                futures.add(executor.submit(() -> {
                    assertThat(start.await(10, TimeUnit.SECONDS))
                            .as("A konkurencia teszt indito latch-e nem akadhat be")
                            .isTrue();
                    return transactionTemplate.execute(status ->
                            transferSerialSequenceService.next(companyId, "AT"));
                }));
            }

            start.countDown();

            List<Long> allocated = new ArrayList<>();
            for (Future<Long> future : futures) {
                allocated.add(future.get(20, TimeUnit.SECONDS));
            }

            assertThat(allocated)
                    .hasSize(workers)
                    .doesNotHaveDuplicates();
            assertThat(allocated.stream().sorted().toList())
                    .containsExactlyElementsOf(java.util.stream.LongStream.rangeClosed(1, workers).boxed().toList());
            assertThat(readLastValue(companyId, "AT")).isEqualTo(workers);
        } finally {
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS))
                    .as("A konkurencia teszt executor szalai nem maradhatnak eletben")
                    .isTrue();
        }
    }

    @Test
    @DisplayName("transfer serial: tenantenkent es prefixenkent kulon folyamatos szekvenciat tart")
    void nextKeepsTenantAndPrefixSequencesIndependent() {
        UUID firstCompanyId = seedCompany("SEQ-A");
        UUID secondCompanyId = seedCompany("SEQ-B");
        runTransferSerialMigration();

        transactionTemplate.executeWithoutResult(status -> {
            assertThat(transferSerialSequenceService.next(firstCompanyId, "AT")).isEqualTo(1L);
            assertThat(transferSerialSequenceService.next(firstCompanyId, "AV")).isEqualTo(1L);
            assertThat(transferSerialSequenceService.next(secondCompanyId, "AT")).isEqualTo(1L);
            assertThat(transferSerialSequenceService.next(firstCompanyId, "AT")).isEqualTo(2L);
        });

        assertThat(readLastValue(firstCompanyId, "AT")).isEqualTo(2L);
        assertThat(readLastValue(firstCompanyId, "AV")).isEqualTo(1L);
        assertThat(readLastValue(secondCompanyId, "AT")).isEqualTo(1L);
    }

    private UUID seedCompany(String prefix) {
        return transactionTemplate.execute(status -> companyRepository.save(Company.builder()
                .code(shortCode(prefix))
                .name("Transfer serial sequence company " + prefix)
                .createdAt(LocalDateTime.now())
                .build()).getId());
    }

    private TransferSeed seedTransferSeed(String prefix) {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = prefix + "-" + Long.toString(System.nanoTime());
            Company company = companyRepository.save(Company.builder()
                    .code(shortCode("C" + prefix))
                    .name("Transfer backfill company " + suffix)
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE")
                    .code(shortCode("BT" + prefix))
                    .name("Transfer backfill branch type")
                    .createdAt(now)
                    .build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY")
                    .code(shortCode("CO" + prefix))
                    .name("Hungary")
                    .createdAt(now)
                    .build());
            Dictionary statusDictionary = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS")
                    .code(shortCode("BS" + prefix))
                    .name("Active")
                    .createdAt(now)
                    .build());

            Branch fromBranch = branchRepository.save(Branch.builder()
                    .code(shortCode("F" + prefix))
                    .company(company)
                    .bankCode("TCBANK")
                    .branchType(branchType)
                    .name("Transfer backfill from branch")
                    .address("From Street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(statusDictionary)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());
            Branch toBranch = branchRepository.save(Branch.builder()
                    .code(shortCode("T" + prefix))
                    .company(company)
                    .bankCode("TCBANK")
                    .branchType(branchType)
                    .name("Transfer backfill to branch")
                    .address("To Street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(statusDictionary)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());
            Worker worker = workerRepository.save(Worker.builder()
                    .company(company)
                    .branch(fromBranch)
                    .code(shortCode("W" + prefix, 10))
                    .name("Transfer Backfill Worker")
                    .passwordHash("$2a$10$test")
                    .role(WorkerRole.CASHIER)
                    .active(true)
                    .createdAt(now)
                    .build());
            Currency currency = currencyRepository.findByCode("EUR")
                    .orElseGet(() -> currencyRepository.save(Currency.builder()
                            .code("EUR")
                            .name("Euro")
                            .symbol("EUR")
                            .decimalPlaces(2)
                            .active(true)
                            .createdAt(now)
                            .build()));

            return new TransferSeed(company, fromBranch, toBranch, worker, currency);
        });
    }

    private void saveExistingTransfer(TransferSeed seed, String transferNumber) {
        transferRepository.save(Transfer.builder()
                .transferNumber(transferNumber)
                .companyId(seed.company().getId())
                .fromBranch(seed.fromBranch())
                .toBranch(seed.toBranch())
                .fromWorker(seed.worker())
                .transferType(Transfer.TransferType.CURRENCY)
                .status(Transfer.TransferStatus.COMPLETED)
                .transferDate(LocalDate.now())
                .transferTime(LocalTime.now())
                .currency(seed.currency())
                .amount(new BigDecimal("100.0000"))
                .hufValue(new BigDecimal("40000.00"))
                .direction(Transfer.TransferDirection.F)
                .handoverPrinted(false)
                .receiptPrinted(false)
                .isCancelled(transferNumber.endsWith("-SZ"))
                .createdAt(LocalDateTime.now())
                .build());
    }

    private long readLastValue(UUID companyId, String prefix) {
        Long value = jdbcTemplate.queryForObject("""
                SELECT last_value
                FROM transfer_serial_sequence
                WHERE company_id = ? AND prefix = ?
                """, Long.class, companyId, prefix);
        return value == null ? 0L : value;
    }

    private static String shortCode(String prefix) {
        String suffix = Long.toString(System.nanoTime());
        return prefix + "-" + suffix.substring(Math.max(0, suffix.length() - 8));
    }

    private static String shortCode(String prefix, int maxLength) {
        String code = shortCode(prefix);
        return code.length() <= maxLength ? code : code.substring(0, maxLength);
    }

    private record TransferSeed(Company company, Branch fromBranch, Branch toBranch, Worker worker, Currency currency) {
    }
}
