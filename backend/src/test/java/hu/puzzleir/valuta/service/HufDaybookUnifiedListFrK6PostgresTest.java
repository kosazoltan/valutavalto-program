package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-022 kiegészítés FR-K6 (RED-fázis): egyesített FF/UF naplókönyv-lista
 * (shipment_request + transfer), cross-tenant izoláció, irány- és sztornó-szemantika.
 *
 * <p>Kontraktus-döntések (spec-hézagok, dokumentálva a beadási jelentésben):
 * <ul>
 *   <li>A sor timestamp-je MINDKÉT forrásnál a {@code createdAt}-ból képződik (HH:mm:ss)
 *       — transzfernél NEM a transferDate/transferTime; a tesztek szándékosan eltérő
 *       transferTime-mal diszkriminálnak.</li>
 *   <li>A nap-hozzárendelés transzfernél a createdAt dátuma (a seedelt adatokban a
 *       transferDate ezzel megegyezik, így a teszt nem szűkíti le a kettő közül a választást).</li>
 *   <li>Irány: FF prefixű bizonylat a fromBranch naplójában, UF a toBranch naplójában
 *       jelenik meg — a meglévő shipment-lekérdezés szemantikája szerint.</li>
 *   <li>Transzfer-sztornó jelzés: {@code is_cancelled=true} ÉS {@code cancelled_at} együtt;
 *       az anomális (is_cancelled=false, cancelled_at kitöltött) rekord NEM sztornó.</li>
 * </ul></p>
 */
