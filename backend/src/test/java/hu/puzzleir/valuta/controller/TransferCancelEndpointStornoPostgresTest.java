package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
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
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.HufDaybookSequenceService;
import hu.puzzleir.valuta.service.ReceiptSequenceService;
import hu.puzzleir.valuta.service.TransferCreateDedupGuard;
import hu.puzzleir.valuta.service.TransferSerialSequenceService;
import hu.puzzleir.valuta.service.TransferService;
import hu.puzzleir.valuta.service.VaultStockFlowService;
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
import org.springframework.http.MediaType;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * BLOCKING-fix regresszió: a {@code POST /api/v1/transfers/{id}/cancel} végpont a BIZTONSÁGOS
 * sztornó-útvonalra irányít — ENDPOINT (HTTP) szinten igazolva.
 *
 * <h3>Miért kell külön ettől a service-teszttől</h3>
 * A {@code TransferPendingStornoPostgresTest} a {@code TransferService.storno(...)} metódust
 * hívja közvetlenül. A Codex-review BLOCKING leletének lényege viszont épp az volt, hogy a
 * RÉGI, néma {@code /cancel} VÉGPONT élt tovább, és az éles kliens azt hívta — vagyis a
 * biztonságos útvonal a gyakorlatban sosem érvényesült. Ez a teszt ezért ott mér, ahol a
 * kliens is belép: a controller-metóduson, JSON request body-val, {@code MockMvc}-vel
 * (a repo {@code standaloneSetup} mintája szerint).
 *
 * <p>A korábbi {@code TransferService.cancel(Long)} törölve; a végpont most kötelező
 * indoklást vár ({@code StornoRequestDto}) és a {@code storno} diszpécserre megy, amely
 * PENDING-nél a {@code stornoPending} ágra fut.
 *
 * <p>Külső határfelületek mockolva: {@code AuditLogService} (egyben az audit-assert megfigyelője),
 * {@code ReceiptSequenceService}, {@code VaultStockFlowService} (nem-vault fióknál amúgy is no-op),
 * {@code AccessScopeService}. A cash_balance, a bizonylat-tábla, a sorszám-szolgáltatások és a
 * Postgres valósak. Auditing NINCS bekapcsolva — a {@code @PrePersist} védőháló (PR #1532) fedi.
 */
@Testcontainers
@Import({
        TransferController.class,
        TransferService.class,
        TransferCreateDedupGuard.class,
        TransferSerialSequenceService.class,
        HufDaybookSequenceService.class
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
class TransferCancelEndpointStornoPostgresTest {

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
    @Autowired private TransferController transferController;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private DataSource dataSource;

    @PersistenceContext private EntityManager entityManager;

    @MockitoBean private AuditLogService auditLogService;
    @MockitoBean private ReceiptSequenceService receiptSequenceService;
    @MockitoBean private VaultStockFlowService vaultStockFlowService;
    @MockitoBean private AccessScopeService accessScopeService;

    private MockMvc mockMvc;

    private static final BigDecimal OPENING = new BigDecimal("100000.00");
    private static final BigDecimal AMOUNT = new BigDecimal("1000.00");

    private final AtomicInteger receiptCounter = new AtomicInteger();

    @BeforeEach
    void setUp() {
        // A két sorszám-tábla nem JPA-entitás (natív SQL-lel írt Flyway-tábla) — a migrációt
        // magát futtatjuk, a TransferSerialSequenceServicePostgresIT bevált mintája szerint.
        new ResourceDatabasePopulator(
                new ClassPathResource("db/migration/V303__transfer_serial_sequence.sql"),
                new ClassPathResource("db/migration/V360__huf_daybook_sequence.sql"))
                .execute(dataSource);

        lenient().when(receiptSequenceService.generateReceiptNumber(any(), any()))
                .thenAnswer(inv -> "R" + receiptCounter.incrementAndGet());
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        // A repo bevált controller-teszt mintája (standaloneSetup) — valós JSON-binding és
        // @Valid-kikényszerítés, a kliens belépési pontjával azonos szinten.
        mockMvc = MockMvcBuilders.standaloneSetup(transferController).build();
    }

    @AfterEach
    void tearDownSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("BLOCKING-fix: POST /transfers/{id}/cancel valós kassza-visszapótlást, -SZ bizonylatot és STORNO auditot eredményez")
    void cancelEndpoint_pendingTransfer_restoresCashCreatesReversalAndAudit() throws Exception {
        Fixture fx = seed("CEP-OK");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());
        Long transferId = created.getId();
        String transferNumber = created.getTransferNumber();

        // Előfeltétel: az F create MÁR levonta a küldő kasszájából.
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));

        mockMvc.perform(post("/api/v1/transfers/{id}/cancel", transferId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"Beragadt tétel visszavonása\"}"))
                .andExpect(status().isNoContent());

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("a /cancel végpont MOSTANTÓL visszapótolja a küldő fiók kasszáját "
                        + "(a régi, néma útvonal ezt sosem tette)")
                .isEqualByComparingTo(OPENING);

        assertThat(countTransactionsByReference(fx.companyId(), transferNumber + "-SZ"))
                .as("ellentételező bizonylat keletkezik a végponton keresztül is")
                .isGreaterThanOrEqualTo(1L);

        verify(auditLogService).log(eq("STORNO"), contains("VV-TX-002"), eq(transferId));

        Transfer reloaded = transactionTemplate.execute(s ->
                transferRepository.findById(transferId).orElseThrow());
        assertThat(reloaded.getIsCancelled()).isTrue();
        assertThat(reloaded.getCancellationReason()).isEqualTo("Beragadt tétel visszavonása");
        assertThat(reloaded.getStatus())
                .as("a visszavont tétel kikerül a munkafolyamatból (receive/pending-listák a státuszra szűrnek)")
                .isEqualTo(Transfer.TransferStatus.CANCELLED);
    }

    @Test
    @DisplayName("BLOCKING-fix: indoklás nélküli /cancel hívás elutasított — nincs visszapótlás, nincs bizonylat")
    void cancelEndpoint_blankReason_isRejectedWithoutSideEffects() throws Exception {
        Fixture fx = seed("CEP-NORE");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());
        String transferNumber = created.getTransferNumber();

        mockMvc.perform(post("/api/v1/transfers/{id}/cancel", created.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"   \"}"))
                .andExpect(status().isBadRequest());

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("elutasított hívás NEM pótolhat vissza kasszát")
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));
        assertThat(countTransactionsByReference(fx.companyId(), transferNumber + "-SZ"))
                .as("elutasított hívás NEM generálhat ellentételező bizonylatot")
                .isZero();
    }

    // ===== Helperek =====

    private record Fixture(UUID companyId, UUID fromBranchId, UUID toBranchId,
                           Long fromWorkerId, Long eurId) {
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

    private BigDecimal balanceOf(UUID companyId, UUID branchId, Long currencyId) {
        return transactionTemplate.execute(status -> cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyId(branchId, currencyId, companyId)
                .orElseThrow(() -> new AssertionError("Hiányzó cash_balance sor"))
                .getCurrentBalance());
    }

    /** CÉG-SZKÓPOLT: a bizonylatszám cégenként újraindul, ezért a referencia ütközne a tesztek közt. */
    private long countTransactionsByReference(UUID companyId, String referenceNumber) {
        return transactionTemplate.execute(status -> entityManager.createQuery(
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
                    .code(shortCode("C", suffix))
                    .name("cancel-endpoint company " + suffix)
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code(shortCode("BT", suffix))
                    .name("branch type").createdAt(now).build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY").code(shortCode("CO", suffix))
                    .name("Hungary").createdAt(now).build());
            Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS").code(shortCode("BS", suffix))
                    .name("Active").createdAt(now).build());

            Branch fromBranch = saveBranch(company, branchType, country, branchStatus,
                    shortCode("BF", suffix), now);
            Branch toBranch = saveBranch(company, branchType, country, branchStatus,
                    shortCode("BX", suffix), now);

            Worker worker = workerRepository.save(Worker.builder()
                    .company(company).branch(fromBranch)
                    .code(shortCode("W", suffix))
                    .name("Küldő pénztáros")
                    .passwordHash("$2a$10$test")
                    .role(WorkerRole.CASHIER)
                    .active(true)
                    .createdAt(now)
                    .build());

            Currency eur = currencyRepository.findByCode("EUR")
                    .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                            .code("EUR").name("Euró").symbol("€")
                            .decimalPlaces(2).active(true).displayOrder(2)
                            .createdAt(now).build()));

            for (Branch branch : java.util.List.of(fromBranch, toBranch)) {
                cashBalanceRepository.save(CashBalance.builder()
                        .company(company).branch(branch).currency(eur)
                        .openingBalance(OPENING).currentBalance(OPENING)
                        .createdAt(now).build());
            }

            return new Fixture(company.getId(), fromBranch.getId(), toBranch.getId(),
                    worker.getId(), eur.getId());
        });
    }

    private Branch saveBranch(Company company, Dictionary branchType, Dictionary country,
                              Dictionary branchStatus, String code, LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code(code).company(company).bankCode("CEPBANK")
                .branchType(branchType).name("Fiók " + code)
                .address("Teszt utca 1").city("Budapest").zipCode("1000")
                .country(country).branchStatus(branchStatus)
                .openingDate(LocalDate.now()).isVault(false)
                .createdAt(now).build());
    }

    private static String shortCode(String kind, String suffix) {
        String digits = suffix.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return kind + tail;
    }
}
