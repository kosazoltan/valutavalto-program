package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDraftRequest;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.BranchHandlingFeeConfig;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.BranchHandlingFeeConfigService;
import hu.puzzleir.valuta.service.DiscountThresholdService;
import hu.puzzleir.valuta.service.HandlingFeeService;
import hu.puzzleir.valuta.service.SystemParameterService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
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
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * FK-096 WU-8 — cross-tenant + fail-closed integrációs bizonyítás VALÓS Postgres-sémán
 * (Testcontainers + teljes Flyway-lánc, a ShipmentHandlingFeeIsolationPostgresIT mintájára).
 *
 * <p>Bizonyított állítások:</p>
 * <ol>
 *   <li>A cég iroda-konfigurációja a másik cég számára láthatatlan (companyId-szűrés).</li>
 *   <li>Cross-tenant publish → ResourceNotFoundException (404), sor nem íródik (FR-13).</li>
 *   <li>Deaktivált LIVE sor → calculateHandlingFee ValidationException — a fail-closed
 *       VALÓS sémán működik, nem csak mockokon (FR-5).</li>
 *   <li>FR-2 end-to-end: a V383 seed (újrajátszva) PER_MILLE paraméterrel pontosan a
 *       korábbi cégszintű képlet eredményét adja 3 mintaösszegre.</li>
 *   <li>W3/D17: publish-swap SIKERES meglévő LIVE sor felett a valós parciális egyedi
 *       indexen (deaktiválás → flush → előléptetés); utána pontosan 1 LIVE+aktív sor áll,
 *       a régi archivált (is_active=false) sor megmarad, és az index TOVÁBBRA IS él.</li>
 *   <li>W6/D16: a legacy GET-szintű status-szűrt finder CSAK LIVE sávokat ad, miközben a
 *       status nélküli finder kevert LIVE+DRAFT listát adna.</li>
 * </ol>
 */
