package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
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
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * FKH-018 valós PostgreSQL holdout: SUBMITTED KK közvetlen átvétel, konkurens dupla-deliver
 * pontosan-egyszer készlet/audit hatása, valamint a deprecated approve sender-only guardjának
 * rollbackot túlélő ACCESS_DENIED auditja. Flyway enabled, valódi Spring bean-lánccal.
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
    @Autowired private VaultTerritoryRepository vaultTerritoryRepository;
    @Autowired private TransactionTemplate txTemplate;
    @Autowired private JdbcTemplate jdbc;
    @PersistenceContext private EntityManager entityManager;

    @MockitoBean private ExchangeRateService exchangeRateService;
    @MockitoBean private AccessScopeService accessScopeService;

    private Company companyA;
    private Branch vaultBranchA;
    private Branch cashierBranchA;
    private Worker requesterW1;   // a rögzítő/küldő
    private Worker approverW2;    // a célfiók átvevője
    private Currency huf;

    @BeforeEach
    void seed() {
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
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

            VaultTerritory vaultTerritory = vaultTerritoryRepository.save(VaultTerritory.builder()
                    .company(companyA)
                    .name("FE Territory " + suffix)
                    .baseCapital(BigDecimal.ZERO)
                    .active(true)
                    .build());

            vaultBranchA = branchRepository.save(Branch.builder()
                    .code("VA-" + suffix).company(companyA).bankCode("FEBANK").branchType(branchType)
                    .name("Vault Branch A").address("Vault Street 1").city("Budapest").zipCode("1000")
                    .country(country).branchStatus(statusDict).isVault(true)
                    .vaultTerritoryId(vaultTerritory.getId())
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

            huf = currencyRepository.findByCode("HUF").orElseGet(() ->
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

    /** SUBMITTED KK + fee-sor közvetlen repo-seedje a transition/concurrency holdoutokhoz. */
    private UUID seedSubmittedFeeShipmentByW1() {
        return txTemplate.execute(status -> {
            ShipmentRequest sr = ShipmentRequest.builder()
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
                    .build();
            sr.addItem(ShipmentRequestItem.builder()
                    .currencyId(huf.getId())
                    .requestedAmount(new BigDecimal("125000.00"))
                    .appliedRate(BigDecimal.ONE)
                    .hufValue(new BigDecimal("125000.00"))
                    .build());
            sr = shipmentRequestRepository.saveAndFlush(sr);
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

    private long auditActionCount(UUID shipmentId, String action) {
        Long n = jdbc.queryForObject(
                "SELECT count(*) FROM audit_log WHERE action = ? AND entity_id = ?",
                Long.class, action, shipmentId.toString());
        return n == null ? 0 : n;
    }

    private void makeShipmentStale(UUID shipmentId) {
        txTemplate.executeWithoutResult(status -> {
            int updated = jdbc.update(
                    "UPDATE shipment_request SET created_at = created_at - INTERVAL '49 hours' WHERE id = ?",
                    shipmentId);
            assertThat(updated).isEqualTo(1);
            entityManager.clear();
        });
        entityManager.getEntityManagerFactory().getCache().evict(ShipmentRequest.class, shipmentId);
        LocalDateTime persistedCreatedAt = jdbc.queryForObject(
                "SELECT created_at FROM shipment_request WHERE id = ?", LocalDateTime.class, shipmentId);
        assertThat(persistedCreatedAt).isBefore(LocalDateTime.now().minusHours(48));
    }

    private long receiverStockRowCount() {
        Long count = jdbc.queryForObject(
                "SELECT count(*) FROM currency_stock WHERE company_id = ? AND entity_type = 'VAULT' "
                        + "AND entity_id = ? AND currency_code = 'HUF'",
                Long.class, companyA.getId(), String.valueOf(vaultBranchA.getVaultTerritoryId()));
        return count == null ? 0 : count;
    }

    private void assertServerReportsShipmentStale(UUID shipmentId) {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(approverW2.getId());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());
            ShipmentRequestResponseDto response = shipmentService.findByIdResponse(shipmentId);
            assertThat(response.getCreatedAt()).isBefore(LocalDateTime.now().minusHours(48));
            assertThat(response.getStaleThresholdHours()).isEqualTo(ShipmentService.DEFAULT_STALE_HOURS);
            assertThat(response.getStaleForDelivery()).isTrue();
        }
    }

    @Test
    @DisplayName("FKH-018: SUBMITTED KK tétel közvetlenül, négy-szem nélkül kézbesíthető")
    void submittedFeeShipmentDirectDeliverSucceedsWithoutFourEyesApproval() {
        UUID shipmentId = seedSubmittedFeeShipmentByW1();

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(approverW2.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(approverW2.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());

            shipmentService.deliverResponse(shipmentId);
        }

        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.DELIVERED);
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_DIRECT_DELIVER)).isEqualTo(1L);
    }

    @Test
    @DisplayName("FKH-018 holdout: két valós PG-tranzakció konkurens deliverje pontosan egyszer könyvel")
    void concurrentDirectDeliverBooksStockAndAuditExactlyOnce() throws Exception {
        UUID shipmentId = seedSubmittedFeeShipmentByW1();
        CyclicBarrier start = new CyclicBarrier(2);
        ExecutorService executor = Executors.newFixedThreadPool(2);

        try {
            Future<Throwable> first = executor.submit(() -> attemptConcurrentDeliver(shipmentId, start));
            Future<Throwable> second = executor.submit(() -> attemptConcurrentDeliver(shipmentId, start));
            List<Throwable> outcomes = Arrays.asList(
                    first.get(60, TimeUnit.SECONDS),
                    second.get(60, TimeUnit.SECONDS));

            assertThat(outcomes).filteredOn(outcome -> outcome == null).hasSize(1);
            assertThat(outcomes).filteredOn(ConflictException.class::isInstance).hasSize(1);
        } finally {
            executor.shutdownNow();
            assertThat(executor.awaitTermination(10, TimeUnit.SECONDS)).isTrue();
        }

        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.DELIVERED);
        assertThat(auditActionCount(shipmentId, ShipmentStockBookingService.ACTION_STOCK_IN))
                .isEqualTo(1L);
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_DIRECT_DELIVER)).isEqualTo(1L);
        assertThat(jdbc.queryForObject(
                "SELECT quantity FROM currency_stock WHERE company_id = ? AND entity_type = 'VAULT' "
                        + "AND entity_id = ? AND currency_code = 'HUF'",
                BigDecimal.class, companyA.getId(), String.valueOf(vaultBranchA.getVaultTerritoryId())))
                .isEqualByComparingTo("125000.00");
    }

    @Test
    @DisplayName("FKH-023 holdout: két confirmed-stale PG-tranzakcióból csak egy könyvel és auditál")
    void concurrentConfirmedStaleDeliverBooksStockAndConfirmationAuditExactlyOnce() throws Exception {
        UUID shipmentId = seedSubmittedFeeShipmentByW1();
        makeShipmentStale(shipmentId);
        assertServerReportsShipmentStale(shipmentId);
        CyclicBarrier start = new CyclicBarrier(2);
        ExecutorService executor = Executors.newFixedThreadPool(2);

        try {
            Future<Throwable> first = executor.submit(() -> attemptConcurrentDeliver(shipmentId, start, true));
            Future<Throwable> second = executor.submit(() -> attemptConcurrentDeliver(shipmentId, start, true));
            List<Throwable> outcomes = Arrays.asList(
                    first.get(60, TimeUnit.SECONDS),
                    second.get(60, TimeUnit.SECONDS));

            assertThat(outcomes).filteredOn(outcome -> outcome == null).hasSize(1);
            assertThat(outcomes).filteredOn(ConflictException.class::isInstance).hasSize(1);
        } finally {
            executor.shutdownNow();
            assertThat(executor.awaitTermination(10, TimeUnit.SECONDS)).isTrue();
        }

        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.DELIVERED);
        assertThat(auditActionCount(shipmentId, ShipmentStockBookingService.ACTION_STOCK_IN)).isEqualTo(1L);
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_DIRECT_DELIVER)).isEqualTo(1L);
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_DELIVER_CONFIRMED_STALE)).isEqualTo(1L);
        assertThat(jdbc.queryForObject(
                "SELECT quantity FROM currency_stock WHERE company_id = ? AND entity_type = 'VAULT' "
                        + "AND entity_id = ? AND currency_code = 'HUF'",
                BigDecimal.class, companyA.getId(), String.valueOf(vaultBranchA.getVaultTerritoryId())))
                .isEqualByComparingTo("125000.00");
    }

    @Test
    @DisplayName("FKH-023 holdout: külső valós tranzakció rollbackje együtt törli a confirmed-stale mutációkat")
    void confirmedStaleDeliveryRollsBackStatusStockAndAuditTogether() {
        UUID shipmentId = seedSubmittedFeeShipmentByW1();
        makeShipmentStale(shipmentId);
        assertServerReportsShipmentStale(shipmentId);
        assertThat(receiverStockRowCount()).isZero();

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(approverW2.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(approverW2.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());

            assertThatThrownBy(() -> txTemplate.executeWithoutResult(status -> {
                shipmentService.deliverResponse(shipmentId, true);
                entityManager.flush();
                assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_DELIVER_CONFIRMED_STALE))
                        .isEqualTo(1L);
                throw new ForcedRollbackException();
            })).isInstanceOf(ForcedRollbackException.class);
        }

        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.SUBMITTED);
        assertThat(receiverStockRowCount()).isZero();
        assertThat(auditActionCount(shipmentId, ShipmentStockBookingService.ACTION_STOCK_IN)).isZero();
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_DIRECT_DELIVER)).isZero();
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_DELIVER_CONFIRMED_STALE)).isZero();
    }

    private Throwable attemptConcurrentDeliver(UUID shipmentId, CyclicBarrier start) {
        return attemptConcurrentDeliver(shipmentId, start, false);
    }

    private Throwable attemptConcurrentDeliver(UUID shipmentId, CyclicBarrier start, boolean confirmedStale) {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(approverW2.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(approverW2.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());
            start.await(10, TimeUnit.SECONDS);
            shipmentService.deliverResponse(shipmentId, confirmedStale);
            return null;
        } catch (Throwable failure) {
            return failure;
        }
    }

    private static final class ForcedRollbackException extends RuntimeException {
    }

    @Test
    @DisplayName("FKH-018: deprecated KK approve sender-only; tiltási audit túléli a rollbackot")
    void deprecatedApproveUsesSenderGuardAndPersistsDeniedAudit() {
        UUID shipmentId = seedSubmittedFeeShipmentByW1();

        // A célfiók régi kliensének approve-kísérlete tiltott, a security trail megmarad.
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(approverW2.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(approverW2.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(vaultBranchA.getId());

            assertThatThrownBy(() -> shipmentService.approveResponse(shipmentId))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("VV-AUTH-002");
        }
        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.SUBMITTED);
        assertThat(accessDeniedCount(shipmentId, "VV-AUTH-002")).isEqualTo(1L);

        // A küldő branch régi kliense kompatibilisen továbbra is APPROVED-ra válthat.
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(requesterW1.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(requesterW1.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(cashierBranchA.getId());

            shipmentService.approveResponse(shipmentId);
        }
        assertThat(shipmentRequestRepository.findById(shipmentId).orElseThrow().getStatus())
                .isEqualTo(ShipmentRequestStatus.APPROVED);
        ShipmentHandlingFee feeAfterApprove = feeRepository
                .findByShipmentRequestIdAndCompanyId(shipmentId, companyA.getId()).orElseThrow();
        assertThat(feeAfterApprove.getApprovedAt()).isNotNull();
        assertThat(feeApprovedCount(shipmentId)).isEqualTo(1L);
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_APPROVE_DEPRECATED)).isEqualTo(1L);

        // Ismételt approve → státusz-validációs hiba, nincs második audit/sync.
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(requesterW1.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(requesterW1.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(cashierBranchA.getId());

            assertThatThrownBy(() -> shipmentService.approveResponse(shipmentId))
                    .isInstanceOf(RuntimeException.class);
        }
        assertThat(feeApprovedCount(shipmentId)).isEqualTo(1L);
        assertThat(auditActionCount(shipmentId, ShipmentService.ACTION_APPROVE_DEPRECATED)).isEqualTo(1L);
    }
}
