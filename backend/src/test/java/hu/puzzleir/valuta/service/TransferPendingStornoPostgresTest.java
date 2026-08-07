package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.dto.transfer.TransferLineDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.exception.ValidationException;
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
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

/**
 * FR-P1..P7 — PENDING átadás-átvétel sztornózásának egységesítése, valós PostgreSQL-en
 * (Testcontainers). <b>RED-fázis</b>: az implementáció még NEM készült el.
 *
 * <h3>Szerződés (Fázis 0 + kiegészítő Fázis 0 döntései)</h3>
 * <ul>
 *   <li><b>D1 — hatókör:</b> {@code F}, {@code U}, {@code FF} irányú átadás create után
 *       PENDING marad ({@code TransferService:160}, a COMPLETED-re váltás csak a
 *       {@code case UF} ágon van, {@code TransferService:603}). Mindhárom könyvelt a
 *       create-kor, tehát mindhármat vissza kell fordítani. Az {@code UF} nem érintett.</li>
 *   <li><b>D2 — audit:</b> a MEGLÉVŐ storno audit-hívás változatlanul
 *       ({@code auditLogService.log("STORNO", "VV-TX-002: ...", Long entityId)}),
 *       NEM új formátum, NEM KAT=TX JSON.</li>
 *   <li><b>D3 — fiók-hatókör:</b> a PENDING-ág megtartja a mai {@code cancel}
 *       {@code fromBranch}-only guardját ({@code TransferService:331-334}) — a storno
 *       cég-szintű, fiók-korlát nélküli modellje NEM kerül át.</li>
 * </ul>
 *
 * <h3>Miért a {@code storno(id, reason)} a belépési pont?</h3>
 * A UI EGY végpontot hív ({@code POST /transfers/{id}/storno}), és a döntés szerint egy
 * vékony, státusz alapján elágazó diszpécser mögé kerül a két külön útvonal (COMPLETED:
 * változatlan; PENDING: új {@code stornoPending}). A tesztek ezért a MEGLÉVŐ, publikus
 * {@code storno(...)} API-t hívják — így ma is FORDULNAK, és viselkedésre buknak. Egy még
 * nem létező {@code stornoPending(...)} metódusra írt teszt fordítási hibát adna, ami nem
 * viselkedési RED-bizonyíték, és a teljes teszt-modul fordítását megakasztaná.
 *
 * <h3>Jelenlegi (RED) bukási ok</h3>
 * A {@code storno} státusz-guardja ({@code TransferService:372-375}) minden nem-COMPLETED
 * bizonylatot elutasít:
 * <pre>ValidationException: "Csak véglegesített (lezárt) átadás-átvétel bizonylat
 * sztornózható. Függőben lévő bizonylatot a törlés (cancel) kezel."</pre>
 * Ez a hiba maga. Tesztet a bukás elfedésére módosítani TILOS.
 *
 * <h3>Infrastruktúra-megjegyzés — miért NINCS itt {@code @EnableJpaAuditing}</h3>
 * A {@code Transfer.createdAt} és a {@code Transaction.createdAt} egyaránt
 * {@code @CreatedDate} + {@code nullable = false}, és a {@code TransferService} egyiket sem
 * tölti kézzel — a {@code TestApplication}-kontextusokban pedig szándékosan nincs auditing.
 * Ezt a rést a {@code Transfer}/{@code Transaction} entitásokra felvett
 * {@code @PrePersist applyCreatedAtFallback()} védőháló zárja be (PR #1532), így ez az osztály
 * auditing NÉLKÜL is végig tudja futtatni a valós {@code create()} → {@code storno()} utat.
 *
 * <p><b>Auditingot bekapcsolni itt TILOS.</b> A Surefire alapértelmezetten
 * {@code forkCount=1, reuseForks=true} mellett fut, tehát minden tesztosztály egy JVM-en
 * osztozik: egy {@code @EnableJpaAuditing}-et hordozó {@code *Test} JVM-szinten aktiválja az
 * auditingot és felülírja a suite kézzel seedelt {@code createdAt} értékeit. Ez mérhetően
 * 7 idegen teszt bukását okozta 3 osztályban ({@code ShipmentHandlingFeeRepositoryTest},
 * {@code HufDaybookUnifiedListFrK6PostgresTest},
 * {@code HufDaybookAnnualSequenceBackfillFrK2PostgresTest}) a PR #1531 egy korábbi futásán.
 * A {@code ShipmentHandlingFeeIsolationPostgresIT} azért élhet vele, mert {@code *IT} — a CI
 * kizárólag {@code *Test}-et futtat, tehát az soha nem fut együtt a suite-tal.
 *
 * <p>Külső határfelületek mockolva: {@code AuditLogService} (egyben az FR-P2 megfigyelője),
 * {@code ReceiptSequenceService}, {@code VaultStockFlowService} (nem-vault fiókoknál
 * amúgy is no-op), {@code AccessScopeService}. Minden más — repository-k, sorszám-
 * szolgáltatások, cash-lock, Postgres — valós.
 */
