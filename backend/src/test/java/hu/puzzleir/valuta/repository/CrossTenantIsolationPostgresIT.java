package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Pageable;
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
class CrossTenantIsolationPostgresIT {

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
    @Autowired private TransferRepository transferRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private DailyBalanceRepository dailyBalanceRepository;
    @Autowired private DailySessionRepository dailySessionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("TransferRepository tenant guard: idegen branch id nem szivarogtat adatot")
    void transferQueriesReturnEmptyForForeignBranchAndCompanyScopedSearch() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seedTwoTenants("TR");
            LocalDate today = seed.businessDate();
            LocalDate from = today.minusDays(1);
            LocalDate to = today.plusDays(1);
            UUID companyA = seed.companyA().getId();
            UUID branchA = seed.branchA().getId();
            UUID branchB = seed.branchB().getId();

            assertThat(transferRepository.findOutgoingByBranch(companyA, branchB)).isEmpty();
            assertThat(transferRepository.findIncomingByBranch(companyA, branchB)).isEmpty();
            assertThat(transferRepository.countPendingByBranch(companyA, branchB)).isZero();
            assertThat(transferRepository.sumTransfersInByPeriod(companyA, branchB, from, to)).isEmpty();
            assertThat(transferRepository.sumTransfersOutByPeriod(companyA, branchB, from, to)).isEmpty();
            assertThat(transferRepository.findByFromBranchIdOrderByCreatedAtDesc(companyA, branchB)).isEmpty();
            assertThat(transferRepository.findByToBranchIdOrderByCreatedAtDesc(companyA, branchB)).isEmpty();

