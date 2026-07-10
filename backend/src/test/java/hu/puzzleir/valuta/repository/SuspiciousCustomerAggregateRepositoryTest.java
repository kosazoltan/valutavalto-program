package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FS-12 S1: repository-aggregátum tesztek a gyanús ügyfél 3 mintájára.
 */
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
@ActiveProfiles("test")
@Transactional
class SuspiciousCustomerAggregateRepositoryTest {

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionRepository transactionRepository;

    @Test
    @DisplayName("FS-12 S1: count/sum/distinctBranch aggregátum és total desc rendezés helyes")
    void aggregatesMetricsAndSortsByTotalDesc() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS12AGG", now);
        Branch otherBranch = createBranch(tenant, "FS12AGG2", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withCustomer(transaction(tenant, "FS12-A-1", TransactionType.BUY, day, LocalTime.of(9, 0), eur, "1000.00"), "CUST-A", "Kovács Béla"));
        transactionRepository.save(withCustomer(transaction(tenant, "FS12-A-2", TransactionType.SELL, day, LocalTime.of(10, 0), eur, "2000.00"), "CUST-A", "Kovács Béla"));
        transactionRepository.save(withBranch(withCustomer(transaction(tenant, "FS12-A-3", TransactionType.BUY, day, LocalTime.of(11, 0), eur, "3000.00"), "CUST-A", "Kovács Béla"), otherBranch));
        transactionRepository.save(withCustomer(transaction(tenant, "FS12-B-1", TransactionType.BUY, day, LocalTime.of(12, 0), eur, "9000.00"), "CUST-B", "Nagy Anna"));
        transactionRepository.flush();

        List<Object[]> rows = find(tenant, day, true, 3, true, new BigDecimal("5000.00"), true, 2);

