package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbQueryRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateUpdateRequest;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.MnbSettlementRate;
import hu.puzzleir.valuta.entity.MnbSettlementRateHistory;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.MnbSettlementRateHistoryRepository;
import hu.puzzleir.valuta.repository.MnbSettlementRateRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.AuditLogService;
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
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@Testcontainers
@EnableJpaAuditing
@Import({MnbSettlementRateService.class, AuditLogService.class})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect",
                "mnb-settlement.query.min-interval-ms=0"
        })
class MnbSettlementRatePostgresIT {

    private static final AtomicInteger SEQ = new AtomicInteger(10);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private MnbSettlementRateService service;
    @Autowired private MnbSettlementRateRepository rateRepository;
    @Autowired private MnbSettlementRateHistoryRepository historyRepository;
    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private JdbcTemplate jdbcTemplate;

    @MockitoBean
    private MnbRateQueryClient mnbRateQueryClient;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("update: árfolyamokat ment és egy teljes, közös recorded_at snapshotot hoz létre")
    void update_savesRatesAndCreatesFullSnapshot() {
        Seed seed = seedCompanyWithRows("UPD");
        installAuth(seed.companyId(), "FOERTEKTAR", "FO01");
        int activeCount = activeCurrencyCount();

        service.update(request(item("EUR", "401.2500"), item("USD", "352.1000")), false);

        Map<String, MnbSettlementRate> rows = rowsFor(seed.companyId());
        assertThat(rows.get("EUR").getOfficialRate()).isEqualByComparingTo("401.2500");
        assertThat(rows.get("USD").getOfficialRate()).isEqualByComparingTo("352.1000");
        assertThat(rows.get("EUR").getUpdatedBy()).isEqualTo("FO01");

        List<MnbSettlementRateHistory> history = historyRepository.findByCompanyIdOrderByRecordedAtDesc(seed.companyId());
        assertThat(history).hasSize(activeCount);
        assertThat(history).extracting(MnbSettlementRateHistory::getRecordedAt).containsOnly(history.get(0).getRecordedAt());
        assertThat(history).extracting(MnbSettlementRateHistory::getCurrencyCode).contains("HUF", "EUR", "USD");
        assertThat(history).extracting(MnbSettlementRateHistory::getRecordedBy).containsOnly("FO01");
    }

    @Test
    @DisplayName("publish: minden cég-saját sort azonos timestamp-pel irodáknak elérhetővé tesz, és ezt snapshotolja")
    void publish_stampsAllRowsAndSnapshotsTimestamp() {
        Seed seed = seedCompanyWithRows("PUB");
        installAuth(seed.companyId(), "FOERTEKTAR", "FO02");

        service.update(request(item("EUR", "402.0000")), true);

        Map<String, MnbSettlementRate> rows = rowsFor(seed.companyId());
        Instant publishedAt = rows.get("EUR").getAvailableToOfficesAt();
        assertThat(publishedAt).isNotNull();
        assertThat(rows.values()).allSatisfy(row -> assertThat(row.getAvailableToOfficesAt()).isEqualTo(publishedAt));
        List<MnbSettlementRateHistory> history = historyRepository.findByCompanyIdOrderByRecordedAtDesc(seed.companyId());
        assertThat(history).extracting(MnbSettlementRateHistory::getAvailableToOfficesAt).containsOnly(publishedAt);
    }

    @Test
    @DisplayName("update: sima rögzítés nem írja felül az available_to_offices_at mezőt")
    void update_doesNotTouchAvailableToOfficesAt() {
        Seed seed = seedCompanyWithRows("AVL");
        installAuth(seed.companyId(), "FOERTEKTAR", "FO03");
        Instant before = rowsFor(seed.companyId()).get("EUR").getAvailableToOfficesAt();

        service.update(request(item("EUR", "403.0000")), false);

        assertThat(rowsFor(seed.companyId()).get("EUR").getAvailableToOfficesAt()).isEqualTo(before);
    }

    @Test
    @DisplayName("tenant izoláció: T2 update nem módosítja T1 árfolyam/timestamp/updated_by értékeit")
    void crossTenant_isolation() {
        Seed first = seedCompanyWithRows("T1A");
        Seed second = seedCompanyWithRows("T2A");
        Map<String, MnbSettlementRate> before = rowsFor(first.companyId());
        installAuth(second.companyId(), "FOERTEKTAR", "FO04");

        service.update(request(item("EUR", "410.0000")), true);

        Map<String, MnbSettlementRate> after = rowsFor(first.companyId());
        assertThat(after.get("EUR").getOfficialRate()).isEqualByComparingTo(before.get("EUR").getOfficialRate());
        assertThat(after.get("EUR").getAvailableToOfficesAt()).isEqualTo(before.get("EUR").getAvailableToOfficesAt());
        assertThat(after.get("EUR").getUpdatedBy()).isEqualTo(before.get("EUR").getUpdatedBy());
    }

