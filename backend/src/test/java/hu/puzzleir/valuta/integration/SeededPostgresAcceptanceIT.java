package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DailySessionRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
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
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

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
class SeededPostgresAcceptanceIT {

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
    @Autowired private ExchangeRateRepository exchangeRateRepository;
    @Autowired private CashBalanceRepository cashBalanceRepository;
    @Autowired private DailySessionRepository dailySessionRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("seedelt PostgreSQL acceptance: napnyitas + vetel/eladas adatok es riport query-k egyutt mukodnek")
    void seededPostgresBuySellAndDaySessionRoundTrip() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seedAcceptanceBranch("APR-A");
            LocalDate businessDate = LocalDate.now();

            DailySession session = dailySessionRepository.save(DailySession.builder()
                    .company(seed.company())
                    .branch(seed.branch())
                    .sessionDate(businessDate)
                    .status(DailySessionStatus.OPEN)
                    .openedByWorker(seed.worker())
                    .openedAt(LocalDateTime.now())
                    .openingBalanceHuf(new BigDecimal("10000000.00"))
                    .transactionCount(2)
                    .buyCount(1)
                    .sellCount(1)
                    .buyTurnoverHuf(new BigDecimal("39000.00"))
                    .sellTurnoverHuf(new BigDecimal("16000.00"))
                    .createdAt(LocalDateTime.now())
                    .build());

            ExchangeRate rate = exchangeRateRepository.save(ExchangeRate.builder()
                    .company(seed.company())
                    .branch(seed.branch())
                    .currency(seed.eur())
                    .validDate(businessDate)
                    .validTime(LocalTime.of(9, 0))
                    .baseBuyRate(new BigDecimal("390.0000"))
                    .baseSellRate(new BigDecimal("400.0000"))
                    .officialRate(new BigDecimal("395.0000"))
                    .active(true)
                    .createdAt(LocalDateTime.now())
                    .build());

            CashBalance hufBalance = cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(seed.branch().getId(), seed.huf().getId(), seed.company().getId()).orElseThrow();
            CashBalance eurBalance = cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(seed.branch().getId(), seed.eur().getId(), seed.company().getId()).orElseThrow();

            hufBalance.subtractBalance(new BigDecimal("39000.00"));
            eurBalance.addBalance(new BigDecimal("100.00"));
            eurBalance.subtractBalance(new BigDecimal("40.00"));
            hufBalance.addBalance(new BigDecimal("16000.00"));

            cashBalanceRepository.saveAll(List.of(hufBalance, eurBalance));

            Transaction buy = transactionRepository.save(newTransaction(
                    seed, "VTC001", TransactionType.BUY, businessDate,
                    new BigDecimal("100.00"), rate.getBaseBuyRate(), new BigDecimal("39000.00"),
                    "BUY-CUST-001"));
            Transaction sell = transactionRepository.save(newTransaction(
                    seed, "ETC001", TransactionType.SELL, businessDate,
                    new BigDecimal("40.00"), rate.getBaseSellRate(), new BigDecimal("16000.00"),
                    "SELL-CUST-001"));
            transactionRepository.flush();

            assertThat(buy.getId()).isNotNull();
            assertThat(sell.getId()).isNotNull();
            assertThat(session.getId()).isNotNull();

            assertThat(exchangeRateRepository.findCurrentRate(
                    seed.company().getId(), seed.eur().getId(), seed.branch().getId()))
                    .hasSize(1)
                    .first()
                    .extracting(ExchangeRate::getBaseSellRate)
                    .isEqualTo(new BigDecimal("400.0000"));

            assertThat(transactionRepository.findByBranchAndDate(seed.branch().getId(), businessDate))
                    .extracting(Transaction::getReceiptNumber)
                    .containsExactlyInAnyOrder("ETC001", "VTC001");
            assertThat(transactionRepository.sumDailyTurnover(
                    seed.company().getId(), seed.branch().getId(), businessDate, TransactionType.BUY))
                    .isEqualByComparingTo("39000.00");
            assertThat(transactionRepository.sumDailyTurnover(
                    seed.company().getId(), seed.branch().getId(), businessDate, TransactionType.SELL))
                    .isEqualByComparingTo("16000.00");

