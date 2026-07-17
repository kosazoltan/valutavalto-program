package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;

/**
 * HOLDOUT H2 (a coder NEM látta) — a KK fee-approve négy-szem elve + az ACCESS_DENIED audit
 * PERZISZTENCIÁJA a dobott kivétel rollbackje ELLENÉRE, VALÓS PostgreSQL-en.
 *
 * <p>A terv unit-tesztjei mockolt {@code auditLogService}-szel csak a HÍVÁST bizonyítják. Éles PG-n
 * a REQUIRES_NEW hiánya (pl. ha a guard sima {@code log}-ot hívna) azt jelentené, hogy a
 * megtagadási security-trail a 403 rollbackjével EGYÜTT elveszik. Ez a próba a VALÓDI Spring
 * bean-láncon + valós {@code audit_log} táblán bizonyít.
 *
 * <p>A seed-minta a {@code ShipmentHandlingFeeIsolationPostgresIT}-ből származik (FLYWAY enabled).
 */
@Testcontainers
@EnableJpaAuditing
@Import({
        ShipmentHandlingFeeService.class,
        ShipmentService.class,
        HandlingFeeService.class,
        TransferSerialSequenceService.class,
        ShipmentStockBookingService.class,
        ShipmentHandlingFeeSyncService.class,
        SystemParameterService.class,
        DiscountThresholdService.class,
        AuditLogService.class
})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class ShipmentFeeApproveFourEyesPostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void pg(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private ShipmentService shipmentService;
    @Autowired private ShipmentHandlingFeeRepository feeRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private HandlingFeeBracketRepository bracketRepository;
    @Autowired private SystemParameterRepository systemParameterRepository;
    @Autowired private TransactionTemplate txTemplate;
    @Autowired private JdbcTemplate jdbc;

    @MockitoBean private ExchangeRateService exchangeRateService;
    @MockitoBean private AccessScopeService accessScopeService;

    private Company companyA;
    private Branch vaultBranchA;
    private Branch cashierBranchA;
    private Worker requesterW1;   // a rögzítő
    private Worker approverW2;    // független jóváhagyó

    @BeforeEach
    void seed() {
        txTemplate.executeWithoutResult(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

            companyA = companyRepository.save(Company.builder()
                    .code("FE-" + suffix).name("FourEyes Company A").createdAt(now).build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code("BT-" + suffix).name("FE Branch Type").createdAt(now).build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY").code("CO-" + suffix).name("Hungary").createdAt(now).build());
            Dictionary statusDict = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS").code("BS-" + suffix).name("Active").createdAt(now).build());

            vaultBranchA = branchRepository.save(Branch.builder()
                    .code("VA-" + suffix).company(companyA).bankCode("FEBANK").branchType(branchType)
                    .name("Vault Branch A").address("Vault Street 1").city("Budapest").zipCode("1000")
                    .country(country).branchStatus(statusDict).isVault(true)
                    .openingDate(LocalDate.now()).createdAt(now).build());

            cashierBranchA = branchRepository.save(Branch.builder()
                    .code("CA-" + suffix).company(companyA).bankCode("FEBANK").branchType(branchType)
                    .name("Cashier Branch A").address("Cashier Street 1").city("Budapest").zipCode("1001")
                    .country(country).branchStatus(statusDict).isVault(false)
                    .openingDate(LocalDate.now()).createdAt(now).build());

            requesterW1 = workerRepository.save(Worker.builder()
                    .company(companyA).branch(cashierBranchA).code("W1-" + suffix).name("FE Requester")
                    .passwordHash("$2a$10$test").role(WorkerRole.CASHIER).active(true).createdAt(now).build());
            approverW2 = workerRepository.save(Worker.builder()
                    .company(companyA).branch(vaultBranchA).code("W2-" + suffix).name("FE Approver")
                    .passwordHash("$2a$10$test").role(WorkerRole.SUPERVISOR).active(true).createdAt(now).build());

            currencyRepository.findByCode("HUF").orElseGet(() ->
                    currencyRepository.saveAndFlush(Currency.builder()
                            .code("HUF").name("Forint").symbol("Ft").decimalPlaces(0)
                            .active(true).displayOrder(1).createdAt(now).build()));

            systemParameterRepository.saveAndFlush(SystemParameter.builder()
                    .parameterKey("HANDLING_FEE_TYPE").companyId(companyA.getId())
                    .parameterValue("BRACKET").parameterType("STRING").category("FEE")
                    .description("Handling fee type for company A").isActive(true).build());

            bracketRepository.saveAndFlush(HandlingFeeBracket.builder()
                    .company(companyA).bracketOrder(1).upperLimit(new BigDecimal("1000000"))
                    .feeAmount(new BigDecimal("2000")).active(true).build());
        });
    }

    /**
     * SUBMITTED KK fee-shipment + fee-sor KÖZVETLEN repo-seed-je (W1 = requestedById), a testvér
     * {@code ShipmentHandlingFeeIsolationPostgresIT} helper-mintájával. Szándékosan NEM a valódi
     * create()+submit() úton megy: a submit() stock-booking (currency_stock/cash_balance fedezet +
     * pesszimista lock) machinériája nem tárgya ennek a holdoutnak (azt a submit-tesztek fedik), és
     * friss PG-n fedezet nélkül fail-closed elakadna. A holdout load-bearing állítása kizárólag az
     * approve() négy-szem guard + az ACCESS_DENIED audit rollback-túlélése — ehhez egy SUBMITTED
     * fee-shipment kell, a hozzá vezető úttól függetlenül.
     */
    private UUID seedSubmittedFeeShipmentByW1() {
        return txTemplate.execute(status -> {
            ShipmentRequest sr = shipmentRequestRepository.saveAndFlush(ShipmentRequest.builder()
                    .requestNumber("KK-H2-" + System.nanoTime())
                    .companyId(companyA.getId())
                    .serialPrefix(ShipmentHandlingFeeService.SERIAL_PREFIX_HANDLING_FEE)
                    .serialNumber(System.nanoTime())
                    .fromBranchId(cashierBranchA.getId())
                    .toBranchId(vaultBranchA.getId())
                    .transferType("BRANCH_TO_VAULT")
                    .requestedById(requesterW1.getId())
                    .status(ShipmentRequestStatus.SUBMITTED)
                    .requestDate(LocalDate.now())
                    .carrierName("Brink's Hungary Kft.")
                    .sealNumber("H2-" + System.nanoTime())
                    .build());
            feeRepository.saveAndFlush(ShipmentHandlingFee.builder()
                    .companyId(companyA.getId())
                    .shipmentRequestId(sr.getId())
                    .sourceBranchId(cashierBranchA.getId())
                    .hufAmount(new BigDecimal("125000.00"))
                    .calculatedFee(new BigDecimal("2000.00"))
                    .status(ShipmentRequestStatus.SUBMITTED)
                    .build());
            return sr.getId();
        });
    }

    private long accessDeniedCount(UUID shipmentId, String errorCode) {
        Long n = jdbc.queryForObject(
                "SELECT count(*) FROM audit_log WHERE action = 'ACCESS_DENIED' "
                        + "AND entity_id = ? AND changes LIKE ?",
                Long.class, shipmentId.toString(), "%\"error_code\":\"" + errorCode + "\"%");
        return n == null ? 0 : n;
    }

    private long feeApprovedCount(UUID shipmentId) {
        Long n = jdbc.queryForObject(
                "SELECT count(*) FROM audit_log WHERE action = ? AND changes LIKE ?",
                Long.class, ShipmentHandlingFeeSyncService.ACTION_FEE_APPROVED,
                "%\"shipment_request_id\":\"" + shipmentId + "\"%");
        return n == null ? 0 : n;
    }

    @Test
    @DisplayName("H2: önjóváhagyás 403 + ACCESS_DENIED audit túléli a rollbackot; W2 jóváhagy, idempotens")
    void selfApprovalDeniedAuditSurvivesRollback_thenIndependentApproverSucceeds() {
        UUID shipmentId = seedSubmittedFeeShipmentByW1();

        // (1) W1 (a rögzítő) próbál jóváhagyni — to-branchre állított branchId-vel is → VV-AUTH-003.
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(requesterW1.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(requesterW1.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());

            assertThatThrownBy(() -> shipmentService.approveResponse(shipmentId))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("VV-AUTH-003");
        }

        // Friss tranzakcióból olvasva: a 403 rollbackje ellenére az állapot SUBMITTED, fee approvedAt NULL,
        // ÉS az ACCESS_DENIED VV-AUTH-003 audit-sor LÉTEZIK (= logInNewTransaction túlélte a rollbackot).
        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.SUBMITTED);
        ShipmentHandlingFee feeAfterDeny = feeRepository
                .findByShipmentRequestIdAndCompanyId(shipmentId, companyA.getId()).orElseThrow();
        assertThat(feeAfterDeny.getApprovedAt()).isNull();
        assertThat(accessDeniedCount(shipmentId, "VV-AUTH-003")).isEqualTo(1L);

        // (2) W2 (független jóváhagyó, != rögzítő; vault/to branch) → APPROVED, fee approvedAt kitöltve,
        // PONTOSAN EGY FEE_APPROVED audit-sor.
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(approverW2.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(approverW2.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());

            shipmentService.approveResponse(shipmentId);
        }
        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.APPROVED);
        ShipmentHandlingFee feeAfterApprove = feeRepository
                .findByShipmentRequestIdAndCompanyId(shipmentId, companyA.getId()).orElseThrow();
        assertThat(feeAfterApprove.getApprovedAt()).isNotNull();
        assertThat(feeApprovedCount(shipmentId)).isEqualTo(1L);

        // (3) Ismételt approve W2-vel → státusz-validációs hiba, és TOVÁBBRA IS pontosan egy FEE_APPROVED sor.
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(approverW2.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(approverW2.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());

            assertThatThrownBy(() -> shipmentService.approveResponse(shipmentId))
                    .isInstanceOf(RuntimeException.class);
        }
        assertThat(feeApprovedCount(shipmentId)).isEqualTo(1L);
    }
}