            assertThat(transferRepository.search(companyA, null, null, null, null, null, Pageable.unpaged()))
                    .extracting(Transfer::getTransferNumber)
                    .containsExactly("TR-A-PENDING");
            assertThat(transferRepository.findOutgoingByBranch(companyA, branchA))
                    .extracting(Transfer::getTransferNumber)
                    .containsExactly("TR-A-PENDING");
        });
    }

    @Test
    @DisplayName("TransactionRepository.sumDailyTurnover tenant guard: idegen branch nulla, sajat branch valos osszeg")
    void sumDailyTurnoverIsCompanyScoped() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seedTwoTenants("TX");
            UUID companyA = seed.companyA().getId();

            assertThat(transactionRepository.sumDailyTurnover(
                    companyA, seed.branchB().getId(), seed.businessDate(), TransactionType.BUY))
                    .isEqualByComparingTo(BigDecimal.ZERO);
            assertThat(transactionRepository.sumDailyTurnover(
                    companyA, seed.branchA().getId(), seed.businessDate(), TransactionType.BUY))
                    .isEqualByComparingTo("1000.00");
        });
    }

    @Test
    @DisplayName("DailyBalanceRepository tenant guard: idegen branch/lista nem hoz mas tenant adatot")
    void dailyBalanceQueriesAreCompanyScoped() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seedTwoTenants("DB");
            UUID companyA = seed.companyA().getId();
            UUID branchA = seed.branchA().getId();
            UUID branchB = seed.branchB().getId();
            LocalDate today = seed.businessDate();

            assertThat(dailyBalanceRepository.findByBranchIdAndBalanceDate(companyA, branchB, today)).isEmpty();
            assertThat(dailyBalanceRepository.findByBranchIdsAndDate(companyA, List.of(branchA, branchB), today))
                    .extracting(DailyBalance::getBranchId)
                    .containsExactly(branchA);
            assertThat(dailyBalanceRepository.findClosedDates(
                    companyA, branchB, today.minusDays(1), today.plusDays(1))).isEmpty();

            assertThat(dailyBalanceRepository.findByBranchIdAndBalanceDate(companyA, branchA, today))
                    .hasSize(1)
                    .first()
                    .extracting(DailyBalance::getCurrencyCode)
                    .isEqualTo("EUR");
        });
    }

    @Test
    @DisplayName("DailySessionRepository tenant guard: branchId-only session query-k companyId szerint szurnek")
    void dailySessionQueriesAreCompanyScoped() {
        transactionTemplate.executeWithoutResult(status -> {
            Seed seed = seedTwoTenants("DS");
            UUID companyA = seed.companyA().getId();
            UUID branchA = seed.branchA().getId();
            UUID branchB = seed.branchB().getId();
            LocalDate today = seed.businessDate();

            assertThat(dailySessionRepository.findOpenSessionsByBranch(companyA, branchB)).isEmpty();
            assertThat(dailySessionRepository.findByBranchIdAndSessionDate(companyA, branchB, today)).isEmpty();
            assertThat(dailySessionRepository.countOpenSessionsInRange(
                    companyA, branchB, today.minusDays(1), today.plusDays(1))).isZero();

            assertThat(dailySessionRepository.findOpenSessionsByBranch(companyA, branchA)).hasSize(1);
            assertThat(dailySessionRepository.findByBranchIdAndSessionDate(companyA, branchA, today)).isPresent();
        });
    }

    private Seed seedTwoTenants(String prefix) {
        LocalDateTime now = LocalDateTime.now();
        LocalDate businessDate = LocalDate.now();
        Tenant tenantA = seedTenant(prefix + "A", now);
        Tenant tenantB = seedTenant(prefix + "B", now);
        Currency huf = findOrCreateCurrency("HUF", "Forint", "Ft", 0, 1, now);
        Currency eur = findOrCreateCurrency("EUR", "Euro", "EUR", 2, 2, now);

        transferRepository.save(transfer("TR-A-PENDING", tenantA, tenantA, Transfer.TransferStatus.PENDING,
                businessDate, eur, "100.00"));
        transferRepository.save(transfer("TR-B-PENDING", tenantB, tenantB, Transfer.TransferStatus.PENDING,
                businessDate, eur, "200.00"));
        transferRepository.save(transfer("TR-B-IN-TRANSIT", tenantB, tenantB, Transfer.TransferStatus.IN_TRANSIT,
                businessDate, eur, "300.00"));
        transferRepository.save(transfer("TR-B-COMPLETED", tenantB, tenantB, Transfer.TransferStatus.COMPLETED,
                businessDate, eur, "400.00"));

        transactionRepository.save(transaction(tenantA, "V-A-001", TransactionType.BUY, businessDate,
                eur, "10.00", "100.0000", "1000.00", "TENANT-A"));
        transactionRepository.save(transaction(tenantB, "V-B-001", TransactionType.BUY, businessDate,
                eur, "20.00", "4999.9500", "99999.00", "TENANT-B"));

        dailyBalanceRepository.save(dailyBalance(tenantA, businessDate, eur, "100.00"));
        dailyBalanceRepository.save(dailyBalance(tenantB, businessDate, eur, "999.00"));

        dailySessionRepository.save(dailySession(tenantA, businessDate));
        dailySessionRepository.save(dailySession(tenantB, businessDate));
        transferRepository.flush();
        transactionRepository.flush();
        dailyBalanceRepository.flush();
        dailySessionRepository.flush();

        return new Seed(tenantA.company(), tenantA.branch(), tenantB.company(), tenantB.branch(), huf, eur, businessDate);
    }

    private Tenant seedTenant(String prefix, LocalDateTime now) {
        String suffix = prefix + "-" + Long.toString(System.nanoTime());
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("C", suffix))
                .name("Cross Tenant Company " + suffix)
                .createdAt(now)
                .build());

        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(shortCode("BT", suffix))
                .name("Cross tenant branch type")
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
                .bankCode("CTBANK")
                .branchType(branchType)
                .name("Cross Tenant Branch " + suffix)
                .address("Cross Tenant Street 1")
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
                .name("Cross Tenant Cashier")
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

    private Transfer transfer(
            String number,
            Tenant from,
            Tenant to,
            Transfer.TransferStatus status,
            LocalDate businessDate,
            Currency currency,
            String amount) {
        return Transfer.builder()
                .transferNumber(number)
                .companyId(from.company().getId())
                .fromBranch(from.branch())
                .toBranch(to.branch())
                .fromWorker(from.worker())
                .toWorker(to.worker())
                .transferType(Transfer.TransferType.CURRENCY)
                .status(status)
                .transferDate(businessDate)
                .transferTime(LocalTime.now())
                .currency(currency)
                .amount(new BigDecimal(amount))
                .hufValue(new BigDecimal(amount).multiply(new BigDecimal("400.00")))
                .createdAt(LocalDateTime.now())
                .build();
    }

    private Transaction transaction(
            Tenant tenant,
            String receiptNumber,
            TransactionType type,
            LocalDate businessDate,
            Currency currency,
            String currencyAmount,
            String exchangeRate,
            String hufAmount,
            String customerId) {
        return Transaction.builder()
                .company(tenant.company())
                .branch(tenant.branch())
                .worker(tenant.worker())
                .receiptNumber(receiptNumber)
                .transactionType(type)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(businessDate)
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(new BigDecimal(currencyAmount))
                .exchangeRate(new BigDecimal(exchangeRate))
                .hufAmount(new BigDecimal(hufAmount))
                .handlingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .customerId(customerId)
                .customerName("Cross Tenant Customer")
                .customerDocumentNumber("AB123456")
                .financialEffective(true)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private DailyBalance dailyBalance(Tenant tenant, LocalDate businessDate, Currency currency, String closingBalance) {
        return DailyBalance.builder()
                .company(tenant.company())
                .branchId(tenant.branch().getId())
                .balanceDate(businessDate)
                .currencyCode(currency.getCode())
                .openingBalance(BigDecimal.ZERO)
                .purchases(BigDecimal.ZERO)
                .sales(BigDecimal.ZERO)
                .closingBalance(new BigDecimal(closingBalance))
                .isClosed(true)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private DailySession dailySession(Tenant tenant, LocalDate businessDate) {
        return DailySession.builder()
                .company(tenant.company())
                .branch(tenant.branch())
                .sessionDate(businessDate)
                .status(DailySessionStatus.OPEN)
                .openedByWorker(tenant.worker())
                .openedAt(LocalDateTime.now())
                .openingBalanceHuf(new BigDecimal("1000000.00"))
                .createdAt(LocalDateTime.now())
                .build();
    }

    private static String shortCode(String prefix, String value) {
        String digits = value.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return (prefix + tail);
    }

    private record Tenant(Company company, Branch branch, Worker worker) {
    }

    private record Seed(
            Company companyA,
            Branch branchA,
            Company companyB,
            Branch branchB,
            Currency huf,
            Currency eur,
            LocalDate businessDate) {
    }
}