            assertThat(cashBalanceRepository.findByBranchIdAndCurrencyCode(seed.branch().getId(), "HUF").orElseThrow()
                    .getCurrentBalance()).isEqualByComparingTo("9977000.00");
            assertThat(cashBalanceRepository.findByBranchIdAndCurrencyCode(seed.branch().getId(), "EUR").orElseThrow()
                    .getCurrentBalance()).isEqualByComparingTo("5060.00");
            assertThat(dailySessionRepository.findOpenSessionByBranchAndDate(
                    seed.company().getId(), seed.branch().getId(), businessDate))
                    .isPresent()
                    .get()
                    .extracting(DailySession::getTransactionCount)
                    .isEqualTo(2);
        });
    }

    @Test
    @DisplayName("seedelt PostgreSQL acceptance: cegszuert bizonylatkereses nem szivarogtat masik tenantbol")
    void receiptLookupIsCompanyScopedOnSeededPostgresData() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed firstTenant = seedAcceptanceBranch("APR-B1");
            Seed secondTenant = seedAcceptanceBranch("APR-B2");
            LocalDate businessDate = LocalDate.now();

            transactionRepository.save(newTransaction(
                    firstTenant, "VSHARED001", TransactionType.BUY, businessDate,
                    new BigDecimal("10.00"), new BigDecimal("390.0000"), new BigDecimal("3900.00"),
                    "FIRST-TENANT"));
            transactionRepository.save(newTransaction(
                    secondTenant, "VSHARED001", TransactionType.BUY, businessDate,
                    new BigDecimal("20.00"), new BigDecimal("391.0000"), new BigDecimal("7820.00"),
                    "SECOND-TENANT"));
            transactionRepository.flush();

            Optional<Transaction> firstLookup = transactionRepository.findByReceiptNumberAndCompanyId(
                    "VSHARED001", firstTenant.company().getId());
            Optional<Transaction> secondLookup = transactionRepository.findByReceiptNumberAndCompanyId(
                    "VSHARED001", secondTenant.company().getId());

            assertThat(firstLookup).isPresent();
            assertThat(firstLookup.get().getCustomerId()).isEqualTo("FIRST-TENANT");
            assertThat(secondLookup).isPresent();
            assertThat(secondLookup.get().getCustomerId()).isEqualTo("SECOND-TENANT");
        });
    }

    private Seed seedAcceptanceBranch(String prefix) {
        LocalDateTime now = LocalDateTime.now();
        String suffix = prefix + "-" + Long.toString(System.nanoTime());
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix))
                .name("Acceptance Company " + suffix)
                .createdAt(now)
                .build());

        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(shortCode("BT", suffix))
                .name("Acceptance branch type")
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
                .bankCode("ACCBANK")
                .branchType(branchType)
                .name("Acceptance Branch " + suffix)
                .address("Acceptance Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(statusDictionary)
                .openingDate(LocalDate.now())
                .createdAt(now)
                .build());

        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code(shortCode("W", suffix))
                .name("Acceptance Cashier")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());

        Currency huf = findOrCreateCurrency("HUF", "Forint", "Ft", 0, 1, now);
        Currency eur = findOrCreateCurrency("EUR", "Euro", "EUR", 2, 2, now);

        cashBalanceRepository.save(CashBalance.builder()
                .company(company)
                .branch(branch)
                .currency(huf)
                .openingBalance(new BigDecimal("10000000.00"))
                .currentBalance(new BigDecimal("10000000.00"))
                .createdAt(now)
                .build());
        cashBalanceRepository.save(CashBalance.builder()
                .company(company)
                .branch(branch)
                .currency(eur)
                .openingBalance(new BigDecimal("5000.00"))
                .currentBalance(new BigDecimal("5000.00"))
                .createdAt(now)
                .build());

        return new Seed(company, branch, worker, huf, eur);
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

    private Transaction newTransaction(
            Seed seed,
            String receiptNumber,
            TransactionType type,
            LocalDate businessDate,
            BigDecimal currencyAmount,
            BigDecimal exchangeRate,
            BigDecimal hufAmount,
            String customerId) {
        return Transaction.builder()
                .company(seed.company())
                .branch(seed.branch())
                .worker(seed.worker())
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(businessDate)
                .transactionTime(LocalTime.now())
                .currency(seed.eur())
                .currencyAmount(currencyAmount)
                .exchangeRate(exchangeRate)
                .hufAmount(hufAmount)
                .handlingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .customerId(customerId)
                .customerName("Acceptance Customer")
                .customerDocumentNumber("AB123456")
                .financialEffective(true)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private static String shortCode(String prefix, String value) {
        String digits = value.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return (prefix + tail);
    }

    private record Seed(Company company, Branch branch, Worker worker, Currency huf, Currency eur) {
    }
}
