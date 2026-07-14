package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AmlApprovalService;
import hu.puzzleir.valuta.service.AmlService;
import hu.puzzleir.valuta.service.DailySessionService;
import hu.puzzleir.valuta.service.ExchangeRateService;
import hu.puzzleir.valuta.service.HandlingFeeCalculator;
import hu.puzzleir.valuta.service.HandlingFeeOverrideService;
import hu.puzzleir.valuta.service.LicenseService;
import hu.puzzleir.valuta.service.PmtComplianceValidator;
import hu.puzzleir.valuta.service.PosTerminalService;
import hu.puzzleir.valuta.service.ReceiptSequenceService;
import hu.puzzleir.valuta.service.SystemParameterService;
import hu.puzzleir.valuta.service.TransactionCalculationService;
import hu.puzzleir.valuta.service.TransactionConversionService;
import hu.puzzleir.valuta.service.TransactionMultiLineService;
import hu.puzzleir.valuta.service.TransactionReversalService;
import hu.puzzleir.valuta.service.TransactionService;
import hu.puzzleir.valuta.service.TransactionValidationService;
import hu.puzzleir.valuta.service.ValueBandService;
import hu.puzzleir.valuta.service.VaultStockFlowService;
import hu.puzzleir.valuta.service.WacService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mockStatic;

/**
 * FR-6 holdout: a napi turnover tranzakciós és Shipment-eredetű kezelési díját valós
 * PostgreSQL-en, Flyway-sémán és a tényleges {@link TransactionService} útvonalon bizonyítja.
 */
