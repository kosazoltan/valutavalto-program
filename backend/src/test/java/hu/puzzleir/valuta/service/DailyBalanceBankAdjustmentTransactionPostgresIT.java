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
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
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
import static org.assertj.core.api.Assertions.assertThatNoException;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.doThrow;

/**
 * FK-052 tranzakciós holdout valós PostgreSQL-en.
 *
 * <p>A teljes DailyClosingService fixture helyett a legkisebb valós Spring tranzakciós harness
 * ugyanazt a szerződést hajtja végre: a külső zárási tranzakció daily_balance sort ír, majd
 * TransactionAfterCommit callbackből a valódi, proxizott DailyBalanceService-t hívja. Az auditot
 * a valódi, proxizott AuditLogService menti. Így a teszt nem Mockito tranzakció-szimulációt, hanem
 * tényleges commit-láthatóságot, REQUIRES_NEW rollback-izolációt és audit-perzisztenciát mér.</p>
 */
@Testcontainers
@EnableJpaAuditing
@Import({
        DailyBalanceService.class,
        AuditLogService.class,
        DailyBalanceBankAdjustmentTransactionPostgresIT.ClosingTransactionHarness.class
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
class DailyBalanceBankAdjustmentTransactionPostgresIT {

    private static final LocalDate BUSINESS_DATE = LocalDate.of(2026, 7, 15);
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

    @Autowired private ClosingTransactionHarness harness;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private JdbcTemplate jdbcTemplate;

    @MockitoSpyBean
    private DailyBalanceRepository dailyBalanceRepository;

    @Test
    @DisplayName("afterCommit REQUIRES_NEW bank-lépés látja és frissíti a külső tranzakcióban létrehozott sort")
    void afterCommitBankActionSeesAndUpdatesOuterTransactionRow() {
        Seed seed = seedVault("VIS");

        HarnessResult result = harness.closeAndScheduleBankAdjustment(
                seed.companyId(), seed.branchId(), BUSINESS_DATE, "EUR", new BigDecimal("99.00"));

        assertThat(result.warnings()).isEmpty();
        assertThat(bankIn(seed, "EUR")).isEqualByComparingTo("0.00");
        assertThat(auditCompany("DAILY_BALANCE_BANK_ADJUSTMENT", seed.branchId()))
                .isEqualTo(seed.companyId());
    }

    @Test
    @DisplayName("bank repository-hiba nem mérgezi a külső commitot; hiba-audit megmarad és részírás rollbackel")
    void bankFailureDoesNotPoisonOuterCommitAndPersistsFailureAudit() {
        Seed seed = seedVault("FAIL");
        saveBalance(seed, "EUR", new BigDecimal("11.00"));
        saveBalance(seed, "USD", new BigDecimal("22.00"));
        doThrow(new DataIntegrityViolationException("forced bank repository failure"))
                .when(dailyBalanceRepository)
                .save(argThat(balance -> "USD".equals(balance.getCurrencyCode())));

        AtomicReference<HarnessResult> result = new AtomicReference<>();
        assertThatNoException().isThrownBy(() -> result.set(
                harness.closeAndScheduleBankAdjustment(
                        seed.companyId(), seed.branchId(), BUSINESS_DATE,
                        "AAA", new BigDecimal("77.00"))));

        assertThat(result.get().warnings())
                .singleElement()
                .satisfies(warning -> {
                    assertThat(warning.getStep()).isEqualTo("bank_adjustment");
                    assertThat(warning.getMessage()).contains("forced bank repository failure");
                });
        assertThat(balanceRowCount(seed)).isEqualTo(3);
        assertThat(bankIn(seed, "AAA"))
                .as("a külső zárási tranzakció commitált sora megmarad")
                .isEqualByComparingTo("77.00");
        assertThat(bankIn(seed, "EUR"))
                .as("az USD hiba előtt módosított EUR részírás rollbackel")
                .isEqualByComparingTo("11.00");
        assertThat(bankIn(seed, "USD")).isEqualByComparingTo("22.00");
        assertThat(auditCompany("DAILY_BALANCE_BANK_ADJUSTMENT_FAILED", seed.branchId()))
                .as("a bank tranzakció rollbackje ellenére explicit tenanttal megmarad")
                .isEqualTo(seed.companyId());
    }

    private Seed seedVault(String label) {
        return transactionTemplate.execute(status -> {
            int seq = SEQ.incrementAndGet();
            String suffix = label + seq;
            LocalDateTime now = LocalDateTime.now();
            Company company = companyRepository.saveAndFlush(Company.builder()
                    .code("FK52" + suffix)
                    .name("FK-052 transaction company " + suffix)
                    .createdAt(now)
                    .build());
            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE")
                    .code("BT" + suffix)
                    .name("FK-052 branch type")
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
                    .code("VB" + suffix)
                    .company(company)
                    .bankCode("FK052")
                    .branchType(branchType)
                    .name("FK-052 vault " + suffix)
                    .address("Test street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(branchStatus)
                    .openingDate(BUSINESS_DATE.minusYears(1))
                    .isVault(true)
                    .vaultTerritoryId(seq)
                    .createdAt(now)
                    .build());
            return new Seed(company.getId(), branch.getId());
        });
    }

    private void saveBalance(Seed seed, String currencyCode, BigDecimal bankIn) {
        transactionTemplate.executeWithoutResult(status -> {
            Company company = companyRepository.findById(seed.companyId()).orElseThrow();
            dailyBalanceRepository.saveAndFlush(balance(company, seed.branchId(), currencyCode, bankIn));
        });
    }

    private BigDecimal bankIn(Seed seed, String currencyCode) {
        return jdbcTemplate.queryForObject(
                "SELECT bank_in FROM daily_balance WHERE company_id=? AND branch_id=? "
                        + "AND balance_date=? AND currency_code=?",
                BigDecimal.class, seed.companyId(), seed.branchId(), BUSINESS_DATE, currencyCode);
    }

    private int balanceRowCount(Seed seed) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM daily_balance WHERE company_id=? AND branch_id=? AND balance_date=?",
                Integer.class, seed.companyId(), seed.branchId(), BUSINESS_DATE);
        return count == null ? 0 : count;
    }

    private UUID auditCompany(String action, UUID branchId) {
        return jdbcTemplate.queryForObject(
                "SELECT company_id FROM audit_log WHERE action=? AND entity_id=? "
                        + "ORDER BY created_at DESC LIMIT 1",
                UUID.class, action, branchId.toString());
    }

    private static DailyBalance balance(
            Company company, UUID branchId, String currencyCode, BigDecimal bankIn) {
        return DailyBalance.builder()
                .company(company)
                .branchId(branchId)
                .balanceDate(BUSINESS_DATE)
                .currencyCode(currencyCode)
                .bankIn(bankIn)
                .isClosed(false)
                .build();
    }

    record Seed(UUID companyId, UUID branchId) {
    }

    record HarnessResult(List<DailyClosingService.ClosingWarning> warnings) {
    }

    static class ClosingTransactionHarness {
        private final CompanyRepository companyRepository;
        private final DailyBalanceRepository dailyBalanceRepository;
        private final DailyBalanceService dailyBalanceService;

        ClosingTransactionHarness(
                CompanyRepository companyRepository,
                DailyBalanceRepository dailyBalanceRepository,
                DailyBalanceService dailyBalanceService) {
            this.companyRepository = companyRepository;
            this.dailyBalanceRepository = dailyBalanceRepository;
            this.dailyBalanceService = dailyBalanceService;
        }

        @Transactional(rollbackFor = Exception.class)
        public HarnessResult closeAndScheduleBankAdjustment(
                UUID companyId,
                UUID branchId,
                LocalDate date,
                String outerCurrency,
                BigDecimal initialBankIn) {
            Company company = companyRepository.findById(companyId).orElseThrow();
            dailyBalanceRepository.save(balance(company, branchId, outerCurrency, initialBankIn));
            List<DailyClosingService.ClosingWarning> warnings = new ArrayList<>();
            TransactionAfterCommit.run(() -> {
                try {
                    dailyBalanceService.recordVaultBankAdjustments(branchId, date);
                } catch (Exception e) {
                    warnings.add(DailyClosingService.ClosingWarning.builder()
                            .step("bank_adjustment")
                            .message("Banki BANK+/BANK− igazítás hiba: " + e.getMessage())
                            .build());
                }
            }, "FK-052 bank adjustment branch=" + branchId + ", date=" + date);
            return new HarnessResult(warnings);
        }
    }
}
