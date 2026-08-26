package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateResponseDto;
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
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.DiscountThresholdService;
import hu.puzzleir.valuta.service.ExchangeRateService;
import hu.puzzleir.valuta.service.HandlingFeeService;
import hu.puzzleir.valuta.service.HufDaybookSequenceService;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeService;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeSyncService;
import hu.puzzleir.valuta.service.ShipmentService;
import hu.puzzleir.valuta.service.ShipmentStockBookingService;
import hu.puzzleir.valuta.service.ShipmentVatSupplySyncService;
import hu.puzzleir.valuta.service.SystemParameterService;
import hu.puzzleir.valuta.service.TransferSerialSequenceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.test.annotation.DirtiesContext;
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
 * FKH-018 HOLDOUT — real-PG integrációs teszt.
 *
 * <p>Független bizonyítás, hogy a shipment_handling_fee funkció:
 * <ol>
 *   <li>Teszt 1 — calculated_fee BITRE egyenlő a meglévő HandlingFeeService.calculateHandlingFee
 *       kimenetével (nem duplikált díjlogika) + kerekítés-ellenpróba (125003 → 125005).</li>
 *   <li>Teszt 2 — company_id-izoláció: A talál, B üres, null üres.</li>
 *   <li>Teszt 3 — ShipmentRequest normál és lockolt lookup közvetlen company_id-izolációja.</li>
 *   <li>Teszt 4 — V357 DDL-invariánsok valós PG-n (unique index, FK, CHECK).</li>
 * </ol>
 *
 * <p><b>FLYWAY enabled</b> (nem create-drop) — a cél épp a V357 DDL valós PG-n való bizonyítása.
 */
