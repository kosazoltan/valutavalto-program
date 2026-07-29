package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
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
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-022 kiegészítés — 13. regressziós teszt (Bugbot #1 MEDIUM fix, PR #1518):
 * érvénytelenített (voided) transzferek kizárása a HUF naplókönyvből.
 *
 * <p>A {@code storno()} út (COMPLETED → is_cancelled=true) eredeti + sztornó-sort ad
 * (nettó nulla) — az helyes. DE a PENDING/IN_TRANSIT fázisban törölt ({@code cancel()} →
 * status=CANCELLED, is_cancelled NEM állítódik) és az elutasított (REJECTED) transzfer
 * SOSEM volt valós pénzmozgás — sem eredeti, sem sztornó sorként nem jelenhet meg,
 * különben a napi összesen ellentételezés nélkül torzul. A kizárási minta a repo saját
 * {@code TransferRepository.findForReconciliation} precedensét követi.</p>
 */
@Testcontainers
@Import(HufDaybookService.class)
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class HufDaybookVoidedTransferExclusionFrK13PostgresTest {

    private static final LocalDate DAY = LocalDate.of(2026, 7, 1);

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
    @Autowired private TransferRepository transferRepository;
    @Autowired private HufDaybookService hufDaybookService;
    @Autowired private TransactionTemplate transactionTemplate;

    @MockitoBean
    private AccessScopeService accessScopeService;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FR-K13: CANCELLED (PENDING-fázisú törlés) és REJECTED FF/UF transzfer sem eredeti, sem sztornó sorként nem jelenik meg — a COMPLETED igen")
    void voidedTransfersAreExcludedFromDaybook() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K13"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // PENDING-fázisban törölt (cancel()): status=CANCELLED, is_cancelled=false,
            // cancelled_at nincs — sosem volt valós pénzmozgás.
            saveTransfer(seed, "FF-000801", Transfer.TransferStatus.CANCELLED,
                    DAY.atTime(9, 0, 0), false, null);
            // Elutasított: status=REJECTED.
            saveTransfer(seed, "UF-000802", Transfer.TransferStatus.REJECTED,
                    DAY.atTime(9, 30, 0), false, null);
            // Defenzív eset: CANCELLED státusz MELLETT kitöltött sztornó-mezőkkel sem
            // kerülhet sztornó-ágba (a valós sztornó csak COMPLETED bizonylaton él).
            saveTransfer(seed, "FF-000804", Transfer.TransferStatus.CANCELLED,
                    DAY.atTime(9, 45, 0), true, DAY.atTime(11, 0));
            // Kontroll: a COMPLETED bizonylatnak meg KELL jelennie (nincs túlszűrés).
            saveTransfer(seed, "FF-000803", Transfer.TransferStatus.COMPLETED,
                    DAY.atTime(10, 0, 0), false, null);
        });

        authenticate(seed.company().getId(), seed.branchA().getId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(seed.branchA().getId(), DAY);

        assertThat(daybook.getRows())
                .as("RED (FR-K13): a naplóban KIZÁRÓLAG a COMPLETED transzfer szerepelhet — "
                        + "a CANCELLED/REJECTED bizonylatok (eredeti ÉS sztornó sorként is) kizárva")
                .extracting(HufDaybookRowDto::getReceiptNumber)
                .containsExactly("FF-000803");
    }

    // ============================ HELPEREK ============================

    private void authenticate(UUID companyId, UUID branchId) {
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken("K13-TESZT", "test", "ROLE_ERTEKTAR");
        authentication.setDetails(new WorkerAuthenticationDetails(42L, companyId, branchId, "ERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private void saveTransfer(Seed seed, String transferNumber, Transfer.TransferStatus status,
                              LocalDateTime createdAt, boolean isCancelled, LocalDateTime cancelledAt) {
        transferRepository.save(Transfer.builder()
                .transferNumber(transferNumber)
                .companyId(seed.company().getId())
                .fromBranch(transferNumber.startsWith("FF-") ? seed.branchA() : seed.branchB())
                .toBranch(transferNumber.startsWith("FF-") ? seed.branchB() : seed.branchA())
                .fromWorker(seed.worker())
                .transferType(Transfer.TransferType.CASH)
                .status(status)
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
                .name("FR-K13 voided transfer company")
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(tag + "-BT-" + suffix)
                .name("FR-K13 branch type")
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
                .name("FR-K13 Teszt Dolgozo")
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
                .bankCode("K13BANK")
                .branchType(branchType)
                .name("FR-K13 Branch " + code)
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
