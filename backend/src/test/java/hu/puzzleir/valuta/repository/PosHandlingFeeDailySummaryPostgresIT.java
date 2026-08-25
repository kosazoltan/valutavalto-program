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

/** FK-059: POS daily net and handling-fee aggregation on real PostgreSQL. */
@Testcontainers
@EnableJpaAuditing
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class PosHandlingFeeDailySummaryPostgresIT {

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
    @DisplayName("FK-059 branch query aggregates only CARD SELL COMPLETED daily net and fee")
    void branchQuery_returnsDailyNetAndFee_forCardSellCompletedOnly() {
        Seed seed = transactionTemplate.execute(status -> seed());

        assertThat(seed).isNotNull();
        List<Object[]> rows = transactionRepository.findDailyPosHandlingFee(seed.branchA1().getId(), D1, D2);

        assertThat(rows).hasSize(2);
        assertRow(rows.get(0), D1, "FK059BANK", seed.branchA1().getCode(), "73000.00", "3000.00");
        assertRow(rows.get(1), D2, "FK059BANK", seed.branchA1().getCode(), "10000.00", "0.00");
    }

    @Test
    @DisplayName("FK-059 branch query includes zero-fee card sales and subtracts rounding")
    void branchQuery_includesZeroFeeCardSellInNet() {
        Seed seed = transactionTemplate.execute(status -> seed());

        assertThat(seed).isNotNull();
        List<Object[]> rows = transactionRepository.findDailyPosHandlingFee(seed.branchA1().getId(), D2, D2);

        assertThat(rows).hasSize(1);
        assertRow(rows.get(0), D2, "FK059BANK", seed.branchA1().getCode(), "10000.00", "0.00");
    }

    @Test
    @DisplayName("FK-059 company query excludes counterparties, inactive branches, and other tenants")
    void companyQuery_aggregatesAllOffices_excludingVaultCounterpartyInactiveAndOtherTenant() {
        Seed seed = transactionTemplate.execute(status -> seed());

        assertThat(seed).isNotNull();
        List<Object[]> rows = transactionRepository.findDailyPosHandlingFeeForCompany(seed.companyA().getId(), D1, D2);

        assertThat(rows).hasSize(3);
        assertRow(rows.get(0), D1, "FK059BANK", seed.branchA1().getCode(), "73000.00", "3000.00");
        assertRow(rows.get(1), D1, "FK059BANK", seed.branchA2().getCode(), "20000.00", "800.00");
        assertRow(rows.get(2), D2, "FK059BANK", seed.branchA1().getCode(), "10000.00", "0.00");
    }

    private Seed seed() {
        LocalDateTime now = D1.atTime(8, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Dictionary normalBranchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code("FK059-BT-" + suffix)
                .name("FK-059 branch type")
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
                .code("FK059-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code("FK059-BS-" + suffix)
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

        Company companyA = seedCompany("A" + suffix, now);
        Company companyB = seedCompany("B" + suffix, now);
        BranchWorker a1 = seedBranch(
                companyA, "A1" + suffix, normalBranchType, country, branchStatus, now, true);
        BranchWorker a2 = seedBranch(
                companyA, "A2" + suffix, normalBranchType, country, branchStatus, now, true);
        BranchWorker vaultCounterparty = seedBranch(
                companyA, "V" + suffix, counterpartyType, country, branchStatus, now, true);
        BranchWorker inactive = seedBranch(
                companyA, "I" + suffix, normalBranchType, country, branchStatus, now, false);
        BranchWorker b1 = seedBranch(
                companyB, "B1" + suffix, normalBranchType, country, branchStatus, now, true);

        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D1, TransactionType.SELL, PaymentMethod.CARD,
                TransactionStatus.COMPLETED, "38000", "1500", "0", "E01-" + suffix);
        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D1, TransactionType.SELL, PaymentMethod.CARD,
                TransactionStatus.COMPLETED, "38000", "1500", "0", "E02-" + suffix);
        seedPosTx(companyA, a2.branch(), a2.worker(), huf, D1, TransactionType.SELL, PaymentMethod.CARD,
                TransactionStatus.COMPLETED, "20800", "800", "0", "E03-" + suffix);
        seedPosTx(companyA, vaultCounterparty.branch(), vaultCounterparty.worker(), huf, D1,
                TransactionType.SELL, PaymentMethod.CARD, TransactionStatus.COMPLETED,
                "459000", "15000", "0", "E04-" + suffix);
        seedPosTx(companyA, inactive.branch(), inactive.worker(), huf, D1, TransactionType.SELL,
                PaymentMethod.CARD, TransactionStatus.COMPLETED, "67300", "2300", "0", "E05-" + suffix);
        seedPosTx(companyB, b1.branch(), b1.worker(), huf, D1, TransactionType.SELL, PaymentMethod.CARD,
                TransactionStatus.COMPLETED, "89600", "4600", "0", "E06-" + suffix);

        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D1, TransactionType.BUY, PaymentMethod.CARD,
                TransactionStatus.COMPLETED, "99999", "9999", "0", "V01-" + suffix);
        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D1, TransactionType.SELL, PaymentMethod.CASH,
                TransactionStatus.COMPLETED, "88888", "8888", "0", "E07-" + suffix);
        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D1, TransactionType.SELL, null,
                TransactionStatus.COMPLETED, "77777", "7777", "0", "E08-" + suffix);
        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D1, TransactionType.SELL, PaymentMethod.CARD,
                TransactionStatus.REVERSED, "66666", "6666", "0", "E09-" + suffix);
        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D2.plusDays(1), TransactionType.SELL,
                PaymentMethod.CARD, TransactionStatus.COMPLETED, "55555", "5555", "0", "E10-" + suffix);
        seedPosTx(companyA, a1.branch(), a1.worker(), huf, D2, TransactionType.SELL, PaymentMethod.CARD,
                TransactionStatus.COMPLETED, "10005", "0", "5", "E11-" + suffix);

        transactionRepository.flush();
        return new Seed(companyA, a1.branch(), a2.branch());
    }

    private Company seedCompany(String suffix, LocalDateTime now) {
        return companyRepository.save(Company.builder()
                .code("FK059-C-" + suffix)
                .name("FK-059 Company " + suffix)
                .createdAt(now)
                .build());
    }

    private BranchWorker seedBranch(
            Company company,
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now,
            boolean active) {
        Branch branch = branchRepository.save(Branch.builder()
                .code("FK059-B-" + suffix)
                .company(company)
                .bankCode("FK059BANK")
                .branchType(branchType)
                .name("FK-059 Branch " + suffix)
                .address("Test Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .isActive(active)
                .openingDate(D1)
                .createdAt(now)
                .build());
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code("W" + suffix)
                .name("FK-059 Worker " + suffix)
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        return new BranchWorker(branch, worker);
    }

    private Transaction seedPosTx(
            Company company,
            Branch branch,
            Worker worker,
            Currency currency,
            LocalDate date,
            TransactionType type,
            PaymentMethod paymentMethod,
            TransactionStatus status,
            String hufAmount,
            String handlingFee,
            String roundingAmount,
            String receiptNumber) {
        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(status)
                .transactionDate(date)
                .transactionTime(LocalTime.NOON)
                .currency(currency)
                .currencyAmount(BigDecimal.ONE)
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(new BigDecimal(hufAmount))
                .handlingFee(new BigDecimal(handlingFee))
                .roundingAmount(new BigDecimal(roundingAmount))
                .discountAmount(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .financialEffective(true)
                .createdAt(date.atTime(12, 0))
                .build();
        transaction.setPaymentMethod(paymentMethod);
        return transactionRepository.save(transaction);
    }

    private void assertRow(
            Object[] row, LocalDate date, String bankCode, String code, String netAmount, String feeAmount) {
        assertThat(row[0]).isEqualTo(date);
        assertThat(row[1]).isEqualTo(bankCode);
        assertThat(row[2]).isEqualTo(code);
        assertThat((BigDecimal) row[3]).isEqualByComparingTo(netAmount);
        assertThat((BigDecimal) row[4]).isEqualByComparingTo(feeAmount);
    }

    private record BranchWorker(Branch branch, Worker worker) {}

    private record Seed(Company companyA, Branch branchA1, Branch branchA2) {}
}