    @Test
    @DisplayName("audit: módosított soronként UPDATE/MnbSettlementRate audit keletkezik entityId=valutakód")
    void update_auditLogCreated() {
        Seed seed = seedCompanyWithRows("AUD");
        installAuth(seed.companyId(), "FOERTEKTAR", "FO05");

        service.update(request(item("EUR", "405.0000")), false);

        List<AuditLog> audit = auditLogRepository.findByCompanyIdAndEntityTypeAndEntityIdOrderByCreatedAtDesc(
                seed.companyId(), "MnbSettlementRate", "EUR");
        assertThat(audit).hasSize(1);
        assertThat(audit.get(0).getAction()).isEqualTo("UPDATE");
        assertThat(audit.get(0).getOldValue()).contains("\"KAT\":\"RATE\"");
        assertThat(audit.get(0).getNewValue()).contains("405.0000");
    }

    @Test
    @DisplayName("lista: a dinamikusan inaktivált valuta eltűnik a listából a meglévő rate-sor ellenére")
    void list_reflectsDynamicCurrencyList() {
        Seed seed = seedCompanyWithRows("DYN");
        String code = seedUniqueCurrency();
        transactionTemplate.executeWithoutResult(status -> rateRepository.save(MnbSettlementRate.builder()
                .companyId(seed.companyId())
                .currencyCode(code)
                .officialRate(new BigDecimal("123.0000"))
                .updatedAt(Instant.parse("2026-07-09T08:00:00Z"))
                .build()));
        installAuth(seed.companyId(), "BELSO_ELLENOR", "ELL01");
        assertThat(service.list()).extracting(MnbSettlementRateDto::currencyCode).contains(code);

        transactionTemplate.executeWithoutResult(status -> {
            Currency currency = currencyRepository.findByCode(code).orElseThrow();
            currency.setActive(false);
            currencyRepository.save(currency);
        });

        assertThat(service.list()).extracting(MnbSettlementRateDto::currencyCode).doesNotContain(code);
    }

    @Test
    @DisplayName("mnb-query: mockolt MNB válasz után exchange_rate, settlement-rate, history és UPDATE audit változatlan")
    void mnbQuery_doesNotWriteAnyTable() {
        Seed seed = seedCompanyWithRows("MQW");
        installAuth(seed.companyId(), "FOERTEKTAR", "FO06");
        when(mnbRateQueryClient.fetchCurrentRates()).thenReturn(Map.of(
                "EUR", new BigDecimal("401.2500"),
                "USD", new BigDecimal("352.1000")));
        long exchangeRateBefore = countRows("exchange_rate");
        long settlementBefore = countRows("mnb_settlement_rate");
        long historyBefore = countRows("mnb_settlement_rate_history");
        long updateAuditBefore = updateAuditCount(seed.companyId());
        List<String> settlementRowsBefore = settlementRateFingerprints(seed.companyId());

        List<MnbQueryRateDto> rows = service.mnbQuery();

        assertThat(rows).extracting(MnbQueryRateDto::currencyCode).containsExactly("EUR", "USD");
        assertThat(rows.get(0).officialRate()).isEqualByComparingTo("401.2500");
        assertThat(rows.get(1).officialRate()).isEqualByComparingTo("352.1000");
        assertThat(countRows("exchange_rate")).isEqualTo(exchangeRateBefore);
        assertThat(countRows("mnb_settlement_rate")).isEqualTo(settlementBefore);
        assertThat(countRows("mnb_settlement_rate_history")).isEqualTo(historyBefore);
        assertThat(updateAuditCount(seed.companyId())).isEqualTo(updateAuditBefore);
        assertThat(settlementRateFingerprints(seed.companyId())).isEqualTo(settlementRowsBefore);
    }

    @Test
    @DisplayName("mnb-query: inaktív valutát a mockolt MNB válaszból sem ad vissza")
    void mnbQuery_filtersInactiveCurrencies() {
        Seed seed = seedCompanyWithRows("MQF");
        String inactiveCode = seedUniqueCurrency();
        transactionTemplate.executeWithoutResult(status -> {
            Currency currency = currencyRepository.findByCode(inactiveCode).orElseThrow();
            currency.setActive(false);
            currencyRepository.save(currency);
        });
        installAuth(seed.companyId(), "FOERTEKTAR", "FO07");
        when(mnbRateQueryClient.fetchCurrentRates()).thenReturn(Map.of(
                "EUR", new BigDecimal("401.2500"),
                inactiveCode, new BigDecimal("999.0000")));

        List<MnbQueryRateDto> rows = service.mnbQuery();

        assertThat(rows).extracting(MnbQueryRateDto::currencyCode).containsExactly("EUR");
    }

