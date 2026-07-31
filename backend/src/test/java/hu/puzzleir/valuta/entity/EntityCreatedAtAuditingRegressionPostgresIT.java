package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.TestApplication;
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
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
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

import static org.assertj.core.api.Assertions.assertThat;

/**
 * (c) Regresszió: BEKAPCSOLT auditing mellett a {@code created_at} viselkedése VÁLTOZATLAN,
 * azaz a {@link Transfer}/{@link Transaction} entitásokra felvett {@code @PrePersist} védőháló
 * élesben nem vesz át semmilyen szerepet.
 *
 * <p>A védőháló csak {@code null} esetén tölt, a JPA-specifikáció szerint pedig az
 * {@code @EntityListeners} callbackjei (itt: {@code AuditingEntityListener}) az entitás SAJÁT
 * callbackjei ELŐTT futnak — auditinggal tehát a mező már ki van töltve, mire a védőháló
 * sorra kerül. Ez a teszt ezt a sorrendet igazolja valós Postgres + valós auditing mellett,
 * azaz azt, hogy az éles ({@code ValutaBackendApplication}) konfiguráció szemantikája nem
 * változott.
 *
 * <h3>Miért {@code *IT} és nem {@code *Test} — szándékos, dokumentált korlát</h3>
 * A CI KIZÁRÓLAG {@code *Test} osztályokat futtat (Surefire; nincs Failsafe a
 * {@code backend/pom.xml}-ben, és egyetlen workflow sem hív {@code mvn verify}-t). Ez az
 * osztály ezért <b>CI-ben NEM fut</b> — kézzel, Docker mellett futtatható.
 *
 * <p>Ez tudatos döntés: a Surefire alapértelmezetten {@code forkCount=1, reuseForks=true}
 * mellett fut, tehát MINDEN tesztosztály egy JVM-en osztozik. Egy {@code @EnableJpaAuditing}-et
 * hordozó {@code *Test} osztály emiatt JVM-szinten aktiválja az auditingot, és felülírja a
 * suite kézzel seedelt {@code createdAt} értékeit — ez mérhetően 7 idegen teszt bukását okozta
 * 3 osztályban ({@code ShipmentHandlingFeeRepositoryTest},
 * {@code HufDaybookUnifiedListFrK6PostgresTest},
 * {@code HufDaybookAnnualSequenceBackfillFrK2PostgresTest}) a PR #1531 CI-futásán. A repo
 * „{@code TestApplication} alatt {@code @EnableJpaAuditing} tilos" szabálya pontosan ezt védi.
 *
 * <p>A CI-ben futó garanciát az {@code EntityCreatedAtFallbackPostgresTest} (b) esete adja:
 * ha a {@code createdAt} már ki van töltve — márpedig auditinggal a listener-sorrend miatt ki
 * van —, a védőháló bizonyítottan nem nyúl hozzá.
 */
@Testcontainers
@EnableJpaAuditing
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class EntityCreatedAtAuditingRegressionPostgresIT {

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
    @Autowired private TransferRepository transferRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @PersistenceContext private EntityManager entityManager;

    @Test
    @DisplayName("(c) auditinggal a Transfer created_at-ját továbbra is az auditing tölti — a védőháló nem vesz át szerepet")
    void transfer_withAuditing_createdAtStillPopulatedByAuditing() {
        Seed seed = seed("CAR-TRF");
        LocalDateTime before = LocalDateTime.now();

        Long id = transactionTemplate.execute(status -> {
            Transfer saved = transferRepository.save(Transfer.builder()
                    .transferNumber("AT-000201")
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
                    .build());
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        assertThat(transactionTemplate.execute(s -> transferRepository.findById(id).orElseThrow()).getCreatedAt())
                .as("auditinggal a created_at kitöltött és friss — az éles szemantika változatlan")
                .isNotNull()
                .isAfterOrEqualTo(before.minusMinutes(1));
    }

    @Test
    @DisplayName("(c) auditinggal a Transaction created_at-ját továbbra is az auditing tölti — a védőháló nem vesz át szerepet")
    void transaction_withAuditing_createdAtStillPopulatedByAuditing() {
        Seed seed = seed("CAR-TXN");
        LocalDateTime before = LocalDateTime.now();

        Long id = transactionTemplate.execute(status -> {
            Transaction saved = transactionRepository.save(Transaction.builder()
                    .company(seed.company())
                    .branch(seed.fromBranch())
                    .worker(seed.worker())
                    .receiptNumber("R-000201")
                    .transactionType(TransactionType.TRANSFER_OUT)
                    .status(TransactionStatus.COMPLETED)
                    .transactionDate(LocalDate.now())
                    .transactionTime(LocalTime.now())
                    .currency(seed.currency())
                    .currencyAmount(new BigDecimal("1000.00"))
                    .exchangeRate(BigDecimal.ONE)
                    .hufAmount(new BigDecimal("400000.00"))
                    .build());
            entityManager.flush();
            entityManager.clear();
            return saved.getId();
        });

        assertThat(transactionTemplate.execute(s -> transactionRepository.findById(id).orElseThrow()).getCreatedAt())
                .as("auditinggal a created_at kitöltött és friss — az éles szemantika változatlan")
                .isNotNull()
                .isAfterOrEqualTo(before.minusMinutes(1));
    }

    // ===== Helperek (az EntityCreatedAtFallbackPostgresTest seedjével azonos szerkezet) =====

    private record Seed(Company company, Branch fromBranch, Branch toBranch, Worker worker, Currency currency) {
    }

    private Seed seed(String prefix) {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = prefix + "-" + System.nanoTime();

            Company company = companyRepository.save(Company.builder()
                    .code(shortCode("C", suffix))
                    .name("auditing regression company " + suffix)
                    .createdAt(now)
                    .build());

            Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                    .category("BRANCH_TYPE").code(shortCode("BT", suffix))
                    .name("regression branch type").createdAt(now).build());
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
                    .name("Regressziós pénztáros")
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
                .bankCode("CARBANK")
                .branchType(branchType)
                .name("Regressziós fiók " + code)
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

    private static String shortCode(String kind, String suffix) {
        String digits = suffix.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 8 ? digits : digits.substring(digits.length() - 8);
        return kind + tail;
    }
}