@Testcontainers
@Import({
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
class TransferPendingStornoPostgresTest {

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
    private static final String REASON = "Beragadt tétel visszavonása";

    private final AtomicInteger receiptCounter = new AtomicInteger();

    /**
     * A két sorszám-tábla ({@code transfer_serial_sequence}, {@code huf_daybook_sequence}) nem
     * JPA-entitás, hanem natív SQL-lel írt Flyway-tábla — {@code ddl-auto} nem hozza létre.
     * A {@code TransferSerialSequenceServicePostgresIT} bevált mintája szerint a migrációs
     * fájlt magát futtatjuk (egyetlen igazságforrás, nem kézzel másolt DDL). Mindkét szkript
     * idempotens ({@code CREATE TABLE IF NOT EXISTS} + {@code ON CONFLICT}).
     */
    @BeforeEach
    void setUp() {
        new ResourceDatabasePopulator(
                new ClassPathResource("db/migration/V303__transfer_serial_sequence.sql"),
                new ClassPathResource("db/migration/V360__huf_daybook_sequence.sql"))
                .execute(dataSource);

        lenient().when(receiptSequenceService.generateReceiptNumber(any(), any()))
                .thenAnswer(inv -> "R" + receiptCounter.incrementAndGet());
        // Központi szkóp — nincs region-szűkítés (a territory-guard nem tárgya ennek a körnek).
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @AfterEach
    void tearDownSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // =====================================================================
    // FR-P1 — a create-kori könyvelés visszafordítása (RED)
    // =====================================================================

    @Test
    @DisplayName("FR-P1/F: PENDING F átadás sztornója visszaadja a küldő fiók kasszáját")
    void pendingStorno_directionF_restoresFromBranchCashBalance() {
        Fixture fx = seed("P1F");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());

        // Előfeltétel: az F create MÁR levonta a küldő kasszájából (TransferService:582).
        assertThat(statusOf(created.getId())).isEqualTo(Transfer.TransferStatus.PENDING);
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));

        assertThatCode(() -> transferService.storno(created.getId(), REASON))
                .doesNotThrowAnyException();

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("F-sztornó után a küldő fiók egyenlege a create előtti értékre áll vissza")
                .isEqualByComparingTo(OPENING);
    }

    @Test
    @DisplayName("FR-P1/U: PENDING U átvétel sztornója visszavonja a fogadó fiók növelését (fordított előjel)")
    void pendingStorno_directionU_reversesIncreaseOnFromBranch() {
        Fixture fx = seed("P1U");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "U"), fx.fromWorkerId());

        // Előfeltétel: az U create NÖVELTE a fromBranch kasszáját (TransferService:589) —
        // a sztornónak tehát csökkentenie kell, nem növelnie.
        assertThat(statusOf(created.getId())).isEqualTo(Transfer.TransferStatus.PENDING);
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.add(AMOUNT));

        assertThatCode(() -> transferService.storno(created.getId(), REASON))
                .doesNotThrowAnyException();

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("U-sztornó után a fogadó fiók egyenlege a create előtti értékre áll vissza")
                .isEqualByComparingTo(OPENING);
    }

    // =====================================================================
    // FKH-028 kiegeszites (A resz) — FR-A1/A2/A3: az EREDETI tranzakcio statusza
    // =====================================================================

    @Test
    @DisplayName("FR-A1/F: PENDING F sztornó után az eredeti TRANSFER_OUT tranzakció REVERSED")
    void pendingStorno_directionF_marksOriginalTransactionReversed() {
        Fixture fx = seed("A1F");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());
        String transferNumber = created.getTransferNumber();

        // Elofeltetel: a create COMPLETED tranzakciot hozott letre — ez latszott
        // "Feltoltve"-kent a Tranzakciolistaban a visszavonas UTAN is (a hiba lenyege).
        assertThat(originalTxStatuses(fx.companyId(), transferNumber))
                .as("create utan az eredeti tranzakcio COMPLETED")
                .containsExactly(TransactionStatus.COMPLETED);

        transferService.storno(created.getId(), REASON);

        assertThat(originalTxStatuses(fx.companyId(), transferNumber))
                .as("FR-A1: a visszavonas utan az eredeti tranzakcio REVERSED (megjelenitve: Sztornozott)")
                .containsExactly(TransactionStatus.REVERSED);
    }

    @Test
    @DisplayName("FR-A1/FF: PENDING FF sztornó után MINDKÉT eredeti tranzakció REVERSED")
    void pendingStorno_directionFF_marksBothOriginalTransactionsReversed() {
        Fixture fx = seed("A1FF");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "FF"), fx.fromWorkerId());
        String transferNumber = created.getTransferNumber();

        // Az FF create MINDKET fioknal letrehoz egy-egy TRANSFER_OUT-ot, azonos
        // referenceNumber-rel — ezert szur a repository ceg+referencia szerint, nem branch+tipus.
        assertThat(originalTxStatuses(fx.companyId(), transferNumber))
                .as("FF create ket eredeti tranzakciot hoz letre")
                .containsExactly(TransactionStatus.COMPLETED, TransactionStatus.COMPLETED);

        transferService.storno(created.getId(), REASON);

        assertThat(originalTxStatuses(fx.companyId(), transferNumber))
                .as("FR-A1: FF-nel MINDKET eredeti tranzakcio REVERSED lesz")
                .containsExactly(TransactionStatus.REVERSED, TransactionStatus.REVERSED);
    }

    @Test
    @DisplayName("FR-A3: a kompenzáló -SZ tranzakció COMPLETED marad, a kassza-egyenleg helyreáll")
    void pendingStorno_doesNotReverseCompensatingTransaction() {
        Fixture fx = seed("A3F");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());
        String transferNumber = created.getTransferNumber();

        transferService.storno(created.getId(), REASON);

        // Kontroll-teszt: ha a statusz-iras tul tag szurest hasznalna (pl. LIKE a
        // referenceNumber-re), a frissen letrehozott kompenzalo sort is REVERSED-de tenne —
        // ami elrejtene a visszapotlast a forgalombol.
        assertThat(compensatingTxStatuses(fx.companyId(), transferNumber))
                .as("FR-A3: a -SZ kompenzalo tranzakcio ERINTETLEN marad")
                .isNotEmpty()
                .containsOnly(TransactionStatus.COMPLETED);

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("FR-A3: a kassza-egyenleg pontosan ugyanugy all helyre, mint a javitas elott")
                .isEqualByComparingTo(OPENING);
    }

    @Test
    @DisplayName("FR-P1/FF: PENDING FF korrekció sztornója MINDKÉT fiók kasszáját visszaadja")
    void pendingStorno_directionFF_restoresBothBranchCashBalances() {
        Fixture fx = seed("P1FF");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "FF"), fx.fromWorkerId());

        // Előfeltétel: az FF create MINDKÉT oldalról levont (TransferService:614-615).
        assertThat(statusOf(created.getId())).isEqualTo(Transfer.TransferStatus.PENDING);
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));
        assertThat(balanceOf(fx.companyId(), fx.toBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));

        assertThatCode(() -> transferService.storno(created.getId(), REASON))
                .doesNotThrowAnyException();

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("FF-sztornó után a küldő fiók egyenlege visszaáll")
                .isEqualByComparingTo(OPENING);
        assertThat(balanceOf(fx.companyId(), fx.toBranchId(), fx.eurId()))
                .as("FF-sztornó után a cél fiók egyenlege is visszaáll")
                .isEqualByComparingTo(OPENING);
    }

    @Test
    @DisplayName("FR-P1/multi-line: PENDING F átadólap MINDEN valuta-sorát visszaadja (effectiveLines)")
    void pendingStorno_multiLineTransfer_restoresEveryCurrencyLine() {
        Fixture fx = seed("P1ML");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        CreateTransferDto dto = dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F");
        // A header az ELSŐ sort tükrözi (Transfer.java:97-100); a könyvelés soronként megy.
        dto.setLines(List.of(
                TransferLineDto.builder().currencyId(fx.eurId()).amount(AMOUNT).build(),
                TransferLineDto.builder().currencyId(fx.usdId()).amount(SECOND_LINE_AMOUNT).build()));

        TransferDto created = transferService.create(dto, fx.fromWorkerId());

        assertThat(statusOf(created.getId())).isEqualTo(Transfer.TransferStatus.PENDING);
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.usdId()))
                .isEqualByComparingTo(OPENING.subtract(SECOND_LINE_AMOUNT));

        assertThatCode(() -> transferService.storno(created.getId(), REASON))
                .doesNotThrowAnyException();

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("multi-line sztornó: az EUR sor visszaáll")
                .isEqualByComparingTo(OPENING);
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.usdId()))
                .as("multi-line sztornó: a USD sor is visszaáll (nem csak a header-valuta)")
                .isEqualByComparingTo(OPENING);
    }

    // =====================================================================
    // FR-P2 — ellentételező bizonylat + a MEGLÉVŐ audit-minta (RED)
    // =====================================================================

    @Test
    @DisplayName("FR-P2: PENDING sztornó ellentételező bizonylatot (-SZ) és a meglévő STORNO audit-hívást generálja")
    void pendingStorno_createsReversalTransactionAndReusesExistingAuditCall() {
        Fixture fx = seed("P2");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());
        Long transferId = created.getId();
        String transferNumber = created.getTransferNumber();

        assertThatCode(() -> transferService.storno(transferId, REASON))
                .doesNotThrowAnyException();

        assertThat(countTransactionsByReference(fx.companyId(), transferNumber + "-SZ"))
                .as("a createReversalTransaction mintája szerint <sorszám>-SZ referenciájú bizonylat keletkezik")
                .isGreaterThanOrEqualTo(1L);

        // D2: a COMPLETED-ág audit-hívása VÁLTOZATLANUL (3-argumentumú Long overload,
        // entityType="SYSTEM", hash-lánc automatikus) — nem új formátum.
        verify(auditLogService).log(eq("STORNO"), contains("VV-TX-002"), eq(transferId));
    }

    // =====================================================================
    // FR-P3 — kötelező indoklás (RED)
    // =====================================================================

    @Test
    @DisplayName("FR-P3: PENDING sztornó üres indoklással elutasított (normalizeStornoReason)")
    void pendingStorno_blankReason_isRejected() {
        Fixture fx = seed("P3");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());

        assertThatThrownBy(() -> transferService.storno(created.getId(), "   "))
                .isInstanceOf(ValidationException.class)
                .as("a PENDING-ág ugyanazt a normalizeStornoReason validációt futtatja, mint a COMPLETED")
                .hasMessageContaining("indoklása kötelező");
    }

    // =====================================================================
    // FR-P4 — fromBranch-only fiók-guard (D3) (RED)
    // =====================================================================

    @Test
    @DisplayName("FR-P4: idegen fiók dolgozója NEM sztornózhat PENDING átadást — nincs visszapótlás, nincs bizonylat")
    void pendingStorno_foreignBranchWorker_isRejectedWithoutSideEffects() {
        Fixture fx = seed("P4");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());
        String transferNumber = created.getTransferNumber();

        // Azonos cég, de MÁSIK fiók dolgozója — a cég-guardon átjut, a fiók-guardnak kell fognia.
        authenticateAs(fx.companyId(), fx.otherBranchId(), fx.otherWorkerId());

        assertThatThrownBy(() -> transferService.storno(created.getId(), REASON))
                .isInstanceOf(ValidationException.class)
                .as("D3: a PENDING-ág megtartja a mai cancel fromBranch-only guardját")
                .hasMessageContaining("küldő fiók");

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("elutasított sztornó NEM pótolhat vissza kasszát")
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));
        assertThat(countTransactionsByReference(fx.companyId(), transferNumber + "-SZ"))
                .as("elutasított sztornó NEM generálhat ellentételező bizonylatot")
                .isZero();
        verify(auditLogService, never()).log(eq("STORNO"), contains("VV-TX-002"), eq(created.getId()));
    }

    // =====================================================================
    // FR-P5 / FR-P6 — ZÖLD regressziós őrszemek (ma is átmennek)
    // =====================================================================

    @Test
    @DisplayName("FR-P5 [zöld őrszem]: már sztornózott PENDING átadás újra-sztornózása idempotensen elutasított")
    void alreadyCancelledPendingTransfer_secondStornoIsRejected() {
        Fixture fx = seed("P5");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());

        // Egy korábbi sztornó eredményének szimulálása: a bizonylat megjelölve, a státusz PENDING.
        transactionTemplate.executeWithoutResult(status -> {
            Transfer t = transferRepository.findById(created.getId()).orElseThrow();
            t.setIsCancelled(true);
            t.setCancelledAt(LocalDateTime.now());
            t.setCancellationReason("Korábbi sztornó");
            transferRepository.save(t);
        });

        BigDecimal balanceBefore = balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId());

        assertThatThrownBy(() -> transferService.storno(created.getId(), REASON))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("VV-TX-003");

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("nincs dupla visszapótlás")
                .isEqualByComparingTo(balanceBefore);
        assertThat(countTransactionsByReference(fx.companyId(), created.getTransferNumber() + "-SZ"))
                .as("nincs dupla ellentételező bizonylat")
                .isZero();
    }

    @Test
    @DisplayName("FR-P6 [zöld őrszem]: UF átadás create-kor COMPLETED — a PENDING-út nem érinti, a COMPLETED-storno változatlan")
    void ufTransfer_isCompletedOnCreate_andExistingCompletedStornoStillWorks() {
        Fixture fx = seed("P6");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "UF"), fx.fromWorkerId());

        // A PENDING-specifikus útvonal SOHA nem alkalmazható UF-re: a create azonnal lezárja.
        assertThat(statusOf(created.getId()))
                .as("UF create-kor COMPLETED (TransferService:603) — nem PENDING")
                .isEqualTo(Transfer.TransferStatus.COMPLETED);
        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.subtract(AMOUNT));
        assertThat(balanceOf(fx.companyId(), fx.toBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING.add(AMOUNT));

        assertThatCode(() -> transferService.storno(created.getId(), REASON))
                .doesNotThrowAnyException();

        assertThat(balanceOf(fx.companyId(), fx.fromBranchId(), fx.eurId()))
                .as("a meglévő COMPLETED-storno viselkedése változatlan")
                .isEqualByComparingTo(OPENING);
        assertThat(balanceOf(fx.companyId(), fx.toBranchId(), fx.eurId()))
                .isEqualByComparingTo(OPENING);
    }

    // =====================================================================
    // FR-P7 — HUF naplókönyv sorszám (RED) — a páros a bizonyíték
    // =====================================================================

    @Test
    @DisplayName("FR-P7/HUF: PENDING HUF átadás (FF- prefix) sztornója kioszt storno naplósorszámot")
    void pendingStorno_hufTransfer_assignsStornoJournalSequence() {
        Fixture fx = seed("P7H");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.hufId(), AMOUNT, "F"), fx.fromWorkerId());

        // A prefix VALUTA + IRÁNY alapú (TransferService:1041-1050): HUF + nem-U → "FF-".
        // Vigyázat: az "FF-" prefix NEM az FF IRÁNYT jelenti — itt F irányú, HUF-os tétel.
        assertThat(created.getTransferNumber())
                .as("HUF átadás bizonylatszáma FF- prefixű, tehát naplókönyvi tétel")
                .startsWith("FF-");

        assertThatCode(() -> transferService.storno(created.getId(), REASON))
                .doesNotThrowAnyException();

        assertThat(reloadTransfer(created.getId()).getStornoJournalSequence())
                .as("HUF tételnél a sztornó SAJÁT naplósorszámot kap (TransferService:391-394) — "
                        + "kimaradása csendes lyukat üt a HUF naplókönyv sorszámozásában")
                .isNotNull();
    }

    @Test
    @DisplayName("FR-P7/deviza: PENDING deviza átadás (AT- prefix) sztornója NEM oszt ki naplósorszámot")
    void pendingStorno_foreignCurrencyTransfer_doesNotAssignStornoJournalSequence() {
        Fixture fx = seed("P7D");
        authenticateAs(fx.companyId(), fx.fromBranchId(), fx.fromWorkerId());

        TransferDto created = transferService.create(
                dto(fx.toBranchId(), fx.eurId(), AMOUNT, "F"), fx.fromWorkerId());

        assertThat(created.getTransferNumber())
                .as("deviza átadás bizonylatszáma AT- prefixű, tehát NEM naplókönyvi tétel")
                .startsWith("AT-");

        assertThatCode(() -> transferService.storno(created.getId(), REASON))
                .doesNotThrowAnyException();

        assertThat(reloadTransfer(created.getId()).getStornoJournalSequence())
                .as("deviza tételnél nem szabad naplósorszámot kiosztani — a HUF-esettel "
                        + "való különbségtétel bizonyítja, hogy a feltétel helyesen szűr")
                .isNull();
    }

    // =====================================================================
    // Helperek
    // =====================================================================

    private record Fixture(UUID companyId, UUID fromBranchId, UUID toBranchId, UUID otherBranchId,
                           Long fromWorkerId, Long otherWorkerId, Long hufId, Long eurId, Long usdId) {
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
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(workerId, companyId, branchId, "PENZTAROS");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_PENZTAROS");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private Transfer.TransferStatus statusOf(Long transferId) {
        return reloadTransfer(transferId).getStatus();
    }

    /**
     * FKH-028/A: az adott bizonylathoz tartozo EREDETI tranzakciok statuszai.
     * A {@code -SZ} kompenzalo sort a referenceNumber-egyenloseg kizarja.
     */
    private java.util.List<hu.puzzleir.valuta.entity.TransactionStatus> originalTxStatuses(
            UUID companyId, String transferNumber) {
        return transactionTemplate.execute(status -> entityManager.createQuery(
                        "SELECT t.status FROM Transaction t "
                                + "WHERE t.company.id = :companyId AND t.referenceNumber = :ref",
                        hu.puzzleir.valuta.entity.TransactionStatus.class)
                .setParameter("companyId", companyId)
                .setParameter("ref", transferNumber)
                .getResultList());
    }

    /** FKH-028/A: a kompenzalo {@code -SZ} tranzakciok statuszai (ezek NEM valhatnak REVERSED-de). */
    private java.util.List<hu.puzzleir.valuta.entity.TransactionStatus> compensatingTxStatuses(
            UUID companyId, String transferNumber) {
        return transactionTemplate.execute(status -> entityManager.createQuery(
                        "SELECT t.status FROM Transaction t "
                                + "WHERE t.company.id = :companyId AND t.referenceNumber = :ref",
                        hu.puzzleir.valuta.entity.TransactionStatus.class)
                .setParameter("companyId", companyId)
                .setParameter("ref", transferNumber + "-SZ")
                .getResultList());
    }

    private Transfer reloadTransfer(Long transferId) {
        return transactionTemplate.execute(status ->
                transferRepository.findById(transferId).orElseThrow());
    }

    private BigDecimal balanceOf(UUID companyId, UUID branchId, Long currencyId) {
        return transactionTemplate.execute(status -> cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyId(branchId, currencyId, companyId)
                .orElseThrow(() -> new AssertionError(
                        "Hiányzó cash_balance sor: branch=" + branchId + ", currency=" + currencyId))
                .getCurrentBalance());
    }

    /**
     * JPQL-lel (nem natív SQL-lel) — a {@code transaction} táblanév SQL-kulcsszó-ütközését elkerülve.
     *
     * <p><b>CÉG-SZKÓPOLT, és ez nem opcionális.</b> A bizonylatszám cégenként újraindul
     * ({@code transfer_serial_sequence} kulcsa {@code (company_id, prefix)}), minden teszt pedig
     * friss céget seedel — így MINDEN teszt első EUR-átadása {@code AT-000001}, a referencia
     * {@code AT-000001-SZ} tehát ütközik a tesztmetódusok között. Cég-szűrés nélkül az FR-P5
     * {@code isZero()} assertje 2-t látott az FR-P6 sikeres sztornójának ellentételező
     * bizonylataiból (CI-futás 30644512648). Közös helper hibája volt, ezért mindhárom hívóhely
     * (FR-P2, FR-P4, FR-P5) egyszerre kapta meg a szűrést.
     */
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
                    .name("FR-P Company " + suffix)
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code(shortCode("BT", suffix))
                    .name("FR-P branch type").createdAt(now).build());
            Dictionary country = dictionaryRepository.save(Dictionary.builder()
                    .category("COUNTRY").code(shortCode("CO", suffix))
                    .name("Hungary").createdAt(now).build());
            Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_STATUS").code(shortCode("BS", suffix))
                    .name("Active").createdAt(now).build());

            // Mindhárom fiók SZÁNDÉKOSAN nem-vault: az A-nyom (PENDING-sztornó) izolált marad
            // a külön feltárt vault/cash_balance hibától.
            Branch fromBranch = saveBranch(company, branchType, country, branchStatus,
                    shortCode("BF", suffix), "Küldő fiók", now);
            Branch toBranch = saveBranch(company, branchType, country, branchStatus,
                    shortCode("BX", suffix), "Cél fiók", now);
            Branch otherBranch = saveBranch(company, branchType, country, branchStatus,
                    shortCode("BO", suffix), "Idegen fiók", now);

            Worker fromWorker = saveWorker(company, fromBranch, shortCode("W1", suffix), "Küldő pénztáros", now);
            Worker otherWorker = saveWorker(company, otherBranch, shortCode("W2", suffix), "Idegen pénztáros", now);

            Currency huf = currency("HUF", "Forint", "Ft", 0, 1, now);
            Currency eur = currency("EUR", "Euró", "€", 2, 2, now);
            Currency usd = currency("USD", "USA dollár", "$", 2, 3, now);

            for (Branch branch : List.of(fromBranch, toBranch, otherBranch)) {
                for (Currency currency : List.of(huf, eur, usd)) {
                    cashBalanceRepository.save(CashBalance.builder()
                            .company(company)
                            .branch(branch)
                            .currency(currency)
                            .openingBalance(OPENING)
                            .currentBalance(OPENING)
                            .createdAt(now)
                            .build());
                }
            }

            return new Fixture(company.getId(), fromBranch.getId(), toBranch.getId(), otherBranch.getId(),
                    fromWorker.getId(), otherWorker.getId(), huf.getId(), eur.getId(), usd.getId());
        });
    }

    private Branch saveBranch(Company company, Dictionary branchType, Dictionary country,
                              Dictionary branchStatus, String code, String name, LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code(code)
                .company(company)
                .bankCode("FRPBANK")
                .branchType(branchType)
                .name(name + " " + code)
                .address("Teszt utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .openingDate(LocalDate.now())
                .isVault(false)
                .createdAt(now)
                .build());
    }

    private Worker saveWorker(Company company, Branch branch, String code, String name, LocalDateTime now) {
        return workerRepository.save(Worker.builder()
                .company(company)
                .branch(branch)
                .code(code)
                .name(name)
                .passwordHash("$2a$10$test")
                .role(WorkerRole.CASHIER)
                .active(true)
                .createdAt(now)
                .build());
    }

    /** A valuta törzsadat globális (nem cégenkénti) — a konténeren belül megosztott. */
    private Currency currency(String code, String name, String symbol,
                              int decimalPlaces, int displayOrder, LocalDateTime now) {
        return currencyRepository.findByCode(code)
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code(code).name(name).symbol(symbol)
                        .decimalPlaces(decimalPlaces).active(true).displayOrder(displayOrder)
                        .createdAt(now).build()));
    }

    /** A SeededPostgresAcceptanceIT mintája: prefix + max 8 számjegy — belefér a varchar(10)-be. */
    private static String shortCode(String kind, String suffix) {
        String digits = suffix.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return kind + tail;
    }
}
