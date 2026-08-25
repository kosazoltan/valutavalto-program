package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** FK-053 holdout: a napi készpénzes kezelési díj GROUP BY lekérdezés valós PostgreSQL-en. */
@Testcontainers
@EnableJpaAuditing
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class HandlingFeeDailySummaryPostgresIT {

    private static final LocalDate D1 = LocalDate.of(2026, 7, 1);
    private static final LocalDate D2 = LocalDate.of(2026, 7, 2);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("FK-053: csak napi CASH/legacy-NULL COMPLETED pozitív díjakat aggregál branch és típus szerint")
    void aggregatesDailyCashFeesWithoutCardStatusDateOrTenantLeakage() {
        Seed seed = transactionTemplate.execute(status -> seed());

        assertThat(seed).isNotNull();
        List<Object[]> branchARows = transactionRepository.findDailyCashHandlingFeeByType(
                seed.branchA().getId(), D1, D2);

        assertThat(branchARows).hasSize(3);
        assertRow(branchARows.get(0), D1, "FK053BANK", seed.branchA().getCode(), TransactionType.BUY, "180.00");
        assertRow(branchARows.get(1), D1, "FK053BANK", seed.branchA().getCode(), TransactionType.SELL, "70.00");
        assertRow(branchARows.get(2), D2, "FK053BANK", seed.branchA().getCode(), TransactionType.SELL, "40.00");
        assertThat(branchARows)
                .allSatisfy(row -> assertThat((BigDecimal) row[4])
                        .isNotEqualByComparingTo("777.00")
                        .isNotEqualByComparingTo("999.00"));

        List<Object[]> branchBRows = transactionRepository.findDailyCashHandlingFeeByType(
                seed.branchB().getId(), D1, D2);
        assertThat(branchBRows).hasSize(1);
        assertRow(branchBRows.get(0), D1, "FK053BANK", seed.branchB().getCode(), TransactionType.BUY, "777.00");
    }

    @Test
    @DisplayName("FK-055: cég-szinten aktív, nem értéktári fiókokra aggregál tenant-szivárgás nélkül")
    void aggregatesCompanyWideExcludingVaultInactiveAndOtherTenant() {
        Seed seed = transactionTemplate.execute(status -> seed());

        assertThat(seed).isNotNull();
        List<Object[]> companyRows = transactionRepository.findDailyCashHandlingFeeByTypeForCompany(
                seed.companyA().getId(), D1, D2);

        assertThat(companyRows).hasSize(4);
        assertRow(companyRows.get(0), D1, "FK053BANK", seed.branchA().getCode(), TransactionType.BUY, "180.00");
        assertRow(companyRows.get(1), D1, "FK053BANK", seed.branchA().getCode(), TransactionType.SELL, "70.00");
        assertRow(companyRows.get(2), D1, "FK055BANK", seed.branchA2().getCode(), TransactionType.BUY, "25.00");
        assertRow(companyRows.get(3), D2, "FK053BANK", seed.branchA().getCode(), TransactionType.SELL, "40.00");
        assertThat(companyRows)
                .allSatisfy(row -> assertThat((BigDecimal) row[4])
                        .isNotEqualByComparingTo("444.00")
                        .isNotEqualByComparingTo("555.00")
                        .isNotEqualByComparingTo("666.00")
                        .isNotEqualByComparingTo("777.00")
                        .isNotEqualByComparingTo("888.00")
                        .isNotEqualByComparingTo("999.00"));
    }

    private Seed seed() {
        LocalDateTime now = D1.atTime(8, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code("FK053-BT-" + suffix)
                .name("FK-053 branch type")
                .createdAt(now)
                .build());
        Dictionary counterpartyType = dictionaryRepository
                .findByCategoryAndCode("BRANCH_TYPE", "VAULT_COUNTERPARTY")
                .orElseGet(() -> dictionaryRepository.save(Dictionary.builder()
                        .category("BRANCH_TYPE")
                        .code("VAULT_COUNTERPARTY")
                        .name("Vault counterparty")
                        .createdAt(now)
                        .build()));
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code("FK053-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code("FK053-BS-" + suffix)
                .name("Active")
                .createdAt(now)
                .build());
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF")
                        .name("Forint")
                        .symbol("Ft")
                        .decimalPlaces(0)
                        .active(true)
                        .displayOrder(1)
                        .createdAt(now)
                        .build()));

        Tenant tenantA = seedTenant("A" + suffix, branchType, country, branchStatus, now);
        Tenant tenantB = seedTenant("B" + suffix, branchType, country, branchStatus, now);
        Tenant tenantASecondBranch = seedBranch(
                tenantA.company(), "A2" + suffix, branchType, country, branchStatus, now, false, true);
        Tenant tenantAVaultBranch = seedBranch(
                tenantA.company(), "AV" + suffix, branchType, country, branchStatus, now, true, true);
        Tenant tenantAInactiveBranch = seedBranch(
                tenantA.company(), "AI" + suffix, branchType, country, branchStatus, now, false, false);
        Tenant tenantACounterpartyBranch = seedBranch(
                tenantA.company(), "AC" + suffix, counterpartyType, country, branchStatus,
                now, false, true);

        saveTransaction(tenantA, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "100.00", "A1-" + suffix);
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "50.00", "A2-" + suffix);
        saveTransaction(tenantA, huf, D1, TransactionType.SELL, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "70.00", "A3-" + suffix);
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, PaymentMethod.CARD,
                TransactionStatus.COMPLETED, "999.00", "A4-" + suffix);
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, null,
                TransactionStatus.COMPLETED, "30.00", "A5-" + suffix);
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.REVERSED, "888.00", "A6-" + suffix);
        saveTransaction(tenantA, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "0.00", "A7-" + suffix);
        saveTransaction(tenantA, huf, D2, TransactionType.SELL, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "40.00", "A8-" + suffix);
        saveTransaction(tenantA, huf, D2.plusDays(7), TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "500.00", "A9-" + suffix);
        saveTransaction(tenantASecondBranch, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "25.00", "A10-" + suffix);
        saveTransaction(tenantAVaultBranch, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "555.00", "A11-" + suffix);
        saveTransaction(tenantAInactiveBranch, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "666.00", "A12-" + suffix);
        saveTransaction(tenantACounterpartyBranch, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "444.00", "A13-" + suffix);
        saveTransaction(tenantB, huf, D1, TransactionType.BUY, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "777.00", "B1-" + suffix);
        transactionRepository.flush();
        return new Seed(tenantA.company(), tenantA.branch(), tenantASecondBranch.branch(), tenantB.branch());
    }

    private Tenant seedTenant(
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now) {
        Company company = companyRepository.save(Company.builder()
                .code("FK053-C-" + suffix)
                .name("FK-053 Company " + suffix)
                .createdAt(now)
                .build());
        Branch branch = branchRepository.save(Branch.builder()
                .code("FK053-B-" + suffix)
                .company(company)
                .bankCode("FK053BANK")
                .branchType(branchType)
                .name("FK-053 Branch " + suffix)
                .address("Test Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .openingDate(D1)
                .createdAt(now)
                .build());
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code("FK053-W-" + suffix)
                .name("FK-053 Worker " + suffix)
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        return new Tenant(company, branch, worker);
    }

    private Tenant seedBranch(
            Company company,
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now,
            boolean isVault,
            boolean isActive) {
        Branch branch = branchRepository.save(Branch.builder()
                .code("FK055-B-" + suffix)
                .company(company)
                .bankCode("FK055BANK")
                .branchType(branchType)
                .name("FK-055 Branch " + suffix)
                .address("Test Street 2")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(isVault)
                .isActive(isActive)
                .openingDate(D1)
                .createdAt(now)
                .build());
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code("FK055-W-" + suffix)
                .name("FK-055 Worker " + suffix)
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        return new Tenant(company, branch, worker);
    }

    private void saveTransaction(
            Tenant tenant,
            Currency currency,
            LocalDate date,
            TransactionType type,
            PaymentMethod paymentMethod,
            TransactionStatus status,
            String handlingFee,
            String receiptNumber) {
        Transaction transaction = Transaction.builder()
                .company(tenant.company())
                .branch(tenant.branch())
                .worker(tenant.worker())
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(status)
                .transactionDate(date)
                .transactionTime(LocalTime.NOON)
                .currency(currency)
                .currencyAmount(BigDecimal.ONE)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(BigDecimal.ONE)
                .handlingFee(new BigDecimal(handlingFee))
                .discountAmount(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .financialEffective(true)
                .createdAt(date.atTime(12, 0))
                .build();
        transaction.setPaymentMethod(paymentMethod);
        transactionRepository.save(transaction);
    }

    private void assertRow(
            Object[] row, LocalDate date, String bankCode, String code, TransactionType type, String amount) {
        assertThat(row[0]).isEqualTo(date);
        assertThat(row[1]).isEqualTo(bankCode);
        assertThat(row[2]).isEqualTo(code);
        assertThat(row[3]).isEqualTo(type);
        assertThat((BigDecimal) row[4]).isEqualByComparingTo(amount);
    }

    private record Tenant(Company company, Branch branch, Worker worker) {}

    private record Seed(Company companyA, Branch branchA, Branch branchA2, Branch branchB) {}
}
