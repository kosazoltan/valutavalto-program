package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-030 kieg. FR-1/FR-2/FR-4 — a sztornózott tételek TELJES kizárása a Pénzforgalom
 * riportból, valós PostgreSQL-en (Testcontainers).
 *
 * <p>Ez a teszt a KIZÁRÁS mérvadó bizonyítéka (ticket C4): a kizárás lekérdezés-szintű,
 * a {@code CashFlowReportService} sztornó-ágai érintetlenül maradnak, ezért mockolt
 * repository-kkal a viselkedés nem bizonyítható — csak valódi JPQL-futtatással.</p>
 *
 * <p>Transfer-oldal (D1 truth table):
 * <ul>
 *   <li>COMPLETED + isCancelled=false → benne marad (FR-3);</li>
 *   <li>COMPLETED + isCancelled=true + indoklás (stornoCompleted) → KIZÁRVA (FR-1);</li>
 *   <li>CANCELLED + isCancelled=true + indoklás (stornoPending) → KIZÁRVA (FR-1);</li>
 *   <li>CANCELLED + isCancelled=false (legacy cancel-maradvány) → KIZÁRVA (változatlan);</li>
 *   <li>REJECTED + isCancelled=true + indoklás (reject()) → BENNE MARAD (FR-4) — a
 *       reject-út ugyanazt a két mezőt tölti, mint a sztornó, ezért a státusz-kivétel
 *       terhelt (ticket C1).</li>
 * </ul>
 * Shipment-oldal (D2): a CANCELLED (sztornózott) szállítmány kizárva, a DELIVERED és a
 * REJECTED változatlanul benne marad (FR-2/FR-4).</p>
 *
 * <p>SZÁNDEKOSAN NINCS {@code @EnableJpaAuditing}: a Surefire suite egy JVM-en fut
 * ({@code forkCount=1, reuseForks=true}). Az annotáció JVM-szinten aktiválja az
 * auditingot, és felülírja a későbbi TestApplication-tesztek kézzel seedelt
 * {@code createdAt} értékeit. CI-bizonyíték (PR #1635, 2026-08-18):
 * {@code HufDaybookAnnualSequenceBackfillFrK2PostgresTest.stornoRowsGetOwnSequenceInBothTables}
 * expected 1 but was 3 — az eredeti shipment {@code created_at}-je „most”-ra íródott,
 * a {@code cancelled_at} július 1-jén maradt, ezért a sztornó-események kapták az 1–2.
 * sorszámot. Precedens: {@code TransferPendingStornoPostgresTest},
 * {@code DailyClosingNineStepsFk068PostgresTest},
 * {@code EntityCreatedAtAuditingRegressionPostgresIT}. A Transfer
 * {@code applyCreatedAtFallback()} védőhálója auditing nélkül is kitölti a NOT NULL
 * {@code created_at}-et, ha a hívó nem ad értéket; ez a teszt explicit seedel.</p>
 */
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
class CashFlowReportStornoExclusionFkh030KiegPostgresTest {

    private static final LocalDate TRANSFER_DATE = LocalDate.of(2026, 8, 5);
    private static final LocalDate FROM = LocalDate.of(2026, 8, 1);
    private static final LocalDate TO = LocalDate.of(2026, 8, 31);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private TransferRepository transferRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("FR-1/FR-4: a sztornozott (COMPLETED-storno es CANCELLED-storno) transfer kizarva, a COMPLETED es a REJECTED bent marad")
    void cashFlowTransfersExcludeStornoKeepRejected() {
        Seed seed = transactionTemplate.execute(status -> seedBase("FK30T"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // 1. eset: élő COMPLETED — változatlanul egy sorban kell megjelennie (FR-3).
            saveTransfer(seed, "FF-030001", Transfer.TransferStatus.COMPLETED,
                    TRANSFER_DATE.atTime(9, 0), false, null, null);
            // 2. eset: COMPLETED-sztornó (stornoCompleted) — status MARAD COMPLETED,
            // isCancelled=true + indoklás. Teljesen kizárva (FR-1).
            saveTransfer(seed, "FF-030002", Transfer.TransferStatus.COMPLETED,
                    TRANSFER_DATE.atTime(9, 30), true, TRANSFER_DATE.atTime(11, 0), "Sztorno teszt");
            // 3. eset: PENDING-sztornó (stornoPending) — status=CANCELLED,
            // isCancelled=true + indoklás. Teljesen kizárva (FR-1).
            saveTransfer(seed, "FF-030003", Transfer.TransferStatus.CANCELLED,
                    TRANSFER_DATE.atTime(10, 0), true, TRANSFER_DATE.atTime(11, 30), "Pending sztorno");
            // 4. eset: legacy cancel()-maradvány — CANCELLED, isCancelled=false, indoklás
            // nélkül. Változatlanul kizárva (ma sem szerepel).
            saveTransfer(seed, "FF-030004", Transfer.TransferStatus.CANCELLED,
                    TRANSFER_DATE.atTime(10, 30), false, null, null);
            // 5. eset: reject() — status=REJECTED ÉS isCancelled=true + indoklás (közös
            // adatmodell a sztornóval, TransferService.reject). FR-4: változatlanul
            // megjelenik; ez a fixture a C1-csapda őre.
            saveTransfer(seed, "UF-030005", Transfer.TransferStatus.REJECTED,
                    TRANSFER_DATE.atTime(12, 0), true, TRANSFER_DATE.atTime(12, 30), "Elutasitva");
        });

        assertThat(transferRepository.findCashFlowReportTransfers(
                seed.company().getId(),
                Set.of(seed.branchA().getId(), seed.branchB().getId()),
                FROM, TO))
                .as("FKH-030 kieg. FR-1/FR-4: sztornózott transfer se eredeti, se -SZ sorként "
                        + "nem szerepel; a COMPLETED és a REJECTED bent marad")
                .extracting(Transfer::getTransferNumber)
                .containsExactlyInAnyOrder("FF-030001", "UF-030005");
    }

    @Test
    @DisplayName("FR-2/FR-4: a CANCELLED shipment kizarva, a DELIVERED es a REJECTED bent marad")
    void cashFlowShipmentsExcludeCancelledKeepRejected() {
        Seed seed = transactionTemplate.execute(status -> seedBase("FK30S"));
        assertThat(seed).isNotNull();

        transactionTemplate.executeWithoutResult(status -> {
            // Élő (DELIVERED) szállítmány — változatlanul szerepel (FR-3 analógia).
            saveShipment(seed, "SHP-DELIVERED", ShipmentRequestStatus.DELIVERED,
                    TRANSFER_DATE.atTime(9, 0), null, null);
            // Sztornózott (CANCELLED + cancelledAt) — teljesen kizárva (FR-2).
            saveShipment(seed, "SHP-CANCELLED", ShipmentRequestStatus.CANCELLED,
                    TRANSFER_DATE.atTime(9, 30), LocalDateTime.of(2026, 8, 6, 10, 0), null);
            // Elutasított (REJECTED, rejectionReason, cancelledAt nélkül) — FR-4:
            // változatlanul szerepel.
            saveShipment(seed, "SHP-REJECTED", ShipmentRequestStatus.REJECTED,
                    TRANSFER_DATE.atTime(10, 0), null, "Elutasitva");
        });

        assertThat(shipmentRequestRepository.findCashFlowReportShipments(
                seed.company().getId(),
                Set.of(seed.branchA().getId(), seed.branchB().getId()),
                FROM, TO))
                .as("FKH-030 kieg. FR-2/FR-4: a CANCELLED (sztornozott) szallitmany kizarva; "
                        + "a DELIVERED es a REJECTED bent marad")
                .extracting(ShipmentRequest::getRequestNumber)
                .containsExactlyInAnyOrder("SHP-DELIVERED", "SHP-REJECTED");
    }

    // ============================ HELPEREK ============================

    private void saveTransfer(Seed seed, String transferNumber, Transfer.TransferStatus status,
                              LocalDateTime createdAt, boolean isCancelled, LocalDateTime cancelledAt,
                              String cancellationReason) {
        transferRepository.save(Transfer.builder()
                .cancellationReason(cancellationReason)
                .transferNumber(transferNumber)
                .companyId(seed.company().getId())
                .fromBranch(seed.branchA())
                .toBranch(seed.branchB())
                .fromWorker(seed.worker())
                .transferType(Transfer.TransferType.CASH)
                .status(status)
                .transferDate(createdAt.toLocalDate())
                .transferTime(createdAt.toLocalTime())
                .currency(seed.huf())
                .amount(new BigDecimal("100000.0000"))
                .hufValue(new BigDecimal("100000.00"))
                .direction(Transfer.TransferDirection.F)
                .isCancelled(isCancelled)
                .cancelledAt(cancelledAt)
                .createdAt(createdAt)
                .build());
    }

    private void saveShipment(Seed seed, String requestNumber, ShipmentRequestStatus status,
                              LocalDateTime createdAt, LocalDateTime cancelledAt,
                              String rejectionReason) {
        ShipmentRequest shipment = ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(seed.company().getId())
                .serialPrefix("FF")
                .serialNumber(System.nanoTime())
                .fromBranchId(seed.branchA().getId())
                .toBranchId(seed.branchB().getId())
                .transferType("BRANCH_TO_BRANCH")
                .requestedById(seed.worker().getId())
                .status(status)
                .requestDate(TRANSFER_DATE)
                .carrierName("FKH-030 Carrier")
                .sealNumber("FK30-" + UUID.randomUUID().toString().substring(0, 8))
                .createdAt(createdAt)
                .build();
        shipment.setCancelledAt(cancelledAt);
        shipment.setRejectionReason(rejectionReason);
        shipmentRequestRepository.saveAndFlush(shipment);
    }

    private Seed seedBase(String tag) {
        LocalDateTime now = TRANSFER_DATE.atTime(6, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Company company = companyRepository.save(Company.builder()
                .code(tag + "-" + suffix)
                .name("FKH-030 kieg storno exclusion company")
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(tag + "-BT-" + suffix)
                .name("FKH-030 branch type")
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
                .name("FKH-030 Teszt Dolgozo")
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
                .bankCode("FK30BANK")
                .branchType(branchType)
                .name("FKH-030 Branch " + code)
                .address("Teszt utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .isActive(true)
                .openingDate(TRANSFER_DATE)
                .createdAt(now)
                .build());
    }

    private record Seed(Company company, Branch branchA, Branch branchB, Worker worker, Currency huf) {
    }
}