    private Seed seedCompanyWithRows(String prefix) {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            ensureBaseCurrencies(now);
            int seq = SEQ.incrementAndGet();
            Company company = companyRepository.saveAndFlush(Company.builder()
                    .code(prefix + seq)
                    .name("MNB settlement test company " + prefix + seq)
                    .createdAt(now)
                    .build());
            Instant existingPublishedAt = Instant.parse("2026-07-09T07:00:00Z");
            rateRepository.save(MnbSettlementRate.builder()
                    .companyId(company.getId())
                    .currencyCode("HUF")
                    .officialRate(new BigDecimal("1.0000"))
                    .availableToOfficesAt(existingPublishedAt)
                    .updatedBy("SEED")
                    .updatedAt(existingPublishedAt)
                    .build());
            rateRepository.save(MnbSettlementRate.builder()
                    .companyId(company.getId())
                    .currencyCode("EUR")
                    .officialRate(new BigDecimal("399.0000"))
                    .availableToOfficesAt(existingPublishedAt)
                    .updatedBy("SEED")
                    .updatedAt(existingPublishedAt)
                    .build());
            rateRepository.save(MnbSettlementRate.builder()
                    .companyId(company.getId())
                    .currencyCode("USD")
                    .officialRate(new BigDecimal("350.0000"))
                    .availableToOfficesAt(existingPublishedAt)
                    .updatedBy("SEED")
                    .updatedAt(existingPublishedAt)
                    .build());
            return new Seed(company.getId());
        });
    }

    private void ensureBaseCurrencies(LocalDateTime now) {
        ensureCurrency("HUF", "Forint", 1, now);
        ensureCurrency("EUR", "Euro", 2, now);
        ensureCurrency("USD", "US dollar", 3, now);
    }

    private void ensureCurrency(String code, String name, int displayOrder, LocalDateTime now) {
        Currency currency = currencyRepository.findByCode(code).orElseGet(() -> Currency.builder()
                .code(code)
                .name(name)
                .symbol(code)
                .decimalPlaces("HUF".equals(code) ? 0 : 2)
                .displayOrder(displayOrder)
                .createdAt(now)
                .build());
        currency.setActive(true);
        currency.setDisplayOrder(displayOrder);
        currencyRepository.saveAndFlush(currency);
    }

    private String seedUniqueCurrency() {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String code = String.format("T%02d", SEQ.incrementAndGet());
            currencyRepository.saveAndFlush(Currency.builder()
                    .code(code)
                    .name("Dynamic currency " + code)
                    .symbol(code)
                    .decimalPlaces(2)
                    .active(true)
                    .displayOrder(90 + SEQ.get())
                    .createdAt(now)
                    .build());
            return code;
        });
    }

    private Map<String, MnbSettlementRate> rowsFor(UUID companyId) {
        return rateRepository.findByCompanyId(companyId).stream()
                .collect(Collectors.toMap(MnbSettlementRate::getCurrencyCode, row -> row));
    }

    private int activeCurrencyCount() {
        return currencyRepository.findByActiveTrueOrderByDisplayOrderAsc().size();
    }

    private long countRows(String tableName) {
        return jdbcTemplate.queryForObject("SELECT count(*) FROM " + tableName, Long.class);
    }

    private long updateAuditCount(UUID companyId) {
        return jdbcTemplate.queryForObject(
                "SELECT count(*) FROM audit_log WHERE company_id = ? AND action = 'UPDATE' AND entity_type = 'MnbSettlementRate'",
                Long.class,
                companyId);
    }

    private List<String> settlementRateFingerprints(UUID companyId) {
        return jdbcTemplate.queryForList(
                "SELECT currency_code || ':' || official_rate::text || ':' "
                        + "|| COALESCE(available_to_offices_at::text, '') || ':' "
                        + "|| COALESCE(updated_by, '') || ':' || COALESCE(updated_at::text, '') AS fp "
                        + "FROM mnb_settlement_rate WHERE company_id = ? ORDER BY currency_code",
                String.class,
                companyId);
    }

    private static void installAuth(UUID companyId, String role, String workerCode) {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(1L, companyId, UUID.randomUUID(), role);
        TestingAuthenticationToken auth = new TestingAuthenticationToken(workerCode, "x", "ROLE_" + role);
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private static MnbSettlementRateUpdateRequest request(MnbSettlementRateUpdateRequest.Item... items) {
        MnbSettlementRateUpdateRequest request = new MnbSettlementRateUpdateRequest();
        request.setItems(List.of(items));
        return request;
    }

    private static MnbSettlementRateUpdateRequest.Item item(String currencyCode, String rate) {
        return MnbSettlementRateUpdateRequest.Item.builder()
                .currencyCode(currencyCode)
                .officialRate(new BigDecimal(rate))
                .build();
    }

    private record Seed(UUID companyId) {
    }
}