@Testcontainers
@Import(HufDaybookService.class)
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class HufDaybookUnifiedListFrK6PostgresTest {

    private static final LocalDate DAY = LocalDate.of(2026, 7, 1);

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
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private TransferRepository transferRepository;
    @Autowired private HufDaybookService hufDaybookService;
    @Autowired private TransactionTemplate transactionTemplate;

    /** A régió-scope guard kikapcsolva (null scope) — a fókusz az egyesített lista. */
    @MockitoBean
    private AccessScopeService accessScopeService;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // =====================================================================
    // FR-K6 / 7. G-W-T: shipment + transfer egyesítve, createdAt-időrendben
    // =====================================================================
    @Test
    @DisplayName("FR-K6/7: shipment- és transfer-alapú FF/UF bizonylat EGY egyesített listában, createdAt szerinti sorrendben és timestamp-pel jelenik meg")
    void unifiedListMergesShipmentAndTransferByCreatedAt() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K6T7"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // UF transfer a branchA-ra: createdAt 09:15:00, de transferTime szándékosan 23:59
            // — a timestamp-nek a createdAt-ból kell képződnie.
            saveTransfer(seed, "UF-000201", seed.branchB(), seed.branchA(),
                    DAY.atTime(9, 15, 0), LocalTime.of(23, 59), false, null);
            // AT (deviza) transfer ugyanarra a napra/irodára: NEM része a FF/UF naplónak.
            saveTransfer(seed, "AT-000202", seed.branchA(), seed.branchB(),
                    DAY.atTime(9, 45, 0), LocalTime.of(9, 45), false, null);
            // FF shipment a branchA-ról: createdAt 10:30:00.
            saveShipment(seed, "FF-000021", "FF", seed.branchA().getId(), seed.branchB().getId(),
                    DAY.atTime(10, 30, 0), false, null);
        });

        authenticate(seed.company().getId(), seed.branchA().getId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(seed.branchA().getId(), DAY);

        assertThat(daybook.getRows())
                .as("RED (FR-K6): az egyesített naplóban a transfer-alapú UF bizonylatnak IS szerepelnie kell, "
                        + "createdAt szerint a shipment ELŐTT; az AT- (deviza) bizonylat kizárva")
                .extracting(HufDaybookRowDto::getReceiptNumber)
                .containsExactly("UF-000201", "FF-000021");
        assertThat(daybook.getRows())
                .extracting(HufDaybookRowDto::getTimestamp)
                .as("A timestamp mindkét forrásnál a createdAt-ból képződik (nem transferTime/requestDate)")
                .containsExactly("09:15:00", "10:30:00");
    }

    // =====================================================================
    // FR-K6 / 8. G-W-T: cross-tenant — transfer.company_id szűrés
    // =====================================================================
    @Test
    @DisplayName("FR-K6/8: T2 tenant naplója NEM tartalmazhat T1 tenant transfer-alapú FF/UF bizonylatot (transfer.company_id szűrés)")
    void crossTenantTransferIsolationByCompanyId() {
        Seed tenant1 = transactionTemplate.execute(status -> seedBase("K6T8A"));
        Seed tenant2 = transactionTemplate.execute(status -> seedBase("K6T8B"));
        assertThat(tenant1).isNotNull();
        assertThat(tenant2).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // Anomális T1-es rekord, amely a T2 branch-ére mutat (from_branch = T2 branchA),
            // de company_id = T1 — a companyId-szűrésnek KI KELL zárnia.
            transferRepository.save(transferBuilder(tenant1, "FF-000301",
                    tenant2.branchA(), tenant2.branchB(), DAY.atTime(9, 0, 0), LocalTime.of(9, 0))
                    .companyId(tenant1.company().getId())
                    .build());
            // T2 saját FF transzfere ugyanarról a branch-ről — ennek meg KELL jelennie.
            saveTransfer(tenant2, "FF-000302", tenant2.branchA(), tenant2.branchB(),
                    DAY.atTime(10, 0, 0), LocalTime.of(10, 0), false, null);
        });

        authenticate(tenant2.company().getId(), tenant2.branchA().getId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(tenant2.branchA().getId(), DAY);

        List<String> receiptNumbers = daybook.getRows().stream()
                .map(HufDaybookRowDto::getReceiptNumber)
                .toList();
        assertThat(receiptNumbers)
                .as("RED (FR-K6): a T2 saját transfer-alapú FF bizonylata még hiányzik az egyesített naplóból")
                .contains("FF-000302");
        assertThat(receiptNumbers)
                .as("A T1 tenant transzfere (company_id=T1) NEM szivároghat át a T2 naplójába")
                .doesNotContain("FF-000301");
    }

    // =====================================================================
    // FR-K6 / 9. G-W-T: irány-alapú branch-egyezés (FF→fromBranch, UF→toBranch)
    // =====================================================================
    @Test
    @DisplayName("FR-K6/9: FF prefixű transfer csak a fromBranch, UF csak a toBranch naplójában jelenik meg; idegen branch-nél nem")
    void directionDeterminesWhichBranchSeesTransfer() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K6T9"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            saveTransfer(seed, "FF-000401", seed.branchA(), seed.branchB(),
                    DAY.atTime(9, 0, 0), LocalTime.of(9, 0), false, null);
            saveTransfer(seed, "UF-000402", seed.branchA(), seed.branchB(),
                    DAY.atTime(10, 0, 0), LocalTime.of(10, 0), false, null);
        });

        authenticate(seed.company().getId(), seed.branchA().getId());
        List<String> branchARows = receiptNumbers(
                hufDaybookService.getDaybook(seed.branchA().getId(), DAY));
        assertThat(branchARows)
                .as("RED (FR-K6): az FF transfer a fromBranch (A) naplójában kell megjelenjen")
                .contains("FF-000401");
        assertThat(branchARows)
                .as("A UF transfer NEM az A (fromBranch) naplójába tartozik")
                .doesNotContain("UF-000402");

        authenticate(seed.company().getId(), seed.branchB().getId());
        List<String> branchBRows = receiptNumbers(
                hufDaybookService.getDaybook(seed.branchB().getId(), DAY));
        assertThat(branchBRows)
                .as("RED (FR-K6): a UF transfer a toBranch (B) naplójában kell megjelenjen")
                .contains("UF-000402");
        assertThat(branchBRows)
                .as("Az FF transfer NEM a B (toBranch) naplójába tartozik — idegen branch-nél nem jelenhet meg")
                .doesNotContain("FF-000401");
    }

    // =====================================================================
    // FR-K6 / 10. G-W-T: transfer sztornó-szűrés is_cancelled + cancelled_at alapján
    // =====================================================================
    @Test
    @DisplayName("FR-K6/10: transzfernél a sztornó-ág az is_cancelled boolean alapján dől el — is_cancelled=false + kitöltött cancelled_at NEM sztornó")
    void transferStornoUsesIsCancelledFlagNotOnlyCancelledAt() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K6T10"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // Anomális rekord: cancelled_at kitöltve, de is_cancelled=false → NEM sztornó.
            saveTransfer(seed, "FF-000501", seed.branchA(), seed.branchB(),
                    DAY.atTime(9, 0, 0), LocalTime.of(9, 0), false, DAY.atTime(11, 0));
            // Valódi sztornó: is_cancelled=true + cancelled_at.
            saveTransfer(seed, "UF-000502", seed.branchB(), seed.branchA(),
                    DAY.atTime(9, 30, 0), LocalTime.of(9, 30), true, DAY.atTime(11, 30));
        });

        authenticate(seed.company().getId(), seed.branchA().getId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(seed.branchA().getId(), DAY);

        List<HufDaybookRowDto> anomalousRows = daybook.getRows().stream()
                .filter(r -> r.getReceiptNumber() != null && r.getReceiptNumber().startsWith("FF-000501"))
                .toList();
        assertThat(anomalousRows)
                .as("RED (FR-K6): az is_cancelled=false transzfer PONTOSAN EGY, normál (nem sztornó) sort ad — "
                        + "a kitöltött cancelled_at önmagában nem sorolhatja téves sztornó-ágba")
                .hasSize(1);
        assertThat(anomalousRows.get(0).isStorno()).isFalse();

        List<HufDaybookRowDto> cancelledRows = daybook.getRows().stream()
                .filter(r -> r.getReceiptNumber() != null && r.getReceiptNumber().startsWith("UF-000502"))
                .toList();
        assertThat(cancelledRows)
                .as("RED (FR-K6): az is_cancelled=true transzfer normál + sztornó sort ad (2 sor)")
                .hasSize(2);
        assertThat(cancelledRows)
                .filteredOn(HufDaybookRowDto::isStorno)
                .as("A sztornó-sor SZTORNÓ jelöléssel és az eredeti bizonylatszámra hivatkozó "
                        + "bizonylatszámmal jelenik meg (…-SZ konvenció)")
                .hasSize(1)
                .allSatisfy(row -> {
                    assertThat(row.getReceiptNumber()).startsWith("UF-000502");
                    assertThat(row.getReceiptNumber()).isNotEqualTo("UF-000502");
                });
    }

    // =====================================================================
    // FR-K6 / 11. G-W-T: napi szűrés alapja transzfernél a transferDate
    // =====================================================================
    @Test
    @DisplayName("FR-K6/11: éjfél után rögzített, előző napi transferDate-ű transfer az előző napi naplóban jelenik meg (napi szűrés = transferDate, nem created_at dátumrésze)")
    void transferDayFilterUsesTransferDateNotCreatedAtDate() {
        Seed seed = transactionTemplate.execute(status -> seedBase("K6T11"));
        assertThat(seed).isNotNull();

        // Éjszakai zárás utáni utólagos rögzítés: transferDate = 2026-08-01,
        // de created_at = 2026-08-02 00:15 (éjfél után).
        LocalDate businessDay = LocalDate.of(2026, 8, 1);
        transactionTemplate.executeWithoutResult(status ->
                transferRepository.save(transferBuilder(seed, "FF-000601",
                        seed.branchA(), seed.branchB(),
                        businessDay.plusDays(1).atTime(0, 15, 0), LocalTime.of(0, 15))
                        .transferDate(businessDay)
                        .build()));

        authenticate(seed.company().getId(), seed.branchA().getId());

        List<String> businessDayRows = receiptNumbers(
                hufDaybookService.getDaybook(seed.branchA().getId(), businessDay));
        assertThat(businessDayRows)
                .as("RED (FR-K6/11): az előző napi transferDate-ű, éjfél után rögzített transfer "
                        + "a transferDate napjának (2026-08-01) naplójában kell megjelenjen "
                        + "(napi szűrés = transferDate, konzisztensen a shipment requestDate-szűrésével)")
                .contains("FF-000601");

        List<String> nextDayRows = receiptNumbers(
                hufDaybookService.getDaybook(seed.branchA().getId(), businessDay.plusDays(1)));
        assertThat(nextDayRows)
                .as("A created_at dátumrésze (2026-08-02) szerinti napon NEM jelenhet meg — "
                        + "a napi szűrés nem a created_at dátumán alapul")
                .doesNotContain("FF-000601");
    }

    // ============================ HELPEREK ============================

    private List<String> receiptNumbers(HufDaybookDto daybook) {
        return daybook.getRows().stream().map(HufDaybookRowDto::getReceiptNumber).toList();
    }

    private void authenticate(UUID companyId, UUID branchId) {
        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken("K6-TESZT", "test", "ROLE_ERTEKTAR");
        authentication.setDetails(new WorkerAuthenticationDetails(42L, companyId, branchId, "ERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private void saveShipment(Seed seed, String requestNumber, String prefix,
                              UUID fromBranchId, UUID toBranchId, LocalDateTime createdAt,
                              boolean cancelled, LocalDateTime cancelledAt) {
        shipmentRequestRepository.save(ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(seed.company().getId())
                .serialPrefix(prefix)
                .serialNumber(Long.parseLong(requestNumber.substring(3)))
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .requestedById(seed.worker().getId())
                .requestDate(createdAt.toLocalDate())
                .carrierName("Teszt Szallito")
                .sealNumber("PL-1")
                .cancelledAt(cancelled ? cancelledAt : null)
                .createdAt(createdAt)
                .build());
    }

    private void saveTransfer(Seed seed, String transferNumber, Branch fromBranch, Branch toBranch,
                              LocalDateTime createdAt, LocalTime transferTime,
                              boolean isCancelled, LocalDateTime cancelledAt) {
        transferRepository.save(transferBuilder(seed, transferNumber, fromBranch, toBranch, createdAt, transferTime)
                .isCancelled(isCancelled)
                .cancelledAt(cancelledAt)
                .build());
    }

    private Transfer.TransferBuilder transferBuilder(Seed seed, String transferNumber,
                                                     Branch fromBranch, Branch toBranch,
                                                     LocalDateTime createdAt, LocalTime transferTime) {
        return Transfer.builder()
                .transferNumber(transferNumber)
                .companyId(seed.company().getId())
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(seed.worker())
                .transferType(Transfer.TransferType.CASH)
                .status(Transfer.TransferStatus.COMPLETED)
                .transferDate(createdAt.toLocalDate())
                .transferTime(transferTime)
                .currency(seed.huf())
                .amount(new BigDecimal("100000.0000"))
                .hufValue(new BigDecimal("100000.00"))
                .direction(Transfer.TransferDirection.F)
                .createdAt(createdAt);
    }

    private Seed seedBase(String tag) {
        LocalDateTime now = DAY.atTime(6, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Company company = companyRepository.save(Company.builder()
                .code(tag + "-" + suffix)
                .name("FR-K6 unified company " + tag)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(tag + "-BT-" + suffix)
                .name("FR-K6 branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(tag + "-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(tag + "-BS-" + suffix)
                .name("Active")
                .createdAt(now)
                .build());
        Branch branchA = seedBranch(company, tag + "-A-" + suffix, branchType, country, branchStatus, now);
        Branch branchB = seedBranch(company, tag + "-B-" + suffix, branchType, country, branchStatus, now);
        Worker worker = workerRepository.save(Worker.builder()
                .company(company)
                .branch(branchA)
                .code(("W" + suffix).substring(0, Math.min(10, ("W" + suffix).length())))
                .name("FR-K6 Teszt Dolgozo")
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF")
                        .name("Forint")
                        .symbol("Ft")
                        .decimalPlaces(0)
                        .active(true)
                        .createdAt(now)
                        .build()));
        return new Seed(company, branchA, branchB, worker, huf);
    }

    private Branch seedBranch(Company company, String code, Dictionary branchType,
                              Dictionary country, Dictionary branchStatus, LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code(code)
                .company(company)
                .bankCode("K6BANK")
                .branchType(branchType)
                .name("FR-K6 Branch " + code)
                .address("Teszt utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .isActive(true)
                .openingDate(DAY)
                .createdAt(now)
                .build());
    }

    private record Seed(Company company, Branch branchA, Branch branchB, Worker worker, Currency huf) {
    }
}
