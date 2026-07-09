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
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FS11-LOWER-BYTEA regresszio: a compliance kereső JPQL String parameterei
 * valos PostgreSQL-en null esetben sem kotodhetnek bytea-kent a LOWER(...) kifejezesben.
 */
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
@Transactional
class TransactionRepositoryComplianceSearchIT {

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
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionRepository transactionRepository;

    @Test
    @DisplayName("FS11-LOWER-BYTEA: ures szoveges szurokkel a default lista nem dob lower(bytea) hibat")
    void allTextFiltersNullReturnsPageOnPostgres() {
        LocalDateTime now = LocalDateTime.now();
        Tenant own = seedTenant("LBNULLA", now);
        Tenant foreign = seedTenant("LBNULLB", now);
        Currency eur = findOrCreateCurrency("EUR", "Euro", "EUR", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 9);

        transactionRepository.save(transaction(own, "LB-NULL-OWN-1", day, LocalTime.of(10, 0), eur, "Teszt Elek"));
        transactionRepository.save(transaction(own, "LB-NULL-OWN-2", day, LocalTime.of(11, 0), eur, "Masik Ugyfel"));
        transactionRepository.save(transaction(foreign, "LB-NULL-FOREIGN", day, LocalTime.of(12, 0), eur, "Teszt Elek"));
        transactionRepository.flush();

        Page<Transaction> result = search(own, null, PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber)
                .containsExactly("LB-NULL-OWN-2", "LB-NULL-OWN-1");
        assertThat(result.getTotalElements()).isEqualTo(2);
    }

    @Test
    @DisplayName("FS11-LOWER-BYTEA: customerName szuro nem dob, reszszovegre es companyId-ra szur")
    void customerNameFilterDoesNotThrowAndRespectsCompanyScope() {
        LocalDateTime now = LocalDateTime.now();
        Tenant own = seedTenant("LBNAMEA", now);
        Tenant foreign = seedTenant("LBNAMEB", now);
        Currency eur = findOrCreateCurrency("EUR", "Euro", "EUR", 2, 1, now);
        LocalDate day = LocalDate.of(2026, 7, 9);

        transactionRepository.save(transaction(own, "LB-NAME-MATCH", day, LocalTime.of(10, 0), eur, "Test Bela"));
        transactionRepository.save(transaction(own, "LB-NAME-NOMATCH", day, LocalTime.of(11, 0), eur, "Nagy Anna"));
        transactionRepository.save(transaction(foreign, "LB-NAME-FOREIGN", day, LocalTime.of(12, 0), eur, "Test Bela"));
        transactionRepository.flush();

        Page<Transaction> result = search(own, "test", PageRequest.of(0, 20));

        assertThat(result.getContent()).extracting(Transaction::getReceiptNumber)
                .containsExactly("LB-NAME-MATCH");
        assertThat(result.getTotalElements()).isEqualTo(1);
    }

    private Page<Transaction> search(Tenant tenant, String customerName, org.springframework.data.domain.Pageable pageable) {
        return transactionRepository.searchComplianceTransactions(
                tenant.company().getId(), null, null, null, null, null, null,
                true, List.of(-1L), (PaymentMethod) null, false, false, false, false,
                customerName, null, null, null, false, null, null, null, null, pageable);
    }

    private Tenant seedTenant(String prefix, LocalDateTime now) {
        String suffix = prefix + "-" + Long.toString(System.nanoTime());
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix))
                .name("FS11 lower bytea Company " + suffix)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(shortCode("BT", suffix))
                .name("Test branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(shortCode("CO", suffix))
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary status = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(shortCode("BS", suffix))
                .name("Active")
                .createdAt(now)
                .build());
        Branch branch = branchRepository.save(Branch.builder()
                .code(shortCode("BR", suffix))
                .company(company)
                .bankCode("LBANK")
                .branchType(branchType)
                .name("FS11 lower bytea Branch " + suffix)
                .address("Compliance utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(status)
                .openingDate(LocalDate.of(2026, 1, 1))
                .createdAt(now)
                .build());
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code(shortCode("W", suffix))
                .name("FS11 lower bytea Worker")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        return new Tenant(company, branch, worker);
    }

    private Currency findOrCreateCurrency(
            String code,
            String name,
            String symbol,
            int decimalPlaces,
            int displayOrder,
            LocalDateTime now) {
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

    private Transaction transaction(
            Tenant tenant,
            String receiptNumber,
            LocalDate businessDate,
            LocalTime time,
            Currency currency,
            String customerName) {
        return Transaction.builder()
                .company(tenant.company())
                .branch(tenant.branch())
                .worker(tenant.worker())
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(businessDate)
                .transactionTime(time)
                .currency(currency)
                .currencyAmount(new BigDecimal("10.00"))
                .exchangeRate(new BigDecimal("400.0000"))
                .hufAmount(new BigDecimal("4000.00"))
                .handlingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .discountTypeCode(0)
                .customerId("LB-CUST")
                .customerName(customerName)
                .customerDocumentNumber("AB123456")
                .financialEffective(true)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private static String shortCode(String prefix, String value) {
        String digits = value.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return prefix + tail;
    }

    private record Tenant(Company company, Branch branch, Worker worker) {
    }
}
