package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.dto.daybook.HufDaybookRowDto;
import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferLineDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

/**
 * FR-R1..R4 — a {@code reject()} (PENDING átadás elutasítása a fogadó fiók részéről) valós
 * kassza-visszapótlást, ellentételező bizonylatot és auditot végez. <b>RED-fázis.</b>
 *
 * <h3>Miért kell</h3>
 * A {@code reject()} eddig — a megszüntetett {@code cancel()}-hez hasonlóan — CSAK státuszt
 * váltott: a create-kor lekönyvelt összeg NEM került vissza, bizonylat és audit-nyom sem
 * keletkezett. Mivel az átvétel csak {@code PENDING}/{@code IN_TRANSIT} státuszra enged, a
 * {@code REJECTED} ténylegesen lezárja a tételt — a pénz némán elvész a könyvelt oldalon.
 * (Codex kézi review, BLOCKING-osztály; a tenant/branch-guard már külön PR-ben javult.)
 *
 * <h3>Szerződés (jóváhagyott döntések)</h3>
 * <ul>
 *   <li><b>Visszapótlás:</b> a {@code reversePendingCounterTransactions} VÁLTOZATLAN
 *       újrahasználata — az irányt a {@code direction} dönti el, NEM a kezdeményező
 *       (a create ugyanazt könyvelte, akárki vonja is vissza): F/FF → {@code increase},
 *       U → {@code decrease} a ténylegesen könyvelt oldalon.</li>
 *   <li><b>Adatmodell:</b> {@code isCancelled = true} + kitöltött {@code cancellationReason} —
 *       ez kell ahhoz, hogy a HUF naplókönyv rendereljen. A meglévő predikátum
 *       ({@code status NOT IN (CANCELLED, REJECTED) OR (isCancelled AND reason IS NOT NULL)})
 *       a {@code REJECTED}-et is fedi, ezért <b>NULLA lekérdezés-változás</b> kell.</li>
 *   <li><b>Audit:</b> KÜLÖN action — {@code TRANSFER_REJECTED}, „elutasítva" szöveggel.
 *       SZÁNDÉKOSAN nem {@code STORNO}: az audit-nyom nem nevezheti sztornónak az elutasítást.</li>
 *   <li><b>Bizonylat-referencia:</b> marad {@code <sorszám>-SZ} mindkét ágon — tudatos,
 *       dokumentált kompromisszum (a {@code -SZ} négy különböző helyen él; csak az egyiket
 *       átírva inkoherens állapot állna elő). Follow-up #21.</li>
 *   <li><b>Indoklás:</b> kötelezően nem-üres ({@code normalizeStornoReason}) — a mai
 *       frontend-viselkedés szerveroldali kikényszerítése; enélkül üres indoklású sor
 *       kerülne a HUF naplókönyvbe.</li>
 * </ul>
 *
 * <p>Auditing NINCS bekapcsolva — a {@code @PrePersist} {@code created_at} védőháló (PR #1532) fedi.
 */
