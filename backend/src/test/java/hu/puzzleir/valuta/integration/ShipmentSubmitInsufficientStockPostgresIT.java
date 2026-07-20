package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.ExchangeRateService;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeSyncService;
import hu.puzzleir.valuta.service.ShipmentService;
import hu.puzzleir.valuta.service.ShipmentStockBookingService;
import hu.puzzleir.valuta.service.TransferSerialSequenceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;

/**
 * FKH-006 valós PostgreSQL holdout: az elégtelen készlet auditja nem várhat a saját,
 * felfüggesztett külső tranzakciója által zárolt audit hash-lánc végére.
 */
@Testcontainers
@EnableJpaAuditing
@Import({
        ShipmentService.class,
        ShipmentStockBookingService.class,
        AuditLogService.class
})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.datasource.hikari.connection-init-sql=SET lock_timeout = '9s'"
        })
class ShipmentSubmitInsufficientStockPostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void pg(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private ShipmentService shipmentService;
    @Autowired private AuditLogService auditLogService;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private CashBalanceRepository cashBalanceRepository;
    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private TransactionTemplate txTemplate;
    @Autowired private JdbcTemplate jdbc;

    @MockitoBean private ExchangeRateService exchangeRateService;
    @MockitoBean private TransferSerialSequenceService transferSerialSequenceService;
    @MockitoBean private ShipmentHandlingFeeSyncService handlingFeeSyncService;
    @MockitoBean private AccessScopeService accessScopeService;

    private Company company;
    private Branch fromBranch;
    private Branch toBranch;
    private Currency huf;
    private Currency eur;

    @BeforeEach
    void seedTenantAndBranches() {
        txTemplate.executeWithoutResult(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

            company = companyRepository.save(Company.builder()
                    .code("SD-" + suffix)
                    .name("Shipment deadlock company " + suffix)
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code("BT-" + suffix)
                    .name("Shipment deadlock branch type").createdAt(now).build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY").code("CO-" + suffix)
                    .name("Hungary").createdAt(now).build());
            Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS").code("BS-" + suffix)
                    .name("Active").createdAt(now).build());

            fromBranch = branchRepository.save(Branch.builder()
                    .code("SF-" + suffix).company(company).bankCode("SDBANK")
                    .branchType(branchType).name("Shipment source " + suffix)
                    .address("Source Street 1").city("Budapest").zipCode("1000")
                    .country(country).branchStatus(branchStatus).isVault(false)
                    .openingDate(LocalDate.now()).createdAt(now).build());
            toBranch = branchRepository.save(Branch.builder()
                    .code("ST-" + suffix).company(company).bankCode("SDBANK")
                    .branchType(branchType).name("Shipment target " + suffix)
                    .address("Target Street 1").city("Budapest").zipCode("1001")
                    .country(country).branchStatus(branchStatus).isVault(false)
                    .openingDate(LocalDate.now()).createdAt(now).build());

            huf = currencyRepository.findByCode("HUF").orElseThrow();
            eur = currencyRepository.findByCode("EUR").orElseThrow();
        });
    }

    @Test
    @DisplayName("FKH-006: AML-audit után az elégtelen készlet gyors 422, rollback és tartós audit")
    void amlFirstInsufficientStockReturnsWithoutAuditSelfDeadlock() {
        ShipmentRequest shipment = seedDraftShipment(List.of(
                item(huf, "100000.00", "100000.00")));
        seedCashBalance(huf, "0.00");
        String previousTail = appendCommittedTailAndReadHash(shipment.getId());

        BusinessException failure = submitWithinBound(shipment.getId());

        assertBusinessFailure(failure);
        assertShipmentStayedDraft(shipment.getId());
        assertCashBalance(huf, "0.00");
        assertRolledBackSuccessAudits(shipment.getId());
        assertSingleInsufficientAudit(shipment.getId(), previousTail);
    }

    @Test
    @DisplayName("FKH-006: korábbi tételaudit után a későbbi elégtelen tétel sem okoz self-deadlockot")
    void priorItemAuditThenInsufficientStockReturnsWithoutAuditSelfDeadlock() {
        List<Currency> ordered = List.of(huf, eur).stream()
                .sorted(Comparator.comparing(Currency::getId))
                .toList();
        Currency coveredCurrency = ordered.get(0);
        Currency insufficientCurrency = ordered.get(1);
        ShipmentRequest shipment = seedDraftShipment(List.of(
                item(coveredCurrency, "100.00", "1000.00"),
                item(insufficientCurrency, "100.00", "1000.00")));
        seedCashBalance(coveredCurrency, "1000.00");
        seedCashBalance(insufficientCurrency, "50.00");
        String previousTail = appendCommittedTailAndReadHash(shipment.getId());

        BusinessException failure = submitWithinBound(shipment.getId());

        assertBusinessFailure(failure);
        assertShipmentStayedDraft(shipment.getId());
        assertCashBalance(coveredCurrency, "1000.00");
        assertCashBalance(insufficientCurrency, "50.00");
        assertRolledBackSuccessAudits(shipment.getId());
        assertSingleInsufficientAudit(shipment.getId(), previousTail);
    }

    private BusinessException submitWithinBound(UUID shipmentId) {
        ExecutorService executor = Executors.newSingleThreadExecutor(runnable -> {
            Thread thread = new Thread(runnable, "shipment-insufficient-stock-it");
            thread.setDaemon(true);
            return thread;
        });
        CompletableFuture<Throwable> future = CompletableFuture.supplyAsync(() -> {
            TestingAuthenticationToken authentication = new TestingAuthenticationToken(
                    "SD-WORKER", "test", "ROLE_CASHIER");
            authentication.setDetails(new WorkerAuthenticationDetails(
                    42L, company.getId(), fromBranch.getId(), "CASHIER"));
            SecurityContextHolder.getContext().setAuthentication(authentication);
            try {
                shipmentService.submit(shipmentId);
                return null;
            } catch (Throwable failure) {
                return failure;
            } finally {
                SecurityContextHolder.clearContext();
            }
        }, executor);

        try {
            Throwable failure = assertTimeoutPreemptively(
                    Duration.ofSeconds(10), () -> future.get(8, TimeUnit.SECONDS));
            assertThat(failure).isInstanceOf(BusinessException.class);
            return (BusinessException) failure;
        } finally {
            future.cancel(true);
            executor.shutdownNow();
        }
    }

    private ShipmentRequest seedDraftShipment(List<ShipmentRequestItem> items) {
        return txTemplate.execute(status -> {
            ShipmentRequest shipment = ShipmentRequest.builder()
                    .requestNumber("UF-" + System.nanoTime())
                    .companyId(company.getId())
                    .serialPrefix("UF")
                    .serialNumber(System.nanoTime())
                    .fromBranchId(fromBranch.getId())
                    .toBranchId(toBranch.getId())
                    .transferType(ShipmentStockBookingService.TRANSFER_BRANCH_TO_BRANCH)
                    .requestedById(42L)
                    .status(ShipmentRequestStatus.DRAFT)
                    .requestDate(LocalDate.now())
                    .carrierName("Test carrier")
                    .sealNumber("SD-" + System.nanoTime())
                    .build();
            items.forEach(shipment::addItem);
            return shipmentRequestRepository.saveAndFlush(shipment);
        });
    }

    private void seedCashBalance(Currency currency, String balance) {
        txTemplate.executeWithoutResult(status -> cashBalanceRepository.saveAndFlush(CashBalance.builder()
                .company(company)
                .branch(fromBranch)
                .currency(currency)
                .openingBalance(new BigDecimal(balance))
                .currentBalance(new BigDecimal(balance))
                .createdAt(LocalDateTime.now())
                .build()));
    }

    private String appendCommittedTailAndReadHash(UUID shipmentId) {
        auditLogService.logForCompany(
                "TEST_CHAIN_TAIL", "FKH-006 pre-call tail", shipmentId + ":tail", company.getId());
        return jdbc.queryForObject(
                "SELECT entry_hash FROM audit_log WHERE entry_hash IS NOT NULL "
                        + "ORDER BY created_at DESC LIMIT 1",
                String.class);
    }

    private void assertBusinessFailure(BusinessException failure) {
        assertThat(failure.getErrorCode()).isEqualTo(ShipmentStockBookingService.ERR_INSUFFICIENT);
        assertThat(failure.getHttpStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
    }

    private void assertShipmentStayedDraft(UUID shipmentId) {
        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.DRAFT);
    }

    private void assertCashBalance(Currency currency, String expected) {
        assertThat(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(
                        fromBranch.getId(), currency.getId(), company.getId()).orElseThrow().getCurrentBalance())
                .isEqualByComparingTo(expected);
    }

    private void assertRolledBackSuccessAudits(UUID shipmentId) {
        Integer count = jdbc.queryForObject(
                "SELECT count(*) FROM audit_log WHERE entity_id = ? AND action IN (?, ?)",
                Integer.class,
                shipmentId.toString(),
                ShipmentStockBookingService.ACTION_AML_CHECK,
                ShipmentStockBookingService.ACTION_STOCK_OUT);
        assertThat(count).isZero();
    }

    private void assertSingleInsufficientAudit(UUID shipmentId, String previousTail) {
        List<AuditLog> audits = auditLogRepository
                .findByCompanyIdAndEntityIdOrderByCreatedAtDesc(company.getId(), shipmentId.toString())
                .stream()
                .filter(audit -> ShipmentStockBookingService.ACTION_STOCK_INSUFFICIENT.equals(audit.getAction()))
                .toList();
        assertThat(audits).singleElement().satisfies(audit -> {
            assertThat(audit.getCompanyId()).isEqualTo(company.getId());
            assertThat(audit.getEntityType()).isEqualTo("ShipmentRequest");
            assertThat(audit.getEntityId()).isEqualTo(shipmentId.toString());
            assertThat(audit.getUserId()).isEqualTo("42");
            assertThat(audit.getBranchId()).isEqualTo(fromBranch.getId().toString());
            assertThat(audit.getEntryHash()).matches("[0-9a-f]{64}");
            assertThat(audit.getPreviousHash()).isEqualTo(previousTail);
        });
    }

    private static ShipmentRequestItem item(Currency currency, String amount, String hufValue) {
        return ShipmentRequestItem.builder()
                .currencyId(currency.getId())
                .requestedAmount(new BigDecimal(amount))
                .appliedRate(BigDecimal.ONE)
                .hufValue(new BigDecimal(hufValue))
                .build();
    }
}
