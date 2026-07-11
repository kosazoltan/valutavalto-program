package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.DariusFixingRequest;
import hu.puzzleir.valuta.entity.DariusFixingRequestStatus;
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
import java.util.List;
import java.util.UUID;
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
class DariusFixingRequestRepositoryPostgresLockIT {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID BANK_BRANCH_ID = UUID.fromString("20000000-0000-0000-0000-000000000002");
    private static final LocalDate REQUEST_DATE = LocalDate.of(2026, 7, 14);

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
    private DariusFixingRequestRepository repository;

    @Autowired
    private TransactionTemplate transactionTemplate;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void exportLockSerializesCancelAndCancelReadsIncludedAfterExportCommit() throws Exception {
        UUID requestId = seedApprovedRequests();
        CountDownLatch exportLockAcquired = new CountDownLatch(1);
        CountDownLatch releaseExport = new CountDownLatch(1);
        ExecutorService executor = Executors.newSingleThreadExecutor();

        try {
            Future<?> export = executor.submit(() -> transactionTemplate.executeWithoutResult(status -> {
                List<DariusFixingRequest> locked = repository
                        .findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                                COMPANY_ID,
                                REQUEST_DATE,
                                List.of(DariusFixingRequestStatus.APPROVED));
                assertThat(locked).hasSize(2);
                assertThat(locked.get(0).getCreatedAt()).isBefore(locked.get(1).getCreatedAt());
                DariusFixingRequest target = locked.stream()
                        .filter(request -> request.getId().equals(requestId))
                        .findFirst()
                        .orElseThrow();
                exportLockAcquired.countDown();
                await(releaseExport);
                target.setStatus(DariusFixingRequestStatus.INCLUDED);
                target.setIncludedAt(LocalDateTime.of(2026, 7, 14, 10, 0));
                repository.saveAndFlush(target);
            }));

            assertThat(exportLockAcquired.await(10, TimeUnit.SECONDS)).isTrue();

            Throwable concurrentCancel = catchThrowable(() -> transactionTemplate.executeWithoutResult(status -> {
                jdbcTemplate.execute("SET LOCAL lock_timeout = '300ms'");
                repository.findForUpdateByIdAndCompanyId(requestId, COMPANY_ID).orElseThrow();
            }));
            assertThat(concurrentCancel).isNotNull();
            assertThat(rootMessage(concurrentCancel)).containsIgnoringCase("lock");

            releaseExport.countDown();
            export.get(10, TimeUnit.SECONDS);

            transactionTemplate.executeWithoutResult(status -> {
                DariusFixingRequest afterExport = repository
                        .findForUpdateByIdAndCompanyId(requestId, COMPANY_ID)
                        .orElseThrow();
                assertThat(afterExport.getStatus()).isEqualTo(DariusFixingRequestStatus.INCLUDED);
            });
            assertThat(repository.findByIdAndCompanyId(requestId, COMPANY_ID))
                    .get()
                    .extracting(DariusFixingRequest::getStatus)
                    .isEqualTo(DariusFixingRequestStatus.INCLUDED);
        } finally {
            releaseExport.countDown();
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS)).isTrue();
        }
    }

    private UUID seedApprovedRequests() {
        return transactionTemplate.execute(status -> {
            DariusFixingRequest first = repository.saveAndFlush(request(
                    LocalDateTime.of(2026, 7, 14, 8, 0), BANK_BRANCH_ID));
            repository.saveAndFlush(request(
                    LocalDateTime.of(2026, 7, 14, 9, 0), UUID.fromString("20000000-0000-0000-0000-000000000003")));
            return first.getId();
        });
    }

    private DariusFixingRequest request(LocalDateTime createdAt, UUID bankBranchId) {
        return DariusFixingRequest.builder()
                .companyId(COMPANY_ID)
                .bankBranchId(bankBranchId)
                .requestDate(REQUEST_DATE)
                .status(DariusFixingRequestStatus.APPROVED)
                .createdBy("TEST")
                .createdAt(createdAt)
                .build();
    }

    private static void await(CountDownLatch latch) {
        try {
            if (!latch.await(10, TimeUnit.SECONDS)) {
                throw new AssertionError("Timed out while waiting for export lock release");
            }
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new AssertionError("Interrupted while waiting for export lock release", exception);
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
