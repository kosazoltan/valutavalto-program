package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.util.OptimisticLockRetry;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

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
class OptimisticLockRetryPostgresIT {

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
    private CompanyRepository companyRepository;

    @Autowired
    private DictionaryRepository dictionaryRepository;

    @Autowired
    private BranchRepository branchRepository;

    @Autowired
    private CurrencyRepository currencyRepository;

    @Autowired
    private CashBalanceRepository cashBalanceRepository;

    @Autowired
    private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("valos @Version utkozesnel a retry a 2. probalkozasra atviszi a muveletet")
    void executeRecoversFromRealOptimisticConflictOnSecondAttempt() {
        Long balanceId = seedCashBalance();
        ExecutorService executor = Executors.newSingleThreadExecutor();
        AtomicInteger attempts = new AtomicInteger();
        try {
            BigDecimal result = OptimisticLockRetry.execute(() -> {
                int attempt = attempts.incrementAndGet();
                return transactionTemplate.execute(status -> {
                    CashBalance fresh = cashBalanceRepository.findById(balanceId).orElseThrow();
                    if (attempt == 1) {
                        runConcurrentCommittedUpdate(executor, balanceId, new BigDecimal("10.00"));
                    }
                    fresh.addBalance(new BigDecimal("5.00"));
                    cashBalanceRepository.saveAndFlush(fresh);
                    return fresh.getCurrentBalance();
                });
            }, "IT cash balance adjust");

            assertThat(attempts.get()).as("pontosan 2 probalkozas").isEqualTo(2);
            assertThat(result).isEqualByComparingTo("115.00");

            CashBalance persisted = transactionTemplate.execute(status ->
                    cashBalanceRepository.findById(balanceId).orElseThrow());
            assertThat(persisted.getCurrentBalance()).isEqualByComparingTo("115.00");
            assertThat(persisted.getVersion()).isEqualTo(2L);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    @DisplayName("ha MINDEN probalkozason valos utkozes van, 3 kiserletet utan az eredeti kivetel propagal")
    void executeExhaustsRetriesWhenEveryAttemptConflicts() {
        Long balanceId = seedCashBalance();
        ExecutorService executor = Executors.newSingleThreadExecutor();
        AtomicInteger attempts = new AtomicInteger();
        try {
            assertThatThrownBy(() -> OptimisticLockRetry.execute(() -> {
                attempts.incrementAndGet();
                return transactionTemplate.execute(status -> {
                    CashBalance fresh = cashBalanceRepository.findById(balanceId).orElseThrow();
                    runConcurrentCommittedUpdate(executor, balanceId, new BigDecimal("1.00"));
                    fresh.addBalance(new BigDecimal("5.00"));
                    cashBalanceRepository.saveAndFlush(fresh);
                    return fresh.getCurrentBalance();
                });
            }, "IT exhaustion"))
                    .isInstanceOf(ObjectOptimisticLockingFailureException.class);

            assertThat(attempts.get()).isEqualTo(3);

            CashBalance persisted = transactionTemplate.execute(status ->
                    cashBalanceRepository.findById(balanceId).orElseThrow());
            assertThat(persisted.getCurrentBalance()).isEqualByComparingTo("103.00");
        } finally {
            executor.shutdownNow();
        }
    }

    private Long seedCashBalance() {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = Long.toString(System.nanoTime());
            Company company = companyRepository.save(Company.builder()
                    .code("TC" + suffix.substring(Math.max(0, suffix.length() - 12)))
                    .name("Testcontainers Company")
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE")
                    .code("TC-BRANCH-" + suffix)
                    .name("Testcontainers branch type")
                    .createdAt(now)
                    .build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY")
                    .code("TC-COUNTRY-" + suffix)
                    .name("Hungary")
                    .createdAt(now)
                    .build());
            Dictionary statusDictionary = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS")
                    .code("TC-ACTIVE-" + suffix)
                    .name("Active")
                    .createdAt(now)
                    .build());

            Branch branch = branchRepository.save(Branch.builder()
                    .code("TC-BR-" + suffix.substring(Math.max(0, suffix.length() - 12)))
                    .company(company)
                    .bankCode("TCBANK")
                    .branchType(branchType)
                    .name("Testcontainers Branch")
                    .address("Test Street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(statusDictionary)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());

            Currency currency = currencyRepository.findByCode("TCX")
                    .orElseGet(() -> currencyRepository.save(Currency.builder()
                            .code("TCX")
                            .name("Testcontainers valuta")
                            .createdAt(now)
                            .build()));

            CashBalance balance = cashBalanceRepository.saveAndFlush(CashBalance.builder()
                    .company(company)
                    .branch(branch)
                    .currency(currency)
                    .currentBalance(new BigDecimal("100.00"))
                    .createdAt(now)
                    .build());
            return balance.getId();
        });
    }

    private void runConcurrentCommittedUpdate(ExecutorService executor, Long balanceId, BigDecimal amount) {
        try {
            executor.submit(() -> transactionTemplate.executeWithoutResult(status -> {
                CashBalance other = cashBalanceRepository.findById(balanceId).orElseThrow();
                other.addBalance(amount);
                cashBalanceRepository.saveAndFlush(other);
            })).get(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Konkurens update megszakadt", e);
        } catch (Exception e) {
            throw new IllegalStateException("Konkurens update hibazott", e);
        }
    }
}
