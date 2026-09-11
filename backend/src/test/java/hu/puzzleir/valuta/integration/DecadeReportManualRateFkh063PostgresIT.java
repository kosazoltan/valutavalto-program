package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.dto.decade.DecadeReportLineDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.MnbSettlementRateHistory;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DecadeReportRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.MnbSettlementRateHistoryRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.DecadeReportService;
import hu.puzzleir.valuta.service.MnbExchangeRateService;
import hu.puzzleir.valuta.service.MnbRateQueryClient;
import hu.puzzleir.valuta.service.MnbSettlementRateService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * FKH-063 end-to-end on a real PostgreSQL schema: a currency MNB does not quote is valued from the
 * company's hand-entered FK-028 settlement rate, and the provenance is PERSISTED.
 *
 * <p>The Mockito test proves the in-memory object graph; this one proves the JPA path — column
 * mapping of the two new provenance fields, the CHECK constraint accepting the written value, and
 * the company-scoped predicate of the derived history query. A column-name typo or a companyId
 * mix-up would pass every mock-based test and fail here.</p>
 */
@Testcontainers
@EnableJpaAuditing
@Import({DecadeReportService.class, MnbSettlementRateService.class, AuditLogService.class})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class DecadeReportManualRateFkh063PostgresIT {

    private static final ZoneId BUDAPEST = ZoneId.of("Europe/Budapest");
    /** Global decade 25 = 2026-09-01..2026-09-10. */
    private static final int DECADE = 25;
    private static final LocalDate PERIOD_START = LocalDate.of(2026, 9, 1);
    private static final LocalDate PERIOD_END = LocalDate.of(2026, 9, 10);
    private static final BigDecimal STOCK = new BigDecimal("1000.00");
    private static final BigDecimal MANUAL_RATE = new BigDecimal("185.5000");
    private static final AtomicInteger SEQ = new AtomicInteger(100);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private DecadeReportService decadeReportService;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private DailyBalanceRepository dailyBalanceRepository;
    @Autowired private DecadeReportRepository decadeReportRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private MnbSettlementRateHistoryRepository historyRepository;
    @Autowired private JdbcTemplate jdbcTemplate;

    /** MNB quotes nothing here — every lookup returns an empty map, as it does for BAM in prod. */
    @MockitoBean
    private MnbExchangeRateService mnbExchangeRateService;
    /** Constructor dep of MnbSettlementRateService — never called here. */
    @MockitoBean
    private MnbRateQueryClient mnbRateQueryClient;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    private record Fixture(UUID companyId, UUID branchId) { }

    private Fixture seed() {
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        int n = SEQ.incrementAndGet();
        LocalDateTime now = LocalDateTime.now();
        Company company = companyRepository.save(Company.builder()
                .code("FKH63" + n).name("FKH-063 Co " + n).createdAt(now).build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE").code("BT63" + n).name("branch type").createdAt(now).build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY").code("CO63" + n).name("Hungary").createdAt(now).build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS").code("BS63" + n).name("Active").createdAt(now).build());
        Branch branch = branchRepository.save(Branch.builder()
                .company(company).code("Z63" + n).name("FKH-063 Branch " + n)
                .bankCode("FKH63BANK").branchType(branchType).country(country).branchStatus(branchStatus)
                .address("Teszt utca 1").city("Budapest").zipCode("1000")
                .openingDate(PERIOD_START.minusYears(1)).isVault(false).isActive(true)
                .createdAt(now)
                .build());
        saveBalance(company, branch.getId(), PERIOD_START);
        saveBalance(company, branch.getId(), PERIOD_END);
        return new Fixture(company.getId(), branch.getId());
    }

    private void saveBalance(Company company, UUID branchId, LocalDate date) {
        dailyBalanceRepository.save(DailyBalance.builder()
                .company(company)
                .branchId(branchId)
                .balanceDate(date)
                .currencyCode("BAM")
                .openingBalance(STOCK)
                .closingBalance(STOCK)
                .build());
    }

    private void recordSettlementRate(UUID companyId, BigDecimal rate, LocalDate recordedOn) {
        historyRepository.save(MnbSettlementRateHistory.builder()
                .companyId(companyId)
                .currencyCode("BAM")
                .officialRate(rate)
                .recordedBy("FO63")
                .recordedAt(recordedOn.atTime(9, 0).atZone(BUDAPEST).toInstant())
                .build());
    }

    private void installAuth(UUID companyId) {
        var details = new WorkerAuthenticationDetails(1L, companyId, UUID.randomUUID(), "FOERTEKTAR");
        var auth = new TestingAuthenticationToken("FO63", "x", "ROLE_FOERTEKTAR");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private DecadeReportLineDto bamLine(DecadeReportDto dto) {
        return dto.getLines().stream()
                .filter(l -> "BAM".equals(l.getCurrencyCode()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("BAM line missing"));
    }

    @Test
    @DisplayName("FKH-063 IT: a hand-entered rate values the stock and MANUAL_SETTLEMENT is persisted")
    void manualRatePersistsValueAndProvenance() {
        Fixture f = seed();
        // FK-028 records each boundary rate on the FOLLOWING day; a decade has two boundaries.
        recordSettlementRate(f.companyId(), MANUAL_RATE, PERIOD_START.plusDays(1));
        recordSettlementRate(f.companyId(), MANUAL_RATE, PERIOD_END.plusDays(1));
        installAuth(f.companyId());

        DecadeReportDto dto = decadeReportService.generateDecadeReport(f.branchId(), 2026, DECADE);

        DecadeReportLineDto line = bamLine(dto);
        assertThat(line.getClosingMnbRate()).isEqualByComparingTo(MANUAL_RATE);
        assertThat(line.getClosingValueHuf()).isEqualByComparingTo(STOCK.multiply(MANUAL_RATE));
        assertThat(line.getClosingRateSource()).isEqualTo("MANUAL_SETTLEMENT");

        // The provenance really reached the database column, not just the DTO.
        String persisted = jdbcTemplate.queryForObject("""
                SELECT closing_rate_source FROM decade_report_line
                 WHERE currency_code = 'BAM' AND decade_report_id = ?
                """, String.class, dto.getId());
        assertThat(persisted).isEqualTo("MANUAL_SETTLEMENT");
    }

    @Test
    @DisplayName("FKH-063 IT: only a zero snapshot means ABSENT — non-zero stock still fails closed")
    void zeroSnapshotStillFailsClosed() {
        Fixture f = seed();
        // V353 seeds 0 as the "never recorded" marker: it must NOT be used as a rate.
        recordSettlementRate(f.companyId(), BigDecimal.ZERO, PERIOD_END.plusDays(1));
        installAuth(f.companyId());

        assertThatThrownBy(() -> decadeReportService.generateDecadeReport(f.branchId(), 2026, DECADE))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("BAM");

        // No silent zero valuation was persisted FOR THIS BRANCH (the container is shared
        // between tests, so the count must be branch-scoped).
        Integer lines = jdbcTemplate.queryForObject("""
                SELECT count(*) FROM decade_report_line l
                  JOIN decade_report r ON r.id = l.decade_report_id
                 WHERE r.branch_id = ? AND l.currency_code = 'BAM'
                """, Integer.class, f.branchId());
        assertThat(lines).isZero();
    }

    @Test
    @DisplayName("FKH-063 IT: another company's settlement rate is never used (invariant #1)")
    void crossTenantManualRateIsNeverUsed() {
        Fixture mine = seed();
        Fixture other = seed();
        // ONLY the other company has a usable rate.
        recordSettlementRate(other.companyId(), MANUAL_RATE, PERIOD_END.plusDays(1));
        installAuth(mine.companyId());

        assertThatThrownBy(() -> decadeReportService.generateDecadeReport(mine.branchId(), 2026, DECADE))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("BAM");
    }

    @Test
    @DisplayName("FKH-063 IT: a snapshot recorded long after the decade cannot value it retroactively")
    void futureSnapshotIsNotUsedForAPastDecade() {
        Fixture f = seed();
        recordSettlementRate(f.companyId(), MANUAL_RATE, PERIOD_END.plusDays(40));
        installAuth(f.companyId());

        assertThatThrownBy(() -> decadeReportService.generateDecadeReport(f.branchId(), 2026, DECADE))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("BAM");

        // Once in-window rates exist for both boundaries, generation succeeds with the rate of
        // the decade's OWN period — the 40-days-later snapshot never enters the valuation.
        recordSettlementRate(f.companyId(), MANUAL_RATE, PERIOD_START.plusDays(1));
        recordSettlementRate(f.companyId(), MANUAL_RATE, PERIOD_END.plusDays(1));
        DecadeReportDto dto = decadeReportService.generateDecadeReport(f.branchId(), 2026, DECADE);
        assertThat(bamLine(dto).getClosingRateSource()).isEqualTo("MANUAL_SETTLEMENT");
        assertThat(bamLine(dto).getClosingMnbRate()).isEqualByComparingTo(MANUAL_RATE);

        // NOTE: re-generating the same report in one JVM run is NOT asserted here. The in-place
        // regeneration path (DecadeReportService.java:235 `report.getLines().clear()` followed by
        // fresh line inserts) violates uk_decade_line_report_currency (V82) because Hibernate
        // orders the inserts before the orphan deletes. Verified pre-existing on BASE b2c27b6d
        // (the clear() and the constraint both predate FKH-063; this change touches neither), so
        // it is tracked as a separate defect rather than silently fixed inside a money change.
    }

    @Test
    @DisplayName("FKH-063 IT: the opening boundary resolves from its own period, not the closing one")
    void openingBoundaryUsesItsOwnAsOfWindow() {
        Fixture f = seed();
        List<LocalDate> recordings = List.of(PERIOD_START.plusDays(1), PERIOD_END.plusDays(1));
        recordSettlementRate(f.companyId(), new BigDecimal("180.0000"), recordings.get(0));
        recordSettlementRate(f.companyId(), new BigDecimal("190.0000"), recordings.get(1));
        installAuth(f.companyId());

        DecadeReportDto dto = decadeReportService.generateDecadeReport(f.branchId(), 2026, DECADE);

        DecadeReportLineDto line = bamLine(dto);
        assertThat(line.getOpeningMnbRate()).isEqualByComparingTo("180.0000");
        assertThat(line.getClosingMnbRate()).isEqualByComparingTo("190.0000");
        assertThat(line.getOpeningRateSource()).isEqualTo("MANUAL_SETTLEMENT");
    }

    @Test
    @DisplayName("FKH-063 IT: exactly one persisted BAM line carries the manual provenance")
    void exactlyOneLineIsPersistedWithManualProvenance() {
        Fixture f = seed();
        recordSettlementRate(f.companyId(), MANUAL_RATE, PERIOD_START.plusDays(1));
        recordSettlementRate(f.companyId(), MANUAL_RATE, PERIOD_END.plusDays(1));
        installAuth(f.companyId());

        decadeReportService.generateDecadeReport(f.branchId(), 2026, DECADE);

        assertThat(decadeReportRepository.findByBranchIdAndYearAndDecade(f.branchId(), 2026, DECADE))
                .isPresent();
        Integer lines = jdbcTemplate.queryForObject("""
                SELECT count(*) FROM decade_report_line l
                  JOIN decade_report r ON r.id = l.decade_report_id
                 WHERE r.branch_id = ? AND l.currency_code = 'BAM'
                   AND l.opening_rate_source = 'MANUAL_SETTLEMENT'
                   AND l.closing_rate_source = 'MANUAL_SETTLEMENT'
                """, Integer.class, f.branchId());
        assertThat(lines).isEqualTo(1);
    }
}