@Testcontainers
@Import({
        TransferService.class,
        TransferCreateDedupGuard.class,
        TransferSerialSequenceService.class,
        HufDaybookSequenceService.class,
        HufDaybookService.class
})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class TransferRejectReversalPostgresTest {

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
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private CashBalanceRepository cashBalanceRepository;
    @Autowired private TransferRepository transferRepository;
    @Autowired private TransferService transferService;
    @Autowired private HufDaybookService hufDaybookService;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private DataSource dataSource;

    @PersistenceContext private EntityManager entityManager;

    @MockitoBean private AuditLogService auditLogService;
    @MockitoBean private ReceiptSequenceService receiptSequenceService;
    @MockitoBean private VaultStockFlowService vaultStockFlowService;
    @MockitoBean private AccessScopeService accessScopeService;

    private static final BigDecimal OPENING = new BigDecimal("100000.00");
    private static final BigDecimal AMOUNT = new BigDecimal("1000.00");
    private static final BigDecimal SECOND_LINE_AMOUNT = new BigDecimal("500.00");
    private static final String REASON = "Sérült plomba — nem vesszük át";

    private final AtomicInteger receiptCounter = new AtomicInteger();

    @BeforeEach
    void setUp() {
        new ResourceDatabasePopulator(
                new ClassPathResource("db/migration/V303__transfer_serial_sequence.sql"),
                new ClassPathResource("db/migration/V360__huf_daybook_sequence.sql"))
                .execute(dataSource);
        lenient().when(receiptSequenceService.generateReceiptNumber(any(), any()))
                .thenAnswer(inv -> "R" + receiptCounter.incrementAndGet());
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @AfterEach
    void tearDownSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // =====================================================================
    // FR-R1 — irány szerinti visszapótlás
    // =====================================================================

    @Test
    @DisplayName("FR-R1/F: elutasított F átadás visszaadja a küldő fiók kasszáját")
    void reject_directionF_restoresFromBranchCashBalance() {
        Fixture fx = seed("RJF");
        TransferDto created = createAs(fx, fx.eurId(), AMOUNT, "F");

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));

        rejectAsReceiver(fx, created.getId());

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("elutasítás után a küldő fiók egyenlege a create előtti értékre áll vissza")
                .isEqualByComparingTo(OPENING);
    }

    @Test
    @DisplayName("FR-R1/U: elutasított U átvétel visszavonja a create-kori növelést (fordított előjel)")
    void reject_directionU_reversesIncreaseOnFromBranch() {
        Fixture fx = seed("RJU");
        TransferDto created = createAs(fx, fx.eurId(), AMOUNT, "U");

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.add(AMOUNT));

        rejectAsReceiver(fx, created.getId());

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("U-nál a create NÖVELT, ezért az elutasítás CSÖKKENT")
                .isEqualByComparingTo(OPENING);
    }

    @Test
    @DisplayName("FR-R1/FF: elutasított FF korrekció MINDKÉT fiók kasszáját visszaadja")
    void reject_directionFF_restoresBothBranchCashBalances() {
        Fixture fx = seed("RJFF");
        TransferDto created = createAs(fx, fx.eurId(), AMOUNT, "FF");

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));
        assertThat(balanceOf(fx.companyId(), fx.toBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));

        rejectAsReceiver(fx, created.getId());

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId())).isEqualByComparingTo(OPENING);
        assertThat(balanceOf(fx.companyId(), fx.toBranchId(), fx.eurId())).isEqualByComparingTo(OPENING);
    }

    // =====================================================================
    // FR-R3 — multi-line
    // =====================================================================

    @Test
    @DisplayName("FR-R3: elutasított multi-line átadólap MINDEN valuta-sorát visszapótolja")
    void reject_multiLineTransfer_restoresEveryCurrencyLine() {
        Fixture fx = seed("RJML");
        CreateTransferDto dto = dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F");
        dto.setLines(List.of(
                TransferLineDto.builder().currencyId(fx.eurId()).amount(AMOUNT).build(),
                TransferLineDto.builder().currencyId(fx.usdId()).amount(SECOND_LINE_AMOUNT).build()));
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());
        TransferDto created = transferService.create(dto, fx.fromWorkerId());

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.usdId()))
                .isEqualByComparingTo(OPENING.subtract(SECOND_LINE_AMOUNT));

        rejectAsReceiver(fx, created.getId());

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("EUR sor visszaáll").isEqualByComparingTo(OPENING);
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.usdId()))
                .as("USD sor is visszaáll — nem csak a header-valuta").isEqualByComparingTo(OPENING);
    }

    // =====================================================================
    // FR-R2 — bizonylat + KÜLÖN audit-action
    // =====================================================================

    @Test
    @DisplayName("FR-R2: elutasítás -SZ bizonylatot és TRANSFER_REJECTED auditot generál (NEM STORNO)")
    void reject_createsReversalTransactionAndRejectedAudit() {
        Fixture fx = seed("RJAUD");
        TransferDto created = createAs(fx, fx.eurId(), AMOUNT, "F");
        Long transferId = created.getId();
        String transferNumber = created.getTransferNumber();

        rejectAsReceiver(fx, transferId);

        assertThat(countTransactionsByReference(fx.companyId(), transferNumber + "-SZ"))
                .as("ellentételező bizonylat keletkezik (a -SZ utótag tudatosan közös a sztornóval, #21)")
                .isGreaterThanOrEqualTo(1L);

        verify(auditLogService).log(eq("TRANSFER_REJECTED"), contains("elutasítva"), eq(transferId));
        verify(auditLogService, never()).log(eq("STORNO"), contains("sztornózva"), eq(transferId));

        Transfer reloaded = reloadTransfer(transferId);
        assertThat(reloaded.getStatus()).isEqualTo(Transfer.TransferStatus.REJECTED);
        assertThat(reloaded.getIsCancelled())
                .as("a naplókönyv-megkülönböztető ezt igényli").isTrue();
        assertThat(reloaded.getCancellationReason()).isEqualTo(REASON);
    }

    // =====================================================================
    // FR-R4 — HUF naplókönyv, NULLA lekérdezés-változással
    // =====================================================================

    @Test
    @DisplayName("FR-R4: elutasított HUF tétel eredeti ÉS sztornó sorként megjelenik a naplókönyvben (lekérdezés-változás nélkül)")
    void reject_hufTransfer_appearsInDaybookWithoutQueryChange() {
        Fixture fx = seed("RJHUF");
        TransferDto created = createAs(fx, fx.hufId(), AMOUNT, "F");
        String transferNumber = created.getTransferNumber();
        assertThat(transferNumber).startsWith("FF-");

        rejectAsReceiver(fx, created.getId());

        assertThat(reloadTransfer(created.getId()).getStornoJournalSequence())
                .as("HUF tételnél az elutasítás SAJÁT naplósorszámot kap").isNotNull();

        // A naplókönyvet a FF- oldal (fromBranch) szemszögéből kérdezzük le.
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());
        HufDaybookDto daybook = hufDaybookService.getDaybook(fx.fromBranchId(), LocalDate.now());

        assertThat(daybook.getRows())
                .as("a meglévő predikátum (isCancelled + cancellationReason) a REJECTED-et is fedi — "
                        + "eredeti + sztornó sorpár, nettó nulla")
                .extracting(HufDaybookRowDto::getReceiptNumber)
                .contains(transferNumber, transferNumber + "-SZ");
    }

    // ===== Helperek =====

    private record Fixture(UUID companyId, UUID fromBranchId, UUID toBranchId,
                           Long fromWorkerId, Long toWorkerId,
                           Long hufId, Long eurId, Long usdId) {
    }

    private TransferDto createAs(Fixture fx, Long currencyId, BigDecimal amount, String direction) {
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());
        return transferService.create(dto(fx.toBranchId(), currencyId, amount, direction), fx.fromWorkerId());
    }

    /** Az elutasítás a CÉLFIÓK joga — a fogadó fiók dolgozójaként hívunk. */
    private void rejectAsReceiver(Fixture fx, Long transferId) {
        authenticateAs(fx.companyId(), fx.toBranchId(), fx.toWorkerId());
        transferService.reject(transferId, REASON, fx.toWorkerId());
    }

    private CreateTransferDto dto(UUID toBranchId, Long currencyId, BigDecimal amount, String direction) {
        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toBranchId.toString());
        dto.setCurrencyId(currencyId);
        dto.setAmount(amount);
        dto.setTransferType("CURRENCY");
        dto.setDirection(direction);
        dto.setCarrierName("Teszt Szállító");
        dto.setSealNumber("PLOMBA-001");
        return dto;
    }

    private void authenticateAs(UUID companyId, UUID branchId, Long workerId) {
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_PENZTAROS");
        auth.setDetails(new WorkerAuthenticationDetails(workerId, companyId, branchId, "PENZTAROS"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private Transfer reloadTransfer(Long id) {
        return transactionTemplate.execute(s -> transferRepository.findById(id).orElseThrow());
    }

    private BigDecimal balanceOf(UUID companyId, UUID branchId, Long currencyId) {
        return transactionTemplate.execute(s -> cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyId(branchId, currencyId, companyId)
                .orElseThrow(() -> new AssertionError("Hiányzó cash_balance sor"))
                .getCurrentBalance());
    }

    /** CÉG-SZKÓPOLT: a bizonylatszám cégenként újraindul, ezért a referencia ütközne a tesztek közt. */
    private long countTransactionsByReference(UUID companyId, String referenceNumber) {
        return transactionTemplate.execute(s -> entityManager.createQuery(
                        "SELECT COUNT(t) FROM Transaction t "
                                + "WHERE t.referenceNumber = :ref AND t.company.id = :companyId", Long.class)
                .setParameter("companyId", companyId)
                .setParameter("ref", referenceNumber)
                .getSingleResult());
    }

    private Fixture seed(String prefix) {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = prefix + "-" + System.nanoTime();

            Company company = companyRepository.save(Company.builder()
                    .code(shortCode("C", suffix)).name("reject-reversal company " + suffix)
                    .createdAt(now).build());
            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code(shortCode("BT", suffix))
                    .name("branch type").createdAt(now).build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY").code(shortCode("CO", suffix))
                    .name("Hungary").createdAt(now).build());
            Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS").code(shortCode("BS", suffix))
                    .name("Active").createdAt(now).build());

            Branch fromBranch = saveBranch(company, branchType, country, branchStatus, shortCode("BF", suffix), now);
            Branch toBranch = saveBranch(company, branchType, country, branchStatus, shortCode("BX", suffix), now);

            Worker fromWorker = saveWorker(company, fromBranch, shortCode("W1", suffix), "Küldő pénztáros", now);
            Worker toWorker = saveWorker(company, toBranch, shortCode("W2", suffix), "Fogadó pénztáros", now);

            Currency huf = currency("HUF", "Forint", "Ft", 0, 1, now);
            Currency eur = currency("EUR", "Euró", "€", 2, 2, now);
            Currency usd = currency("USD", "USA dollár", "$", 2, 3, now);

            for (Branch branch : List.of(fromBranch, toBranch)) {
                for (Currency c : List.of(huf, eur, usd)) {
                    cashBalanceRepository.save(CashBalance.builder()
                            .company(company).branch(branch).currency(c)
                            .openingBalance(OPENING).currentBalance(OPENING)
                            .createdAt(now).build());
                }
            }

            return new Fixture(company.getId(), fromBranch.getId(), toBranch.getId(),
                    fromWorker.getId(), toWorker.getId(), huf.getId(), eur.getId(), usd.getId());
        });
    }

    private Branch saveBranch(Company company, Dictionary branchType, Dictionary country,
                              Dictionary branchStatus, String code, LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code(code).company(company).bankCode("RJBANK")
                .branchType(branchType).name("Fiók " + code)
                .address("Teszt utca 1").city("Budapest").zipCode("1000")
                .country(country).branchStatus(branchStatus)
                .openingDate(LocalDate.now()).isVault(false).isActive(true)
                .createdAt(now).build());
    }

    private Worker saveWorker(Company company, Branch branch, String code, String name, LocalDateTime now) {
        return workerRepository.save(Worker.builder()
                .company(company).branch(branch).code(code).name(name)
                .passwordHash("$2a$10$test").role(WorkerRole.CASHIER).active(true)
                .createdAt(now).build());
    }

    private Currency currency(String code, String name, String symbol,
                              int decimalPlaces, int displayOrder, LocalDateTime now) {
        return currencyRepository.findByCode(code)
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code(code).name(name).symbol(symbol)
                        .decimalPlaces(decimalPlaces).active(true).displayOrder(displayOrder)
                        .createdAt(now).build()));
    }

    private static String shortCode(String kind, String suffix) {
        String digits = suffix.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return kind + tail;
    }
}
