package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
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
import java.time.LocalTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * {@code created_at} védőháló a {@link Transfer} és {@link Transaction} entitásokon — RED→GREEN.
 *
 * <h3>Miért kell</h3>
 * Mindkét entitás {@code created_at} mezője {@code nullable = false}, az értéket viszont
 * kizárólag a {@code @CreatedDate} auditing tölti; az entitást építő service-ek (pl.
 * {@code TransferService.create} és {@code createReversalTransaction}) szándékosan nem állítják
 * be kézzel. Éles környezetben ez rendben van — a {@code ValutaBackendApplication} hordozza az
 * {@code @EnableJpaAuditing}-et —, de a {@code TestApplication}-kontextusokban nincs auditing
 * (repo-szabály: bekapcsolva korábban suite-szintű törést okozott). Emiatt BÁRMELY auditing
 * nélküli útvonal, ami ilyen entitást perzisztál, NOT NULL-sértéssel elhasal, holott a mentendő
 * adat maga hibátlan.
 *
 * <h3>Mit rögzít ez a teszt</h3>
 * <ul>
 *   <li><b>(a)</b> auditing NÉLKÜL, {@code createdAt} megadása nélkül a mentés SIKERES, és a
 *       perzisztált érték nem null;</li>
 *   <li><b>(b)</b> auditing NÉLKÜL, expliciten megadott {@code createdAt} esetén az EREDETI érték
 *       marad meg — a védőháló sosem ír felül.</li>
 * </ul>
 * A (c) auditing-os regresszió a párja: {@code EntityCreatedAtAuditingRegressionPostgresIT}
 * (ld. ott, miért nem {@code *Test}).
 *
 * <p>Ez az osztály SZÁNDÉKOSAN nem kapcsol {@code @EnableJpaAuditing}-et — épp az auditing
 * nélküli viselkedés a szerződés tárgya.
 *
 * <p>Az assertek a DB-be TÉNYLEGESEN kiírt sort nézik ({@code flush} + {@code clear} utáni
 * újraolvasás), nem a memóriabeli példányt — különben a teszt akkor is zöld lenne, ha az érték
 * sosem jutna el az INSERT-ig.
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
class EntityCreatedAtFallbackPostgresTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private TransferRepository transferRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @PersistenceContext private EntityManager entityManager;

    /** Szándékosan régi, "beszélő" időpont — ha felülíródna, az azonnal látszik. */
    private static final LocalDateTime EXPLICIT_CREATED_AT = LocalDateTime.of(2020, 3, 4, 5, 6, 7);

    // =====================================================================
    // (a) auditing nélkül, createdAt nélkül → sikeres mentés, nem null érték
    // =====================================================================

    @Test
    @DisplayName("(a) Transfer: auditing nélkül, createdAt megadása nélkül is menthető, a perzisztált érték nem null")
    void transfer_withoutAuditingAndWithoutCreatedAt_persistsWithFallbackValue() {
        Seed seed = seed("CAF-TRF-A");
        LocalDateTime before = LocalDateTime.now();

        Long id = transactionTemplate.execute(status -> {
            Transfer saved = transferRepository.save(newTransfer(seed, "AT-000101", null));
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        Transfer reloaded = reloadTransfer(id);
        assertThat(reloaded.getCreatedAt())
                .as("a @PrePersist védőháló kitöltötte a created_at-ot auditing nélkül is")
                .isNotNull()
                .isAfterOrEqualTo(before.minusMinutes(1));
    }

    @Test
    @DisplayName("(a) Transaction: auditing nélkül, createdAt megadása nélkül is menthető, a perzisztált érték nem null")
    void transaction_withoutAuditingAndWithoutCreatedAt_persistsWithFallbackValue() {
        Seed seed = seed("CAF-TXN-A");
        LocalDateTime before = LocalDateTime.now();

        Long id = transactionTemplate.execute(status -> {
            Transaction saved = transactionRepository.save(newTransaction(seed, "R-000101", null));
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        Transaction reloaded = reloadTransaction(id);
        assertThat(reloaded.getCreatedAt())
                .as("a @PrePersist védőháló kitöltötte a created_at-ot auditing nélkül is")
                .isNotNull()
                .isAfterOrEqualTo(before.minusMinutes(1));
    }

    @Test
    @DisplayName("(a) AuditLog: auditing nélkül, createdAt megadása nélkül is menthető, a perzisztált érték nem null")
    void auditLog_withoutAuditingAndWithoutCreatedAt_persistsWithFallbackValue() {
        LocalDateTime before = LocalDateTime.now();

        UUID id = transactionTemplate.execute(status -> {
            AuditLog saved = auditLogRepository.save(newAuditLog(null));
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        AuditLog reloaded = auditLogRepository.findById(id).orElseThrow();
        assertThat(reloaded.getCreatedAt())
                .as("audit-bejegyzés nem veszhet el amiatt, hogy a hívó kontextusban nincs auditing")
                .isNotNull()
                .isAfterOrEqualTo(before.minusMinutes(1));
    }

    // =====================================================================
    // (b) auditing nélkül, explicit createdAt → az eredeti érték marad
    // =====================================================================

    @Test
    @DisplayName("(b) AuditLog: expliciten megadott createdAt-ot a védőháló NEM írja felül")
    void auditLog_withExplicitCreatedAt_keepsCallerProvidedValue() {
        UUID id = transactionTemplate.execute(status -> {
            AuditLog saved = auditLogRepository.save(newAuditLog(EXPLICIT_CREATED_AT));
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        assertThat(auditLogRepository.findById(id).orElseThrow().getCreatedAt())
                .as("a védőháló kizárólag null esetén tölt — meglévő értéket sosem ír felül")
                .isEqualTo(EXPLICIT_CREATED_AT);
    }

    private AuditLog newAuditLog(LocalDateTime createdAt) {
        return AuditLog.builder()
                .action("CREATE")
                .entityType("SystemParameter")
                .entityId(UUID.randomUUID().toString())
                .createdAt(createdAt)
                .build();
    }

    @Test
    @DisplayName("(b) Transfer: expliciten megadott createdAt-ot a védőháló NEM írja felül")
    void transfer_withExplicitCreatedAt_keepsCallerProvidedValue() {
        Seed seed = seed("CAF-TRF-B");

        Long id = transactionTemplate.execute(status -> {
            Transfer saved = transferRepository.save(
                    newTransfer(seed, "AT-000102", EXPLICIT_CREATED_AT));
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        assertThat(reloadTransfer(id).getCreatedAt())
                .as("a védőháló kizárólag null esetén tölt — meglévő értéket sosem ír felül")
                .isEqualTo(EXPLICIT_CREATED_AT);
    }

    @Test
    @DisplayName("(b) Transaction: expliciten megadott createdAt-ot a védőháló NEM írja felül")
    void transaction_withExplicitCreatedAt_keepsCallerProvidedValue() {
        Seed seed = seed("CAF-TXN-B");

        Long id = transactionTemplate.execute(status -> {
            Transaction saved = transactionRepository.save(
                    newTransaction(seed, "R-000102", EXPLICIT_CREATED_AT));
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        assertThat(reloadTransaction(id).getCreatedAt())
                .as("a védőháló kizárólag null esetén tölt — meglévő értéket sosem ír felül")
                .isEqualTo(EXPLICIT_CREATED_AT);
    }

    // =====================================================================
    // A védőháló előtti állapot dokumentálása: a mentés egyáltalán ne dobjon
    // =====================================================================

    @Test
    @DisplayName("A védőháló nélkül NOT NULL-sértés jönne — a mentés ma hibamentesen lefut mindkét entitásra")
    void bothEntities_saveWithoutCreatedAt_doNotThrow() {
        Seed seed = seed("CAF-BOTH");

        assertThatCode(() -> transactionTemplate.executeWithoutResult(status -> {
            transferRepository.save(newTransfer(seed, "AT-000103", null));
            transactionRepository.save(newTransaction(seed, "R-000103", null));
            entityManager.flush();
        }))
                .as("created_at NOT NULL sértés nélkül perzisztálódik auditing nélküli kontextusban is")
                .doesNotThrowAnyException();
    }

    // =====================================================================
    // Helperek
    // =====================================================================

    private record Seed(Company company, Branch fromBranch, Branch toBranch, Worker worker, Currency currency) {
    }

    private Transfer newTransfer(Seed seed, String transferNumber, LocalDateTime createdAt) {
        return Transfer.builder()
                .transferNumber(transferNumber)
                .companyId(seed.company().getId())
                .fromBranch(seed.fromBranch())
                .toBranch(seed.toBranch())
                .fromWorker(seed.worker())
                .transferType(Transfer.TransferType.CURRENCY)
                .status(Transfer.TransferStatus.PENDING)
                .transferDate(LocalDate.now())
                .transferTime(LocalTime.now())
                .currency(seed.currency())
                .amount(new BigDecimal("1000.0000"))
                .direction(Transfer.TransferDirection.F)
                .createdAt(createdAt)
                .build();
    }

    private Transaction newTransaction(Seed seed, String receiptNumber, LocalDateTime createdAt) {
        return Transaction.builder()
                .company(seed.company())
                .branch(seed.fromBranch())
                .worker(seed.worker())
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.TRANSFER_OUT)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(seed.currency())
                .currencyAmount(new BigDecimal("1000.00"))
                .exchangeRate(BigDecimal.ONE)
                .hufAmount(new BigDecimal("400000.00"))
                .createdAt(createdAt)
                .build();
    }

    private Transfer reloadTransfer(Long id) {
        return transactionTemplate.execute(status -> transferRepository.findById(id).orElseThrow());
    }

    private Transaction reloadTransaction(Long id) {
        return transactionTemplate.execute(status -> transactionRepository.findById(id).orElseThrow());
    }

    /**
     * A törzsadat-seed KÉZZEL tölti a {@code createdAt}-ot (a suite bevált, auditing nélküli
     * mintája) — a védőháló szerződése kizárólag a {@link Transfer}/{@link Transaction} párosra
     * vonatkozik, a fixture nem támaszkodhat rá.
     */
    private Seed seed(String prefix) {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = prefix + "-" + System.nanoTime();

            Company company = companyRepository.save(Company.builder()
                    .code(shortCode("C", suffix))
                    .name("created_at fallback company " + suffix)
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code(shortCode("BT", suffix))
                    .name("fallback branch type").createdAt(now).build());
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
                    .company(company)
                    .branch(fromBranch)
                    .code(shortCode("W", suffix))
                    .name("Fallback pénztáros")
                    .passwordHash("$2a$10$test")
                    .role(WorkerRole.CASHIER)
                    .active(true)
                    .createdAt(now)
                    .build());

            Currency currency = currencyRepository.findByCode("EUR")
                    .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                            .code("EUR").name("Euró").symbol("€")
                            .decimalPlaces(2).active(true).displayOrder(2)
                            .createdAt(now).build()));

            return new Seed(company, fromBranch, toBranch, worker, currency);
        });
    }

    private Branch saveBranch(Company company, Dictionary branchType, Dictionary country,
                              Dictionary branchStatus, String code, LocalDateTime now) {
        return branchRepository.save(Branch.builder()
                .code(code)
                .company(company)
                .bankCode("CAFBANK")
                .branchType(branchType)
                .name("Fallback fiók " + code)
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

    /** A SeededPostgresAcceptanceIT mintája: prefix + max 8 számjegy — belefér a varchar(10)-be. */
    private static String shortCode(String kind, String suffix) {
        String digits = suffix.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return kind + tail;
    }
}