@Testcontainers
@EnableJpaAuditing
@Import(TransactionService.class)
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class DailyTurnoverHandlingFeePostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private TransactionService transactionService;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private ShipmentHandlingFeeRepository feeRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @MockitoBean private DailySessionService dailySessionService;
    @MockitoBean private ExchangeRateService exchangeRateService;
    @MockitoBean private ReceiptSequenceService receiptSequenceService;
    @MockitoBean private HandlingFeeCalculator handlingFeeCalculator;
    @MockitoBean private HandlingFeeOverrideService handlingFeeOverrideService;
    @MockitoBean private AmlService amlService;
    @MockitoBean private AmlApprovalService amlApprovalService;
    @MockitoBean private PosTerminalService posTerminalService;
    @MockitoBean private TransactionCalculationService transactionCalculationService;
    @MockitoBean private TransactionReversalService transactionReversalService;
    @MockitoBean private TransactionConversionService transactionConversionService;
    @MockitoBean private TransactionMultiLineService transactionMultiLineService;
    @MockitoBean private PmtComplianceValidator pmtComplianceValidator;
    @MockitoBean private LicenseService licenseService;
    @MockitoBean private SystemParameterService systemParameterService;
    @MockitoBean private WacService wacService;
    @MockitoBean private TransactionValidationService transactionValidationService;
    @MockitoBean private VaultStockFlowService vaultStockFlowService;
    @MockitoBean private ValueBandService valueBandService;

    @Test
    @DisplayName("FR-6: a napi KPI tenantonként additív tranzakciós + fogadott Shipment hufAmount")
    void dailyTurnoverAddsTransactionAndReceivedShipmentFeesWithoutCrossTenantLeakage() {
        LocalDate date = LocalDate.now();
        Seed seed = transactionTemplate.execute(status -> seed(date));

        assertThat(seed).isNotNull();
        assertTurnover(seed.companyA().getId(), seed.vaultA().getId(), date, "2125.00");
        assertTurnover(seed.companyB().getId(), seed.vaultB().getId(), date, "3400.00");

        assertThat(feeRepository.sumDailyReceivedFees(
                seed.companyA().getId(), seed.vaultA().getId(), date))
                .isEqualByComparingTo("625.00");
        assertThat(feeRepository.sumDailyReceivedFees(
                seed.companyB().getId(), seed.vaultB().getId(), date))
                .isEqualByComparingTo("400.00");
    }

    private void assertTurnover(
            UUID companyId,
            UUID branchId,
            LocalDate date,
            String expectedHandlingFees) {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchId).thenReturn(branchId);

            assertThat(transactionService.getDailyTurnoverForDate(date).getTotalHandlingFees())
                    .isEqualByComparingTo(expectedHandlingFees);
        }
    }

    private Seed seed(LocalDate date) {
        LocalDateTime now = date.atTime(12, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code("FR6-BT-" + suffix)
                .name("FR-6 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code("FR6-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code("FR6-BS-" + suffix)
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

        transactionRepository.save(transaction(tenantA, huf, date, "FR6-A-" + suffix, "1500.00"));
        transactionRepository.save(transaction(tenantB, huf, date, "FR6-B-" + suffix, "3000.00"));

        saveShipmentFee(tenantA, date.atTime(9, 0), ShipmentRequestStatus.SUBMITTED, "625.00");
        saveShipmentFee(tenantA, date.atTime(10, 0), ShipmentRequestStatus.CANCELLED, "9000.00");
        saveShipmentFee(tenantB, date.atTime(11, 0), ShipmentRequestStatus.DELIVERED, "400.00");

        transactionRepository.flush();
        feeRepository.flush();
        return new Seed(tenantA.company(), tenantA.vault(), tenantB.company(), tenantB.vault());
    }

    private Tenant seedTenant(
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now) {
        Company company = companyRepository.save(Company.builder()
                .code("FR6-C-" + suffix)
                .name("FR-6 Company " + suffix)
                .createdAt(now)
                .build());
        Branch vault = branchRepository.save(Branch.builder()
                .code("FR6-V-" + suffix)
                .company(company)
                .bankCode("FR6BANK")
                .branchType(branchType)
                .name("FR-6 Vault " + suffix)
                .address("Vault Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(true)
                .openingDate(now.toLocalDate())
                .createdAt(now)
                .build());
        Branch cashier = branchRepository.save(Branch.builder()
                .code("FR6-P-" + suffix)
                .company(company)
                .bankCode("FR6BANK")
                .branchType(branchType)
                .name("FR-6 Cashier " + suffix)
                .address("Cashier Street 1")
                .city("Budapest")
                .zipCode("1001")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .openingDate(now.toLocalDate())
                .createdAt(now)
                .build());
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(vault)
                .code("FR6-W-" + suffix)
                .name("FR-6 Worker " + suffix)
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        return new Tenant(company, vault, cashier, worker);
    }

    private Transaction transaction(
            Tenant tenant,
            Currency currency,
            LocalDate date,
            String receiptNumber,
            String handlingFee) {
        return Transaction.builder()
                .company(tenant.company())
                .branch(tenant.vault())
                .worker(tenant.worker())
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
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
    }

    private void saveShipmentFee(
            Tenant tenant,
            LocalDateTime createdAt,
            ShipmentRequestStatus status,
            String hufAmount) {
        ShipmentRequest shipment = shipmentRequestRepository.save(ShipmentRequest.builder()
                .requestNumber("FR6-S-" + UUID.randomUUID())
                .companyId(tenant.company().getId())
                .fromBranchId(tenant.cashier().getId())
                .toBranchId(tenant.vault().getId())
                .requestedById(tenant.worker().getId())
                .status(status)
                .requestDate(createdAt.toLocalDate())
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("FR6-" + UUID.randomUUID())
                .createdAt(createdAt)
                .build());
        feeRepository.save(ShipmentHandlingFee.builder()
                .companyId(tenant.company().getId())
                .shipmentRequestId(shipment.getId())
                .sourceBranchId(tenant.cashier().getId())
                .hufAmount(new BigDecimal(hufAmount))
                .calculatedFee(BigDecimal.ONE)
                .status(status)
                .createdAt(createdAt)
                .build());
    }

    private record Tenant(Company company, Branch vault, Branch cashier, Worker worker) {}

    private record Seed(Company companyA, Branch vaultA, Company companyB, Branch vaultB) {}
}