        assertThat(rows).hasSize(2);
        assertRow(rows.get(0), "CUST-B", "Nagy Anna", 1L, new BigDecimal("9000.00"), 1L);
        assertRow(rows.get(1), "CUST-A", "Kovács Béla", 3L, new BigDecimal("6000.00"), 2L);
    }

    @Test
    @DisplayName("FS-12 S1: azonos customerId más cégnél nem szennyezi az aggregátumot")
    void sameCustomerIdInOtherCompanyIsExcluded() {
        LocalDateTime now = LocalDateTime.now();
        Tenant own = seedTenant("FS12TEN", now);
        Tenant foreign = seedTenant("FS12TENB", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withCustomer(transaction(own, "FS12-T-OWN", TransactionType.BUY, day, LocalTime.of(9, 0), eur, "4000.00"), "SHARED", "Saját Ügyfél"));
        transactionRepository.save(withCustomer(transaction(foreign, "FS12-T-FOREIGN", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "7000.00"), "SHARED", "Idegen Ügyfél"));
        transactionRepository.flush();

        List<Object[]> rows = find(own, day, false, 99, true, new BigDecimal("1.00"), false, 99);

        assertThat(rows).hasSize(1);
        assertRow(rows.get(0), "SHARED", "Saját Ügyfél", 1L, new BigDecimal("4000.00"), 1L);
    }

    @Test
    @DisplayName("FS-12 S1: REVERSED, financialEffective=false, null/üres customerId sor nem számít")
    void excludesReversedFinancialIneffectiveAndBlankCustomers() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS12EXC", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withCustomer(transaction(tenant, "FS12-E-OK", TransactionType.BUY, day, LocalTime.of(9, 0), eur, "1000.00"), "VALID", "Valós Ügyfél"));
        transactionRepository.save(withStatus(withCustomer(transaction(tenant, "FS12-E-REV", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "9000.00"), "VALID", "Valós Ügyfél"), TransactionStatus.REVERSED));
        transactionRepository.save(withFinancialEffective(withCustomer(transaction(tenant, "FS12-E-FE", TransactionType.CONVERSION, day, LocalTime.of(11, 0), eur, "9000.00"), "VALID", "Valós Ügyfél"), false));
        transactionRepository.save(withCustomer(transaction(tenant, "FS12-E-NULL", TransactionType.BUY, day, LocalTime.of(12, 0), eur, "9000.00"), null, "Nincs ID"));
        transactionRepository.save(withCustomer(transaction(tenant, "FS12-E-BLANK", TransactionType.BUY, day, LocalTime.of(13, 0), eur, "9000.00"), "", "Üres ID"));
        transactionRepository.flush();

        List<Object[]> rows = find(tenant, day, false, 99, true, new BigDecimal("1.00"), false, 99);

        assertThat(rows).hasSize(1);
        assertRow(rows.get(0), "VALID", "Valós Ügyfél", 1L, new BigDecimal("1000.00"), 1L);
    }

    @Test
    @DisplayName("FS-12 S1: bekapcsolt feltételek OR-szemantikával szűrnek")
    void enabledConditionsUseOrSemantics() {
        LocalDateTime now = LocalDateTime.now();
        Tenant tenant = seedTenant("FS12OR", now);
        Currency eur = findOrCreateCurrency("EUR", "Euró", "€", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 8);

        transactionRepository.save(withCustomer(transaction(tenant, "FS12-O-C1", TransactionType.BUY, day, LocalTime.of(9, 0), eur, "1000.00"), "COUNTY", "Sok Tranzakció"));
        transactionRepository.save(withCustomer(transaction(tenant, "FS12-O-C2", TransactionType.BUY, day, LocalTime.of(10, 0), eur, "1000.00"), "COUNTY", "Sok Tranzakció"));
        transactionRepository.save(withCustomer(transaction(tenant, "FS12-O-V1", TransactionType.BUY, day, LocalTime.of(11, 0), eur, "9000.00"), "VALUEY", "Nagy Összeg"));
        transactionRepository.flush();

        List<Object[]> countOnly = find(tenant, day, true, 2, false, new BigDecimal("5000.00"), false, 99);
        List<Object[]> countOrValue = find(tenant, day, true, 2, true, new BigDecimal("5000.00"), false, 99);

        assertThat(countOnly).extracting(row -> (String) row[0]).containsExactly("COUNTY");
        assertThat(countOrValue).extracting(row -> (String) row[0]).containsExactly("VALUEY", "COUNTY");
    }

    private List<Object[]> find(Tenant tenant, LocalDate day,
            boolean byTransactionCount, long minTransactionCount,
            boolean byTotalValue, BigDecimal minTotalHuf,
            boolean byBranchCount, long minBranchCount) {
        return transactionRepository.findSuspiciousCustomerAggregates(
                tenant.company().getId(), day.minusDays(1), day.plusDays(1),
                byTransactionCount, minTransactionCount, byTotalValue, minTotalHuf, byBranchCount, minBranchCount);
    }

    private static void assertRow(Object[] row, String customerId, String customerName, long count, BigDecimal total, long branches) {
        assertThat((String) row[0]).isEqualTo(customerId);
        assertThat((String) row[1]).isEqualTo(customerName);
        assertThat(((Number) row[2]).longValue()).isEqualTo(count);
        assertThat((BigDecimal) row[3]).isEqualByComparingTo(total);
        assertThat(((Number) row[4]).longValue()).isEqualTo(branches);
    }

    private Tenant seedTenant(String prefix, LocalDateTime now) {
        String suffix = prefix + "-" + Long.toString(System.nanoTime());
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix))
                .name("FS-12 S1 Company " + suffix)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(shortCode("BT", suffix))
                .name("FS-12 S1 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(shortCode("CO", suffix))
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary statusDictionary = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(shortCode("BS", suffix))
                .name("Active")
                .createdAt(now)
                .build());
        Branch branch = branchRepository.save(Branch.builder()
                .code(shortCode("BR", suffix))
                .company(company)
                .bankCode("FS12BANK")
                .branchType(branchType)
                .name("FS-12 S1 Branch " + suffix)
                .address("Compliance utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(statusDictionary)
                .openingDate(LocalDate.of(2026, 1, 1))
                .createdAt(now)
                .build());
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code(shortCode("W", suffix))
                .name("FS-12 S1 Pénztáros")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        return new Tenant(company, branch, worker);
    }

    private Branch createBranch(Tenant tenant, String prefix, LocalDateTime now) {
        String suffix = prefix + "-" + Long.toString(System.nanoTime());
        return branchRepository.save(Branch.builder()
                .code(shortCode("BR", suffix))
                .company(tenant.company())
                .bankCode("FS12BANK")
                .branchType(tenant.branch().getBranchType())
                .name("FS-12 S1 Other Branch " + suffix)
                .address("Compliance utca 2")
                .city("Budapest")
                .zipCode("1000")
                .country(tenant.branch().getCountry())
                .branchStatus(tenant.branch().getBranchStatus())
                .openingDate(LocalDate.of(2026, 1, 1))
                .createdAt(now)
                .build());
    }

    private Currency findOrCreateCurrency(String code, String name, String symbol, int decimalPlaces, int displayOrder, LocalDateTime now) {
        return currencyRepository.findByCode(code)
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code(code)
                        .name(name)
                        .symbol(symbol)
                        .decimalPlaces(decimalPlaces)
                        .active(true)
                        .displayOrder(displayOrder)
                        .createdAt(now)
                        .build()));
    }

    private Transaction transaction(Tenant tenant, String receiptNumber, TransactionType type, LocalDate businessDate, LocalTime time, Currency currency, String hufAmount) {
        return Transaction.builder()
                .company(tenant.company())
                .branch(tenant.branch())
                .worker(tenant.worker())
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(businessDate)
                .transactionTime(time)
                .currency(currency)
                .currencyAmount(new BigDecimal("10.00"))
                .exchangeRate(new BigDecimal("400.0000"))
                .hufAmount(new BigDecimal(hufAmount))
                .handlingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .discountTypeCode(0)
                .customerId("FS12-CUST")
                .customerName("FS-12 S1 Ügyfél")
                .customerDocumentNumber("AB123456")
                .financialEffective(true)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private static Transaction withCustomer(Transaction transaction, String customerId, String customerName) {
        transaction.setCustomerId(customerId);
        transaction.setCustomerName(customerName);
        return transaction;
    }

    private static Transaction withBranch(Transaction transaction, Branch branch) {
        transaction.setBranch(branch);
        return transaction;
    }

    private static Transaction withStatus(Transaction transaction, TransactionStatus status) {
        transaction.setStatus(status);
        return transaction;
    }

    private static Transaction withFinancialEffective(Transaction transaction, boolean financialEffective) {
        transaction.setFinancialEffective(financialEffective);
        return transaction;
    }

    private static String shortCode(String prefix, String suffix) {
        String compactPrefix = prefix.replaceAll("[^A-Z0-9]", "");
        String hash = Long.toString(Integer.toUnsignedLong(suffix.hashCode()), 36).toUpperCase();
        String compact = compactPrefix + hash;
        return compact.substring(0, Math.min(10, compact.length()));
    }

    private record Tenant(Company company, Branch branch, Worker worker) {}
}