@Testcontainers
@EnableJpaAuditing
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@Import({
        ShipmentHandlingFeeService.class,
        ShipmentService.class,
        HandlingFeeService.class,
        HufDaybookSequenceService.class,
        TransferSerialSequenceService.class,
        ShipmentStockBookingService.class,
        ShipmentHandlingFeeSyncService.class,
        // FK-096 WU-5 + meglévő hiba javítása: a ShipmentService az FKH-039 (#1647) óta
        // függ a ShipmentVatSupplySyncService-től, ami hiányzott az @Import listából —
        // a kontextus már a base commiton sem töltött be.
        ShipmentVatSupplySyncService.class,
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
class ShipmentHandlingFeeIsolationPostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void pg(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private ShipmentHandlingFeeRepository feeRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private ShipmentHandlingFeeService feeService;
    @Autowired private HandlingFeeService handlingFeeService;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private HandlingFeeBracketRepository bracketRepository;
    @Autowired private BranchHandlingFeeConfigRepository branchConfigRepository;
    @Autowired private SystemParameterRepository systemParameterRepository;
    @Autowired private TransactionTemplate txTemplate;

    @MockitoBean private ExchangeRateService exchangeRateService;
    @MockitoBean private AccessScopeService accessScopeService;

    // Seed holders
    private Company companyA;
    private Company companyB;
    private Branch vaultBranchA;
    private Branch cashierBranchA;
    private Branch branchB;
    private Worker workerA;
    private Currency huf;

    @BeforeEach
    void seed() {
        txTemplate.executeWithoutResult(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

            // --- Company A ---
            companyA = companyRepository.save(Company.builder()
                    .code("SA-" + suffix)
                    .name("ShipmentHandlingFee Company A")
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE")
                    .code("BT-" + suffix)
                    .name("SHF Branch Type")
                    .createdAt(now)
                    .build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY")
                    .code("CO-" + suffix)
                    .name("Hungary")
                    .createdAt(now)
                    .build());
            Dictionary statusDict = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS")
                    .code("BS-" + suffix)
                    .name("Active")
                    .createdAt(now)
                    .build());

            vaultBranchA = branchRepository.save(Branch.builder()
                    .code("VA-" + suffix)
                    .company(companyA)
                    .bankCode("SHFBANK")
                    .branchType(branchType)
                    .name("Vault Branch A")
                    .address("Vault Street 1")
                    .city("Budapest")
                    .zipCode("1000")
                    .country(country)
                    .branchStatus(statusDict)
                    .isVault(true)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());

            cashierBranchA = branchRepository.save(Branch.builder()
                    .code("CA-" + suffix)
                    .company(companyA)
                    .bankCode("SHFBANK")
                    .branchType(branchType)
                    .name("Cashier Branch A")
                    .address("Cashier Street 1")
                    .city("Budapest")
                    .zipCode("1001")
                    .country(country)
                    .branchStatus(statusDict)
                    .isVault(false)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());

            workerA = workerRepository.save(Worker.builder()
                    .company(companyA)
                    .branch(cashierBranchA)
                    .code("W" + suffix)
                    .name("SHF Cashier")
                    .passwordHash("$2a$10$test")
                    .role(WorkerRole.CASHIER)
                    .active(true)
                    .createdAt(now)
                    .build());

            // --- Company B ---
            companyB = companyRepository.save(Company.builder()
                    .code("SB-" + suffix)
                    .name("ShipmentHandlingFee Company B")
                    .createdAt(now)
                    .build());

            branchB = branchRepository.save(Branch.builder()
                    .code("BB-" + suffix)
                    .company(companyB)
                    .bankCode("SHFBANK")
                    .branchType(branchType)
                    .name("Branch B")
                    .address("B Street 1")
                    .city("Debrecen")
                    .zipCode("4000")
                    .country(country)
                    .branchStatus(statusDict)
                    .isVault(false)
                    .openingDate(LocalDate.now())
                    .createdAt(now)
                    .build());

            // --- HUF Currency (Flyway may not seed it) ---
            huf = currencyRepository.findByCode("HUF")
                    .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                            .code("HUF")
                            .name("Forint")
                            .symbol("Ft")
                            .decimalPlaces(0)
                            .active(true)
                            .displayOrder(1)
                            .createdAt(now)
                            .build()));

            // --- HANDLING_FEE_TYPE = BRACKET (company-scoped for A) ---
            systemParameterRepository.saveAndFlush(SystemParameter.builder()
                    .parameterKey("HANDLING_FEE_TYPE")
                    .companyId(companyA.getId())
                    .parameterValue("BRACKET")
                    .parameterType("STRING")
                    .category("FEE")
                    .description("Handling fee type for company A")
                    .isActive(true)
                    .build());

            // --- 2 HandlingFeeBracket for Company A ---
            bracketRepository.saveAndFlush(HandlingFeeBracket.builder()
                    .company(companyA)
                    .bracketOrder(1)
                    .upperLimit(new BigDecimal("100000"))
                    .feeAmount(new BigDecimal("500"))
                    .active(true)
                    .build());
            bracketRepository.saveAndFlush(HandlingFeeBracket.builder()
                    .company(companyA)
                    .bracketOrder(2)
                    .upperLimit(new BigDecimal("1000000"))
                    .feeAmount(new BigDecimal("2000"))
                    .active(true)
                    .build());

            // --- FK-096: LIVE iroda-szintu dijkonfig az A-ceg irodaihoz (a seed-ido V383
            // elott jott letre, ezert a @BeforeEach fixture adja a V383 seed helyett).
            // A bit-egyenlosegi assert tovabbra is a MEGLVO HandlingFeeService kimenetet
            // hasonlitja — a feloldas most iroda-szintu, fail-closed.
            branchConfigRepository.saveAndFlush(hu.puzzleir.valuta.entity.BranchHandlingFeeConfig.builder()
                    .companyId(companyA.getId())
                    .branchId(cashierBranchA.getId())
                    .feeMode(hu.puzzleir.valuta.entity.HandlingFeeType.BRACKET)
                    .status(hu.puzzleir.valuta.entity.FeeConfigStatus.LIVE)
                    .active(true)
                    .createdBy("FKH-018-IT")
                    .createdAt(now)
                    .publishedBy("FKH-018-IT")
                    .publishedAt(now)
                    .build());
            branchConfigRepository.saveAndFlush(hu.puzzleir.valuta.entity.BranchHandlingFeeConfig.builder()
                    .companyId(companyA.getId())
                    .branchId(vaultBranchA.getId())
                    .feeMode(hu.puzzleir.valuta.entity.HandlingFeeType.BRACKET)
                    .status(hu.puzzleir.valuta.entity.FeeConfigStatus.LIVE)
                    .active(true)
                    .createdBy("FKH-018-IT")
                    .createdAt(now)
                    .publishedBy("FKH-018-IT")
                    .publishedAt(now)
                    .build());
        });
    }

    // =========================================================================
    // Teszt 1 — calculated_fee == calculateHandlingFee output (nem duplikált logika)
    // =========================================================================

    @Test
    @DisplayName("Teszt 1: createdFee == HandlingFeeService.calculateHandlingFee bitre + kerekítés-ellenpróba")
    void createdFeeMatchesCalculateHandlingFeeOutput() {
        BigDecimal huf = new BigDecimal("125000");

        // Referencia: a MEGLÉVŐ szolgáltatás kimenete ugyanabban a company-kontextusban.
        // A handlingFeeService.calculateHandlingFee SecurityUtils.getCurrentCompanyId()-t hív
        // (bracket lookup company-szkópolt) — mockolni kell.
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(workerA.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(workerA.getCode());
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(cashierBranchA.getId());

            BigDecimal expected = handlingFeeService.calculateHandlingFee(huf, cashierBranchA.getId());
            assertThat(expected).isGreaterThan(BigDecimal.ZERO); // seed-szanity: a bracket él

            var response = feeService.create(ShipmentHandlingFeeCreateRequest.builder()
                    .fromBranchId(cashierBranchA.getId())
                    .toBranchId(vaultBranchA.getId())
                    .hufAmount(huf)
                    .carrierName("Brink's Hungary Kft.")
                    .sealNumber("HOLD-01-1")
                    .build());

            UUID shipmentId = response.getShipment().getId();

            ShipmentHandlingFee stored = feeRepository
                    .findByShipmentRequestIdAndCompanyId(shipmentId, companyA.getId())
                    .orElseThrow();

            // A perzisztált díj BITRE egyezik a meglévő szolgáltatás kimenetével:
            assertThat(stored.getCalculatedFee()).isEqualByComparingTo(expected);
            assertThat(stored.getHufAmount()).isEqualByComparingTo(huf); // 125000 5-tel osztható → változatlan
            assertThat(stored.getCompanyId()).isEqualTo(companyA.getId());
            assertThat(stored.getSourceBranchId()).isEqualTo(cashierBranchA.getId());
            assertThat(stored.getStatus()).isEqualTo(ShipmentRequestStatus.DRAFT);

            // --- Kiegészítő anti-duplikáció assert (kerekítés-út) ---
            // hufAmount=125003-mal hívva a tárolt hufAmount 125005 ÉS a calculatedFee ==
            // handlingFeeService.calculateHandlingFee(new BigDecimal("125005"))
            BigDecimal hufRounded = new BigDecimal("125003");
            BigDecimal expectedRounded = handlingFeeService.calculateHandlingFee(new BigDecimal("125005"), cashierBranchA.getId());

            var response2 = feeService.create(ShipmentHandlingFeeCreateRequest.builder()
                    .fromBranchId(cashierBranchA.getId())
                    .toBranchId(vaultBranchA.getId())
                    .hufAmount(hufRounded)
                    .carrierName("Brink's Hungary Kft.")
                    .sealNumber("HOLD-01-2")
                    .build());

            UUID shipmentId2 = response2.getShipment().getId();
            ShipmentHandlingFee stored2 = feeRepository
                    .findByShipmentRequestIdAndCompanyId(shipmentId2, companyA.getId())
                    .orElseThrow();

            assertThat(stored2.getHufAmount()).isEqualByComparingTo(new BigDecimal("125005"));
            assertThat(stored2.getCalculatedFee()).isEqualByComparingTo(expectedRounded);
        }
    }

    // =========================================================================
    // Teszt 2 — company_id-izoláció valós PG-n
    // =========================================================================

    @Test
    @DisplayName("Teszt 2: fee row company-isolated — A talál, B üres, null üres")
    void feeRowIsCompanyIsolated() {
        UUID shipmentId = createShipmentRequestAndFeeForCompanyA();

        // 1) A saját companyId-val megtalálja:
        assertThat(feeRepository.findByShipmentRequestIdAndCompanyId(shipmentId, companyA.getId()))
                .isPresent();
        // 2) Company B companyId-jával UGYANAZ a shipmentRequestId ÜRES — izoláció:
        assertThat(feeRepository.findByShipmentRequestIdAndCompanyId(shipmentId, companyB.getId()))
                .isEmpty();
        // 3) JPQL-csapda ellenpróba: null companyId sem ad vissza sort
        assertThat(feeRepository.findByShipmentRequestIdAndCompanyId(shipmentId, null))
                .isEmpty();
    }

    @Test
    @DisplayName("ShipmentRequest read + FOR UPDATE az authoritative company_id alapján tenant-izolált")
    void shipmentRequestNormalAndLockedLookupsAreCompanyIsolated() {
        UUID shipmentId = createShipmentRequestAndFeeForCompanyA();

        assertThat(shipmentRequestRepository.findByIdAndCompanyId(shipmentId, companyA.getId()))
                .isPresent();
        assertThat(shipmentRequestRepository.findByIdAndCompanyId(shipmentId, companyB.getId()))
                .isEmpty();
        assertThat(shipmentRequestRepository.findByIdAndCompanyId(UUID.randomUUID(), companyA.getId()))
                .isEmpty();

        txTemplate.executeWithoutResult(status -> {
            assertThat(shipmentRequestRepository.findByIdAndCompanyIdForUpdate(shipmentId, companyA.getId()))
                    .isPresent();
            assertThat(shipmentRequestRepository.findByIdAndCompanyIdForUpdate(shipmentId, companyB.getId()))
                    .isEmpty();
        });
    }

    // =========================================================================
    // Teszt 4 — DDL-invariánsok valós PG-n (Flyway V357 bizonyítás)
    // =========================================================================

    @Test
    @DisplayName("Teszt 4: V357 DDL — unique index + FK + CHECK enforced on real Postgres")
    void schemaConstraintsEnforcedOnRealPostgres() {
        UUID shipmentId = createShipmentRequestAndFeeForCompanyA();

        // (a) unique index: második fee sor ugyanarra a shipmentre → DataIntegrityViolation
        assertThatThrownBy(() -> txTemplate.executeWithoutResult(tx ->
                feeRepository.saveAndFlush(validFeeBuilder(shipmentId).build())))
                .isInstanceOf(DataIntegrityViolationException.class);

        // (b) FK: nem létező shipment_request_id → DataIntegrityViolation
        assertThatThrownBy(() -> txTemplate.executeWithoutResult(tx ->
                feeRepository.saveAndFlush(validFeeBuilder(UUID.randomUUID()).build())))
                .isInstanceOf(DataIntegrityViolationException.class);

        // (c) CHECK huf_amount > 0: nulla összeg DB-szinten is elutasítva
        assertThatThrownBy(() -> txTemplate.executeWithoutResult(tx ->
                feeRepository.saveAndFlush(validFeeBuilder(freshShipmentId())
                        .hufAmount(BigDecimal.ZERO).build())))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    /**
     * Direkt repo-save-vel létrehoz egy Company A-hoz tartozó ShipmentRequest-et
     * (FK miatt kötelező szülő) és egy hozzá tartozó ShipmentHandlingFee-t.
     * Visszaadja a shipmentRequestId-t.
     */
    private UUID createShipmentRequestAndFeeForCompanyA() {
        return txTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();

            // ShipmentRequest (szülő, FK miatt kötelező)
            ShipmentRequest sr = shipmentRequestRepository.saveAndFlush(ShipmentRequest.builder()
                    .requestNumber("SHF-IT-" + System.nanoTime())
                    .companyId(companyA.getId())
                    .serialPrefix("FF")
                    .serialNumber(1L)
                    .fromBranchId(cashierBranchA.getId())
                    .toBranchId(vaultBranchA.getId())
                    .transferType("BRANCH_TO_VAULT")
                    .requestedById(workerA.getId())
                    .status(ShipmentRequestStatus.DRAFT)
                    .requestDate(LocalDate.now())
                    .carrierName("Brink's Hungary Kft.")
                    .sealNumber("SEAL-" + System.nanoTime())
                    .build());

            // ShipmentHandlingFee (gyermek)
            feeRepository.saveAndFlush(ShipmentHandlingFee.builder()
                    .companyId(companyA.getId())
                    .shipmentRequestId(sr.getId())
                    .sourceBranchId(cashierBranchA.getId())
                    .hufAmount(new BigDecimal("125000.00"))
                    .calculatedFee(new BigDecimal("2000.00"))
                    .status(ShipmentRequestStatus.DRAFT)
                    .build());

            return sr.getId();
        });
    }

    /**
     * Új ShipmentRequest-et ment (minden kötelező mezővel), visszaadja az ID-ját.
     * A Teszt 3 (c) CHECK-es esethez kell, ahol egy külön shipment-re mentünk fee-t.
     */
    private UUID freshShipmentId() {
        return txTemplate.execute(status -> {
            ShipmentRequest sr = shipmentRequestRepository.saveAndFlush(ShipmentRequest.builder()
                    .requestNumber("SHF-IT-FRESH-" + System.nanoTime())
                    .companyId(companyA.getId())
                    .serialPrefix("FF")
                    .serialNumber(System.nanoTime())
                    .fromBranchId(cashierBranchA.getId())
                    .toBranchId(vaultBranchA.getId())
                    .transferType("BRANCH_TO_VAULT")
                    .requestedById(workerA.getId())
                    .status(ShipmentRequestStatus.DRAFT)
                    .requestDate(LocalDate.now())
                    .carrierName("Brink's Hungary Kft.")
                    .sealNumber("SEAL-FRESH-" + System.nanoTime())
                    .build());
            return sr.getId();
        });
    }

    /**
     * Valid ShipmentHandlingFee builder — egy (még nem létező) shipmentRequestId-hez.
     * A Teszt 3-hoz: minden mező érvényes, csak a constraint-et teszteljük.
     */
    private ShipmentHandlingFee.ShipmentHandlingFeeBuilder validFeeBuilder(UUID shipmentId) {
        return ShipmentHandlingFee.builder()
                .companyId(companyA.getId())
                .shipmentRequestId(shipmentId)
                .sourceBranchId(cashierBranchA.getId())
                .hufAmount(new BigDecimal("125000.00"))
                .calculatedFee(new BigDecimal("2000.00"))
                .status(ShipmentRequestStatus.DRAFT);
    }
}
