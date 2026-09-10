package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * FKH-061 (A1 real-tx): the decade-report failure must not poison the day-closing commit.
 *
 * <p>This is the ONLY test in the suite that exercises the real rollback-only flag: the Mockito
 * harness has no transaction synchronisation, so {@code TransactionAfterCommit.run} executes
 * inline there and no rollback-only marking can happen.</p>
 *
 * <p>Defect shape on BASE 1588b5b2: {@code generateDecadeReport} was
 * {@code @Transactional(rollbackFor = Exception.class)} (REQUIRED) and was called INLINE inside
 * the closing transaction with a swallow-catch. The thrown ValidationException marked the shared
 * transaction rollback-only; the catch hid it, and the outer commit died with
 * {@code UnexpectedRollbackException} (HTTP 500, unattributable). The harness below reproduces
 * exactly that shape: outer tx writes a daily_balance row (step 3 stand-in), calls the REAL
 * proxied {@code DecadeReportService} inline with a swallow-catch (the branch id does not exist,
 * so the callee throws), then commits.</p>
 *
 * <p>Fixed shape (WU-2): the callee is REQUIRES_NEW, so its failure rolls back only its own
 * transaction; the outer commit succeeds, the daily_balance row is visible, and no
 * UnexpectedRollbackException surfaces. The second test pins the afterCommit leg: a
 * TransactionAfterCommit callback runs a REQUIRES_NEW reader that SEES the committed row — the
 * premise that makes moving the decade report into afterCommit safe for
 * validateDailyClosingCompleteness (it reads step 3's rows).</p>
 */
@Testcontainers
@EnableJpaAuditing
@Import({
        DecadeReportService.class,
        MnbExchangeRateService.class,
        DailyClosingDecadeAfterCommitFkh061PostgresIT.DecadeClosingHarness.class
})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class DailyClosingDecadeAfterCommitFkh061PostgresIT {

    private static final LocalDate BUSINESS_DATE = LocalDate.of(2026, 9, 10);
    private static final AtomicInteger SEQ = new AtomicInteger();

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private DecadeClosingHarness harness;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("FKH-061 A1: a throwing decade report does NOT poison the outer closing commit")
    void decadeReportFailureDoesNotPoisonOuterCommit() {
        Seed seed = seedBranch("DEC");

        AtomicReference<HarnessResult> result = new AtomicReference<>();
        // BASE shape: inline REQUIRED callee + swallow-catch ⇒ UnexpectedRollbackException here.
        // Fixed shape: callee is REQUIRES_NEW ⇒ the commit succeeds with a warning only.
        assertThatCode(() -> result.set(
                harness.closeWithInlineDecadeReport(seed.companyId(), seed.branchId(), BUSINESS_DATE)))
                .doesNotThrowAnyException();

        assertThat(result.get().warnings())
                .singleElement()
                .satisfies(warning -> {
                    assertThat(warning.getStep()).isEqualTo("decade_report");
                    assertThat(warning.getMessage()).contains("Dekád jelentés hiba");
                });
        assertThat(balanceRowCount(seed))
                .as("a külső zárási tranzakció daily_balance sora commitált és látható")
                .isEqualTo(1);
    }

    @Test
    @DisplayName("FKH-061 A1: the afterCommit callback sees the committed closing rows (REQUIRES_NEW reader)")
    void afterCommitCallbackSeesCommittedRows() {
        Seed seed = seedBranch("AFT");

        HarnessResult result = harness.closeWithAfterCommitReader(seed.companyId(), seed.branchId(), BUSINESS_DATE);

        assertThat(result.warnings()).isEmpty();
        assertThat(result.visibleRowsInCallback().get())
                .as("az afterCommit idején a 3. lépés sorai már commitáltak — a dekádriport "
                        + "validateDailyClosingCompleteness ellenőrzése ezért látja őket")
                .isEqualTo(1);
        assertThat(balanceRowCount(seed)).isEqualTo(1);
    }

    // ============ seeding ============

    private Seed seedBranch(String label) {
        return transactionTemplate.execute(status -> {
            int seq = SEQ.incrementAndGet();
            String suffix = label + seq;
            LocalDateTime now = LocalDateTime.now();
            Company company = companyRepository.saveAndFlush(Company.builder()
                    .code("F61" + suffix)
                    .name("FKH-061 transaction company " + suffix)
                    .createdAt(now)
                    .build());
            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE")
                    .code("BT" + suffix)
                    .name("FKH-061 branch type")
                    .createdAt(now)
                    .build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY")
                    .code("CO" + suffix)
                    .name("Hungary")
                    .createdAt(now)
                    .build());
            Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS")
                    .code("BS" + suffix)
                    .name("Active")
                    .createdAt(now)
                    .build());
            Branch branch = branchRepository.saveAndFlush(Branch.builder()
                    .code("DB" + suffix)
                    .company(company)
                    .bankCode("FK061")
                    .branchType(branchType)
                    .name("FKH-061 branch " + suffix)
                    .address("Test street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(branchStatus)
                    .openingDate(BUSINESS_DATE.minusYears(1))
                    .isVault(false)
                    .createdAt(now)
                    .build());
            return new Seed(company.getId(), branch.getId());
        });
    }

    private int balanceRowCount(Seed seed) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM daily_balance WHERE company_id=? AND branch_id=? AND balance_date=?",
                Integer.class, seed.companyId(), seed.branchId(), BUSINESS_DATE);
        return count == null ? 0 : count;
    }

    record Seed(UUID companyId, UUID branchId) {
    }

    record HarnessResult(
            List<DailyClosingService.ClosingWarning> warnings,
            AtomicInteger visibleRowsInCallback) {
    }

    /**
     * Minimal real-Spring transaction harness for the closing ↔ decade-report contract
     * (same pattern as the FK-052 ClosingTransactionHarness — DailyClosingService itself has
     * ~22 collaborators and is not wired here).
     */
    static class DecadeClosingHarness {
        private final CompanyRepository companyRepository;
        private final DailyBalanceRepository dailyBalanceRepository;
        private final DecadeReportService decadeReportService;
        /** Lazy self-reference: the REQUIRES_NEW reader must go through the proxy, but
         *  resolving it in the constructor is a circular reference — ObjectProvider defers it. */
        private final org.springframework.beans.factory.ObjectProvider<DecadeClosingHarness> selfProvider;

        DecadeClosingHarness(
                CompanyRepository companyRepository,
                DailyBalanceRepository dailyBalanceRepository,
                DecadeReportService decadeReportService,
                org.springframework.beans.factory.ObjectProvider<DecadeClosingHarness> selfProvider) {
            this.companyRepository = companyRepository;
            this.dailyBalanceRepository = dailyBalanceRepository;
            this.decadeReportService = decadeReportService;
            this.selfProvider = selfProvider;
        }

        private DecadeClosingHarness self() {
            return selfProvider.getObject();
        }

        /** BASE shape: inline call with swallow-catch inside the closing transaction. */
        @Transactional(rollbackFor = Exception.class)
        public HarnessResult closeWithInlineDecadeReport(UUID companyId, UUID branchId, LocalDate date) {
            saveClosingBalanceRow(companyId, branchId, date);
            List<DailyClosingService.ClosingWarning> warnings = new ArrayList<>();
            try {
                // Unknown decade (37) ⇒ ValidationException inside the callee's own tx (fixed)
                // or inside the shared tx (BASE) — no DB seeding needed, no SecurityContext needed.
                decadeReportService.generateDecadeReport(branchId, date.getYear(), 37);
            } catch (Exception e) {
                warnings.add(DailyClosingService.ClosingWarning.builder()
                        .step("decade_report")
                        .message("Dekád jelentés hiba: " + e.getMessage())
                        .build());
            }
            return new HarnessResult(warnings, new AtomicInteger(-1));
        }

        /** Fixed-shape leg: the decade step runs after the commit and sees the committed rows. */
        @Transactional(rollbackFor = Exception.class)
        public HarnessResult closeWithAfterCommitReader(UUID companyId, UUID branchId, LocalDate date) {
            saveClosingBalanceRow(companyId, branchId, date);
            List<DailyClosingService.ClosingWarning> warnings = new ArrayList<>();
            AtomicInteger visibleRows = new AtomicInteger(-1);
            TransactionAfterCommit.run(() -> {
                try {
                    visibleRows.set(self().countClosingRowsInNewTx(companyId, branchId, date));
                } catch (Exception e) {
                    warnings.add(DailyClosingService.ClosingWarning.builder()
                            .step("decade_report")
                            .message("Dekád jelentés hiba: " + e.getMessage())
                            .build());
                }
            }, "FKH-061 decade report branch=" + branchId + ", date=" + date);
            // The callback fires during the commit that happens when this method returns;
            // the shared AtomicInteger carries the observed count out (same mutable-holder
            // pattern as the warnings list in the FK-052 harness).
            return new HarnessResult(warnings, visibleRows);
        }

        /** Stand-in for validateDailyClosingCompleteness: reads step 3's rows in a fresh tx. */
        @Transactional(propagation = Propagation.REQUIRES_NEW, readOnly = true)
        public int countClosingRowsInNewTx(UUID companyId, UUID branchId, LocalDate date) {
            return dailyBalanceRepository
                    .findByBranchIdAndBalanceDate(companyId, branchId, date)
                    .size();
        }

        private void saveClosingBalanceRow(UUID companyId, UUID branchId, LocalDate date) {
            Company company = companyRepository.findById(companyId).orElseThrow();
            dailyBalanceRepository.saveAndFlush(DailyBalance.builder()
                    .company(company)
                    .branchId(branchId)
                    .balanceDate(date)
                    .currencyCode("HUF")
                    .openingBalance(new BigDecimal("100000.00"))
                    .closingBalance(new BigDecimal("100000.00"))
                    .isClosed(true)
                    .build());
        }
    }
}
