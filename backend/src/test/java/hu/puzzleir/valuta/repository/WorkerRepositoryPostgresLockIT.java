package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;

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
class WorkerRepositoryPostgresLockIT {

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
    private WorkerRepository workerRepository;

    @Autowired
    private TransactionTemplate transactionTemplate;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("findByIdForUpdate valos PostgreSQL tranzakcioban blokkolja a masodik lockot")
    void findByIdForUpdateBlocksConcurrentPostgresTransaction() throws Exception {
        Long workerId = seedWorker();
        CountDownLatch firstLockAcquired = new CountDownLatch(1);
        CountDownLatch releaseFirstLock = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(1);

        try {
            Future<?> firstTransaction = executor.submit(() -> transactionTemplate.executeWithoutResult(status -> {
                Worker locked = workerRepository.findByIdForUpdate(workerId).orElseThrow();
                assertThat(locked.getId()).isEqualTo(workerId);
                firstLockAcquired.countDown();
                await(releaseFirstLock);
            }));

            assertThat(firstLockAcquired.await(10, TimeUnit.SECONDS))
                    .as("Az elso tranzakcionak meg kell szereznie a PostgreSQL row lockot")
                    .isTrue();

            Throwable secondLockFailure = catchThrowable(() -> transactionTemplate.executeWithoutResult(status -> {
                jdbcTemplate.execute("SET LOCAL lock_timeout = '300ms'");
                workerRepository.findByIdForUpdate(workerId).orElseThrow();
            }));

            assertThat(secondLockFailure)
                    .as("A masodik tranzakcio nem kaphatja meg ugyanazt a PESSIMISTIC_WRITE lockot")
                    .isNotNull();
            assertThat(rootMessage(secondLockFailure))
                    .containsIgnoringCase("lock");

            releaseFirstLock.countDown();
            firstTransaction.get(10, TimeUnit.SECONDS);

            transactionTemplate.executeWithoutResult(status -> {
                Worker lockedAfterRelease = workerRepository.findByIdForUpdate(workerId).orElseThrow();
                assertThat(lockedAfterRelease.getId()).isEqualTo(workerId);
            });
        } finally {
            releaseFirstLock.countDown();
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS))
                    .as("A konkurencia teszt sajat executor szala nem maradhat eletben")
                    .isTrue();
        }
    }

    private Long seedWorker() {
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

            Worker worker = workerRepository.saveAndFlush(Worker.builder()
                    .company(company)
                    .branch(branch)
                    .code("W" + suffix.substring(Math.max(0, suffix.length() - 9)))
                    .name("Postgres Lock Cashier")
                    .passwordHash("$2a$10$test")
                    .role(WorkerRole.CASHIER)
                    .active(true)
                    .createdAt(now)
                    .build());

            return worker.getId();
        });
    }

    private static void await(CountDownLatch latch) {
        try {
            if (!latch.await(10, TimeUnit.SECONDS)) {
                throw new AssertionError("Timed out while waiting for test lock release");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new AssertionError("Interrupted while waiting for test lock release", e);
        }
    }

    private static String rootMessage(Throwable throwable) {
        Throwable root = throwable;
        while (root.getCause() != null) {
            root = root.getCause();
        }
        return root.getMessage() == null ? throwable.toString() : root.getMessage();
    }
}