@Testcontainers
@EnableJpaAuditing
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
@Import({
        HandlingFeeService.class,
        BranchHandlingFeeConfigService.class,
        SystemParameterService.class
})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class BranchHandlingFeeConfigIsolationPostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void pg(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private HandlingFeeService handlingFeeService;
    @Autowired private BranchHandlingFeeConfigService branchConfigService;
    @Autowired private BranchHandlingFeeConfigRepository configRepository;
    @Autowired private HandlingFeeBracketRepository bracketRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private SystemParameterRepository systemParameterRepository;
    @Autowired private TransactionTemplate txTemplate;

    @MockitoBean private DiscountThresholdService discountThresholdService;
    @MockitoBean private AuditLogService auditLogService;

    // Seed holders
    private Company companyA;
    private Company companyB;
    private Branch branchA;
    private Branch branchB;

    @BeforeEach
    void seed() {
        txTemplate.executeWithoutResult(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

            companyA = companyRepository.save(Company.builder()
                    .code("FA-" + suffix).name("FK-096 IT Company A").createdAt(now).build());
            companyB = companyRepository.save(Company.builder()
                    .code("FB-" + suffix).name("FK-096 IT Company B").createdAt(now).build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code("BT-" + suffix).name("IT Branch Type")
                    .createdAt(now).build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY").code("CO-" + suffix).name("Hungary").createdAt(now).build());
            Dictionary statusDict = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS").code("BS-" + suffix).name("Active").createdAt(now).build());

            branchA = branchRepository.save(branch("BA-" + suffix, companyA, branchType, country, statusDict, now));
            branchB = branchRepository.save(branch("BB-" + suffix, companyB, branchType, country, statusDict, now));

            // HUF (a Flyway nem feltétlenül seed-eli)
            currencyRepository.findByCode("HUF")
                    .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                            .code("HUF").name("Forint").symbol("Ft").decimalPlaces(0)
                            .active(true).displayOrder(1).createdAt(now).build()));
        });
    }

    // =========================================================================
    // 1. Cross-tenant izoláció (olvasás)
    // =========================================================================
    @Test
    @DisplayName("Az A cég konfigurációi a B cég számára láthatatlanok (findByCompanyIdAndActiveTrue)")
    void companyConfigInvisibleToOtherCompany() {
        txTemplate.executeWithoutResult(status -> {
            configRepository.saveAndFlush(BranchHandlingFeeConfig.builder()
                    .companyId(companyA.getId())
                    .branchId(branchA.getId())
                    .feeMode(HandlingFeeType.BRACKET)
                    .status(FeeConfigStatus.LIVE)
                    .active(true)
                    .createdBy("IT").createdAt(LocalDateTime.now())
                    .build());
        });

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            List<BranchHandlingFeeConfig> rowsA = configRepository.findByCompanyIdAndActiveTrue(companyA.getId());
            assertThat(rowsA).hasSize(1);
            assertThat(configRepository.findByCompanyIdAndActiveTrue(companyB.getId()))
                    .as("A B cég nem látja az A cég konfigurációit")
                    .isEmpty();
        }
    }

    // =========================================================================
    // 2. Cross-tenant publish → 404, írás nélkül (FR-13)
    // =========================================================================
    @Test
    @DisplayName("FR-13: A cég kontextusában B cég irodájára publish → ResourceNotFoundException, írás nélkül")
    void publishCrossTenantRejected() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("IT-WORKER");

            assertThatThrownBy(() -> branchConfigService.publish(branchB.getId(), 0L))
                    .isInstanceOf(ResourceNotFoundException.class);

            assertThat(configRepository.findByCompanyIdAndActiveTrue(companyB.getId()))
                    .as("Cross-tenant publish nem írhat sort")
                    .isEmpty();
        }
    }

    // =========================================================================
    // 3. Fail-closed VALÓS sémán (FR-5)
    // =========================================================================
    @Test
    @DisplayName("FR-5: deaktivált LIVE sor → calculateHandlingFee ValidationException (valós séma)")
    void deactivatedLiveRowFailsClosed() {
        txTemplate.executeWithoutResult(status -> {
            BranchHandlingFeeConfig live = configRepository.saveAndFlush(BranchHandlingFeeConfig.builder()
                    .companyId(companyA.getId())
                    .branchId(branchA.getId())
                    .feeMode(HandlingFeeType.PER_MILLE)
                    .perMilleRate(new BigDecimal("3"))
                    .status(FeeConfigStatus.LIVE)
                    .active(true)
                    .createdBy("IT").createdAt(LocalDateTime.now())
                    .build());
            // Az admin "kikapcsolja" a konfigurációt (archiválás)
            live.setActive(false);
            configRepository.saveAndFlush(live);
        });

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());

            assertThatThrownBy(() ->
                    handlingFeeService.calculateHandlingFee(new BigDecimal("100000"), branchA.getId()))
                    .as("Nincs aktív LIVE sor → fail-closed, SOHA nem néma 0 Ft")
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining(branchA.getId().toString())
                    .hasMessageContaining("Nincs élő kezelési díj konfiguráció");
        }
    }

    // =========================================================================
    // 4. FR-2 end-to-end: V383 seed bit-azonosság (PER_MILLE képlet)
    // =========================================================================
    @Test
    @DisplayName("FR-2: a V383 seed PER_MILLE paraméterrel bit-azonosan adja a korábbi cégszintű képletet")
    void v383SeedReproducesCompanyLevelFormula() throws Exception {
        // A kontextus-indításkor a Flyway üres branch-táblára futtatta a V383-at; a seed
        // idempotens újrajátszása (nfr2 bizonyította) a teszt-irodákra ugyanazt a logikát
        // futtatja, mint élesben a már létező irodákra.
        txTemplate.executeWithoutResult(status -> {
            systemParameterRepository.saveAndFlush(SystemParameter.builder()
                    .parameterKey("HANDLING_FEE_TYPE")
                    .companyId(companyA.getId())
                    .parameterValue("PER_MILLE")
                    .parameterType("STRING").category("HANDLING_FEE")
                    .description("IT").isActive(true).build());
            systemParameterRepository.saveAndFlush(SystemParameter.builder()
                    .parameterKey("HANDLING_FEE_PER_MILLE")
                    .companyId(companyA.getId())
                    .parameterValue("3.5")
                    .parameterType("STRING").category("HANDLING_FEE")
                    .description("IT").isActive(true).build());
        });

        replayV383MigrationFile();

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            when(discountThresholdService.resolveDiscount(any(BigDecimal.class)))
                    .thenReturn(Optional.empty());

            // V383 seed-sor megléte a cég-scope paraméterek szerint
            BranchHandlingFeeConfig seeded = configRepository
                    .findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                            companyA.getId(), branchA.getId(), FeeConfigStatus.LIVE)
                    .orElseThrow();
            assertThat(seeded.getFeeMode()).isEqualTo(HandlingFeeType.PER_MILLE);
            assertThat(seeded.getPerMilleRate()).isEqualByComparingTo("3.5");
            assertThat(seeded.getCreatedBy()).isEqualTo("V383");

            // Bit-azonosság: a korábbi cégszintű képlet (multiply(rate).divide(1000, HALF_UP))
            // kézzel számított elvárt értékei 3 mintaösszegre (cap nincs beállítva).
            assertThat(handlingFeeService.calculateHandlingFee(new BigDecimal("100000"), branchA.getId()))
                    .as("100000 × 3.5 / 1000 = 350")
                    .isEqualByComparingTo("350");
            assertThat(handlingFeeService.calculateHandlingFee(new BigDecimal("123456"), branchA.getId()))
                    .as("123456 × 3.5 / 1000 = 432.096 → HALF_UP 432")
                    .isEqualByComparingTo("432");
            assertThat(handlingFeeService.calculateHandlingFee(new BigDecimal("1000000"), branchA.getId()))
                    .as("1000000 × 3.5 / 1000 = 3500")
                    .isEqualByComparingTo("3500");
        }
    }

    // =========================================================================
    // 5. W3/D17 — publish-swap a valós parciális egyedi indexen
    // =========================================================================
    @Test
    @DisplayName("W3/D17: publish meglévő LIVE(v0) + DRAFT felett SIKERES a valós egyedi indexen")
    void publishSwapAzElesSemanBanSikeres() {
        txTemplate.executeWithoutResult(status -> {
            configRepository.saveAndFlush(BranchHandlingFeeConfig.builder()
                    .companyId(companyA.getId())
                    .branchId(branchA.getId())
                    .feeMode(HandlingFeeType.PER_MILLE)
                    .perMilleRate(new BigDecimal("3"))
                    .status(FeeConfigStatus.LIVE)
                    .active(true)
                    .createdBy("V383").createdAt(LocalDateTime.now())
                    .publishedBy("V383").publishedAt(LocalDateTime.now())
                    .build());
        });

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("IT-WORKER");

            // DRAFT mentése, majd publikálás expectedVersion=0-val (B2: első publikálás)
            branchConfigService.saveDraft(branchA.getId(), draftRequest("PER_MILLE", "5", null));
            BranchFeeConfigDto published = branchConfigService.publish(branchA.getId(), 0L);
            assertThat(published.getStatus()).isEqualTo("LIVE");
            assertThat(published.getPerMilleRate()).isEqualByComparingTo("5");

            // (a) nincs constraint-sértés (eddig sem dobtunk); (b) pontosan 1 LIVE+aktív sor
            List<BranchHandlingFeeConfig> liveRows = configRepository.findByCompanyIdAndActiveTrue(companyA.getId())
                    .stream()
                    .filter(c -> c.getStatus() == FeeConfigStatus.LIVE)
                    .toList();
            assertThat(liveRows).hasSize(1);
            assertThat(liveRows.get(0).getPerMilleRate()).isEqualByComparingTo("5");
            // (c) a régi sor is_active=false archívumként MEGMARAD
            assertThat(configRepository.findAll().stream()
                    .filter(c -> branchA.getId().equals(c.getBranchId()) && !Boolean.TRUE.equals(c.getActive())))
                    .as("A régi LIVE sor archiválva megmarad")
                    .hasSize(1);
            // (d) az új LIVE sor publishedBy/publishedAt mezői kitöltve
            assertThat(liveRows.get(0).getPublishedBy()).isEqualTo("IT-WORKER");
            assertThat(liveRows.get(0).getPublishedAt()).isNotNull();
        }
    }

    @Test
    @DisplayName("W3: a swap után a parciális egyedi index TOVÁBBRA IS tiltja a második LIVE sort")
    void publishSwapNemHagyKetLiveSort() {
        txTemplate.executeWithoutResult(status -> {
            configRepository.saveAndFlush(BranchHandlingFeeConfig.builder()
                    .companyId(companyA.getId())
                    .branchId(branchA.getId())
                    .feeMode(HandlingFeeType.BRACKET)
                    .status(FeeConfigStatus.LIVE)
                    .active(true)
                    .createdBy("V383").createdAt(LocalDateTime.now())
                    .build());
        });

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyA.getId());
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("IT-WORKER");

            branchConfigService.saveDraft(branchA.getId(), draftRequest("PER_MILLE", "5", null));
            branchConfigService.publish(branchA.getId(), 0L);

            // A második (kézi, invariánst megkerülő) LIVE insert az indexbe ütközik
            assertThatThrownBy(() -> txTemplate.executeWithoutResult(status ->
                    configRepository.saveAndFlush(BranchHandlingFeeConfig.builder()
                            .companyId(companyA.getId())
                            .branchId(branchA.getId())
                            .feeMode(HandlingFeeType.PER_MILLE)
                            .perMilleRate(new BigDecimal("9"))
                            .status(FeeConfigStatus.LIVE)
                            .active(true)
                            .createdBy("IT").createdAt(LocalDateTime.now())
                            .build())))
                    .as("Az uk_bhfc_branch_live index a swap után is él")
                    .rootCause()
                    .hasMessageContaining("uk_bhfc_branch_live");
        }
    }

    // =========================================================================
    // 6. W6/D16 — a legacy GET csak LIVE sávokat adhat
    // =========================================================================
    @Test
    @DisplayName("W6: a status-szűrt finder CSAK a LIVE sávot adja; a régi finder kevert listát adna")
    void legacyGetCsakLiveSavokat() {
        txTemplate.executeWithoutResult(status -> {
            bracketRepository.saveAndFlush(HandlingFeeBracket.builder()
                    .company(companyA)
                    .bracketOrder(1)
                    .upperLimit(new BigDecimal("100000"))
                    .feeAmount(new BigDecimal("200"))
                    .active(true)
                    .status(FeeConfigStatus.LIVE)
                    .build());
            bracketRepository.saveAndFlush(HandlingFeeBracket.builder()
                    .company(companyA)
                    .bracketOrder(1)
                    .upperLimit(new BigDecimal("100000"))
                    .feeAmount(new BigDecimal("999"))
                    .active(true)
                    .status(FeeConfigStatus.DRAFT)
                    .build());
        });

        List<HandlingFeeBracket> statusFiltered = bracketRepository
                .findByCompanyIdAndStatusAndActiveOrderByBracketOrder(companyA.getId(), FeeConfigStatus.LIVE, true);
        assertThat(statusFiltered)
                .as("W6: a javított legacy GET CSAK a LIVE sávot adja (a 999 Ft-os DRAFT nem szivárog)")
                .hasSize(1);
        assertThat(statusFiltered.get(0).getFeeAmount()).isEqualByComparingTo("200");

        List<HandlingFeeBracket> legacyUnfiltered = bracketRepository
                .findByCompanyIdAndActiveOrderByBracketOrder(companyA.getId(), true);
        assertThat(legacyUnfiltered)
                .as("W6: a régi status nélküli finder kevert LIVE+DRAFT listát adott volna")
                .hasSize(2);
    }

    // ============================ HELPEREK ============================

    private static Branch branch(String code, Company company, Dictionary branchType,
                                 Dictionary country, Dictionary statusDict, LocalDateTime now) {
        return Branch.builder()
                .code(code)
                .company(company)
                .bankCode("FK096BANK")
                .branchType(branchType)
                .name("FK-096 IT branch " + code)
                .address("Test street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(statusDict)
                .isVault(false)
                .openingDate(LocalDate.now())
                .createdAt(now)
                .build();
    }

    private static BranchFeeConfigDraftRequest draftRequest(String feeMode, String rate, String cap) {
        BranchFeeConfigDraftRequest request = new BranchFeeConfigDraftRequest();
        request.setFeeMode(feeMode);
        request.setPerMilleRate(rate != null ? new BigDecimal(rate) : null);
        request.setPerMilleCap(cap != null ? new BigDecimal(cap) : null);
        return request;
    }

    /**
     * A teljes V383 fájl újrajátszása nyers SQL-ként (idempotens — IF NOT EXISTS /
     * NOT EXISTS guardok). Így a @BeforeEach-ben létrehozott irodák ugyanazon a
     * seed-logikán mennek át, mint élesben a már létező irodák.
     */
    private static void replayV383MigrationFile() throws Exception {
        Path file = Path.of("src", "main", "resources", "db", "migration",
                "V383__fk096_branch_handling_fee_config.sql");
        String sql = Files.readString(file, java.nio.charset.StandardCharsets.UTF_8);
        try (Connection connection = DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             Statement statement = connection.createStatement()) {
            statement.execute(sql);
        }
    }
}
