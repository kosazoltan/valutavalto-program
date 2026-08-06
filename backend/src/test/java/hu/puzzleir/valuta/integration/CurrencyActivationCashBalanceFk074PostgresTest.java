package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.AdminCurrencyService;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.CashBalanceService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
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
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-074 (2026-08-06) PostgreSQL-integrációs teszt: valuta aktiválása a törzsben →
 * automatikus {@code cash_balance} inicializálás minden aktív fióknál (Értéktárakat is
 * beleértve), valamint a pénztári „Kassza / készlet" lista szűrése (inaktív+nulla rejtve,
 * inaktív+nem-nulla látható).
 *
 * <p>Minta: {@code TransferCancelEndpointStornoPostgresTest} — {@link TestApplication}
 * (nincs component scan) + {@code @Import} a vizsgált service-ekre + Testcontainers
 * PostgreSQL + {@code TestingAuthenticationToken}/{@link WorkerAuthenticationDetails}
 * a tenant-kontextushoz. A {@link AuditLogService} VALÓDI (nem mock), hogy az
 * audit-bejegyzés adatbázisban létezése közvetlenül bizonyítható legyen (§6.b, KAT=TX).
 *
 * <p>Fedett követelmények: FR-1, FR-2, FR-3, FR-4, FR-5, NFR-2 (idempotencia),
 * §6.b cross-tenant izoláció.
 */
@Testcontainers
// SZÁNDÉKOSAN NINCS @EnableJpaAuditing (repo-szabály, ld. EntityCreatedAtAuditingRegressionPostgresIT
// és DailyClosingNineStepsFk068PostgresTest:97-101): a mvn-test-suite egy JVM-en osztozik, és az
// auditing a többi tesztosztály kézi createdAt-seedelését írta felül — CI-bukást okozva
// (ShipmentHandlingFee/HufDaybook osztályok). A CurrencyAuditLog.created_at NOT NULL-jét ehelyett
// a CurrencyAuditLog.applyCreatedAtFallback() @PrePersist védőháló tölti (az AuditLog bevált mintája),
// így az audit-bejegyzés itt is perzisztálódik és közvetlenül assertálható (§6.b, KAT=TX).
@Import({
        AdminCurrencyService.class,
        CashBalanceService.class,
        AuditLogService.class
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
class CurrencyActivationCashBalanceFk074PostgresTest {

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
    @Autowired private CashBalanceRepository cashBalanceRepository;
    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private AdminCurrencyService adminCurrencyService;
    @Autowired private CashBalanceService cashBalanceService;
    @Autowired private TransactionTemplate transactionTemplate;

    @PersistenceContext private EntityManager entityManager;

    private final AtomicInteger displayOrderCounter = new AtomicInteger(600);

    @AfterEach
    void tearDownSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    // =================================================================
    // FR-3: aktiválás → 0-s sorok minden AKTÍV fióknál (Értéktár is) + audit
    // =================================================================

    @Test
    @DisplayName("FR-3: valuta aktiválása 0-egyenlegű cash_balance sort hoz létre az aktív PÉNZTÁR és ÉRTÉKTÁR fióknál, audit-bejegyzéssel")
    void activation_createsZeroRowsForActiveCashierAndVaultBranches_andWritesAudit() {
        Fixture fx = seed("FK073A");
        Currency currency = createCurrency("FXA", false);
        authenticateAs(fx.companyIdA(), fx.cashierBranchId());

        Currency activated = adminCurrencyService.setActive(currency.getId(), true, "FK-074 FR-3 teszt");

        assertThat(activated.getActive()).isTrue();

        CashBalance cashierRow = requireBalance(fx.companyIdA(), fx.cashierBranchId(), currency.getId());
        assertThat(cashierRow.getCurrentBalance())
                .as("FR-3: az új sor egyenlege 0")
                .isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(cashierRow.getOpeningBalance()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(cashierRow.getMinBalance()).as("FR-3: MIN/MAX üres marad").isNull();
        assertThat(cashierRow.getMaxBalance()).as("FR-3: MIN/MAX üres marad").isNull();

        CashBalance vaultRow = requireBalance(fx.companyIdA(), fx.vaultBranchId(), currency.getId());
        assertThat(vaultRow.getCurrentBalance())
                .as("FR-3 (FKH-029 pontosítás): az ÉRTÉKTÁR is kap sort, 0 egyenleggel")
                .isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(vaultRow.getMinBalance()).isNull();
        assertThat(vaultRow.getMaxBalance()).isNull();

        // Audit (§6.b, KAT=TX): EGY CASH_BALANCE_AUTO_INIT bejegyzés a céghez, a valuta entityId-val.
        List<AuditLog> auditEntries = transactionTemplate.execute(s -> auditLogRepository
                .findByCompanyIdAndEntityIdOrderByCreatedAtDesc(fx.companyIdA(), String.valueOf(currency.getId()))
                .stream()
                .filter(a -> "CASH_BALANCE_AUTO_INIT".equals(a.getAction()))
                .toList());
        assertThat(auditEntries)
                .as("az automatikus inicializálásnak audit-bejegyzést kell hagynia")
                .hasSize(1);
        assertThat(auditEntries.get(0).getChanges())
                .contains("FXA")
                .contains("2 új sor");
    }

    // =================================================================
    // FR-3 kiegészítés: inaktív fiók kihagyva + §6.b cross-tenant izoláció
    // =================================================================

    @Test
    @DisplayName("FR-3: az INAKTÍV fiók kimarad, és más cég fiókjai nem kapnak sort (cross-tenant izoláció)")
    void activation_skipsInactiveBranchAndOtherTenants() {
        Fixture fx = seed("FK073B");
        Currency currency = createCurrency("FXB", false);
        authenticateAs(fx.companyIdA(), fx.cashierBranchId());

        adminCurrencyService.setActive(currency.getId(), true, null);

        assertThat(balanceOf(fx.companyIdA(), fx.inactiveBranchId(), currency.getId()))
                .as("INAKTÍV fióknál NEM jöhet létre cash_balance sor")
                .isEmpty();
        assertThat(balanceOf(fx.companyIdB(), fx.branchBId(), currency.getId()))
                .as("cross-tenant: B cég fiókja NEM kaphat sort az A cég aktiválásából")
                .isEmpty();
        assertThat(countRowsForCurrency(currency.getId()))
                .as("pontosan a 2 aktív A-cégbeli fiók (pénztár + értéktár) kap sort")
                .isEqualTo(2L);
    }

    // =================================================================
    // FR-5 / NFR-2: idempotencia — dupla aktiválás + közvetlen init-hívás nem duplikál
    // =================================================================

    @Test
    @DisplayName("FR-5: ismételt aktiválás és újrahívott inicializálás NEM duplikál és NEM ír felül meglévő egyenleget")
    void activation_isIdempotent_noDuplicatesNoOverwrite() {
        Fixture fx = seed("FK073C");
        Currency currency = createCurrency("FXC", false);
        authenticateAs(fx.companyIdA(), fx.cashierBranchId());

        adminCurrencyService.setActive(currency.getId(), true, null);
        assertThat(countRowsForCurrency(currency.getId())).isEqualTo(2L);

        // Már aktív valuta „aktiválása" no-op (setActive early-return) — nincs új init-hívás.
        adminCurrencyService.setActive(currency.getId(), true, "dupla kattintás");
        assertThat(countRowsForCurrency(currency.getId()))
                .as("FR-5: dupla aktiválás nem duplikál")
                .isEqualTo(2L);

        // Meglévő egyenleg módosítása — az ON CONFLICT DO NOTHING nem írhatja felül.
        setBalance(fx.companyIdA(), fx.cashierBranchId(), currency.getId(), new BigDecimal("100"));

        // Közvetlen service-hívás (az ON CONFLICT (branch_id, currency_id) DO NOTHING út).
        int created = cashBalanceService.initializeCurrencyBalancesForActiveBranches(currency);
        assertThat(created).as("második inicializálás már nem hozhat létre sort").isZero();
        assertThat(countRowsForCurrency(currency.getId())).isEqualTo(2L);
        CashBalance cashierRow = requireBalance(fx.companyIdA(), fx.cashierBranchId(), currency.getId());
        assertThat(cashierRow.getCurrentBalance())
                .as("FR-5: meglévő egyenleg felülírása tilos")
                .isEqualByComparingTo("100");
    }

    // =================================================================
    // FR-4: deaktiválás a meglévő sorokat érintetlenül hagyja
    // =================================================================

    @Test
    @DisplayName("FR-4: valuta deaktiválása a meglévő cash_balance sorokat (egyenleg, MIN/MAX) érintetlenül hagyja")
    void deactivation_leavesAllRowsUntouched() {
        Fixture fx = seed("FK073D");
        Currency currency = createCurrency("FXD", false);
        authenticateAs(fx.companyIdA(), fx.cashierBranchId());

        adminCurrencyService.setActive(currency.getId(), true, null);
        // Valódi forgalom szimulálása: egyenleg + limitek beállítása az aktiválás után.
        setBalanceAndLimits(fx.companyIdA(), fx.cashierBranchId(), currency.getId(),
                new BigDecimal("777"), new BigDecimal("100"), new BigDecimal("1000"));

        Currency deactivated = adminCurrencyService.setActive(currency.getId(), false, "FK-074 FR-4 teszt");
        assertThat(deactivated.getActive()).isFalse();

        CashBalance cashierRow = requireBalance(fx.companyIdA(), fx.cashierBranchId(), currency.getId());
        assertThat(cashierRow.getCurrentBalance())
                .as("FR-4: deaktiválás NEM módosíthatja az egyenleget")
                .isEqualByComparingTo("777");
        assertThat(cashierRow.getMinBalance()).isEqualByComparingTo("100");
        assertThat(cashierRow.getMaxBalance()).isEqualByComparingTo("1000");
        assertThat(balanceOf(fx.companyIdA(), fx.vaultBranchId(), currency.getId()))
                .as("FR-4: az értéktári sor is megmarad")
                .isPresent();
        assertThat(countRowsForCurrency(currency.getId()))
                .as("FR-4: deaktiválás NEM törölhet sort")
                .isEqualTo(2L);
    }

    // =================================================================
    // FR-1/FR-2: a SZŰRT cashdesk-query viselkedése + szűretlen regressziós guard
    // =================================================================

    @Test
    @DisplayName("FR-1/FR-2: inaktív+nulla sor rejtve, inaktív+nem-nulla látszik; a szűretlen query továbbra is mindent visszaad")
    void filteredQuery_hidesInactiveZeroShowsInactiveNonZero_unfilteredStillReturnsAll() {
        Fixture fx = seed("FK073E");
        Currency inactiveZero = createCurrency("FXF", false);
        Currency inactiveNonZero = createCurrency("FXG", false);
        Currency activeZero = createCurrency("FXH", true);

        transactionTemplate.execute(s -> {
            LocalDateTime now = LocalDateTime.now();
            cashBalanceRepository.save(CashBalance.builder()
                    .company(companyRepository.getReferenceById(fx.companyIdA()))
                    .branch(branchRepository.getReferenceById(fx.cashierBranchId()))
                    .currency(currencyRepository.getReferenceById(inactiveZero.getId()))
                    .openingBalance(BigDecimal.ZERO).currentBalance(BigDecimal.ZERO)
                    .createdAt(now).build());
            cashBalanceRepository.save(CashBalance.builder()
                    .company(companyRepository.getReferenceById(fx.companyIdA()))
                    .branch(branchRepository.getReferenceById(fx.cashierBranchId()))
                    .currency(currencyRepository.getReferenceById(inactiveNonZero.getId()))
                    .openingBalance(new BigDecimal("500")).currentBalance(new BigDecimal("500"))
                    .createdAt(now).build());
            cashBalanceRepository.save(CashBalance.builder()
                    .company(companyRepository.getReferenceById(fx.companyIdA()))
                    .branch(branchRepository.getReferenceById(fx.cashierBranchId()))
                    .currency(currencyRepository.getReferenceById(activeZero.getId()))
                    .openingBalance(BigDecimal.ZERO).currentBalance(BigDecimal.ZERO)
                    .createdAt(now).build());
            return null;
        });

        // FR-1/FR-2: a pénztári „Kassza / készlet" lista SZŰRT queryje.
        List<String> filteredCodes = transactionTemplate.execute(s -> cashBalanceRepository
                .findByBranchIdAndCompanyIdForCashDesk(fx.cashierBranchId(), fx.companyIdA())
                .stream().map(cb -> cb.getCurrency().getCode()).toList());
        assertThat(filteredCodes)
                .as("FR-1: inaktív+NULLA (FXF) rejtve; FR-2: inaktív+NEM-NULLA (FXG) és aktív (FXH) látszik")
                .containsExactly("FXG", "FXH");

        // Regressziós guard: a SZŰRETLEN query (ClosingWizard/DailyClosing/riportok/summary
        // útvonalak forrása) továbbra is MINDEN sort visszaad — FK-074 nem gyengítheti azt.
        List<String> unfilteredCodes = transactionTemplate.execute(s -> cashBalanceRepository
                .findByBranchIdAndCompanyId(fx.cashierBranchId(), fx.companyIdA())
                .stream().map(cb -> cb.getCurrency().getCode()).toList());
        assertThat(unfilteredCodes)
                .as("regressziós guard: a szűretlen findByBranchIdAndCompanyId mindent visszaad")
                .containsExactly("FXF", "FXG", "FXH");
    }

    // ===== Helperek =====

    private record Fixture(UUID companyIdA, UUID cashierBranchId, UUID vaultBranchId,
                           UUID inactiveBranchId, UUID companyIdB, UUID branchBId) {
    }

    private Fixture seed(String prefix) {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            String suffix = prefix + "-" + System.nanoTime();

            Company companyA = companyRepository.save(Company.builder()
                    .code(shortCode("CA", suffix))
                    .name("FK-074 company A " + suffix)
                    .createdAt(now)
                    .build());
            Company companyB = companyRepository.save(Company.builder()
                    .code(shortCode("CB", suffix))
                    .name("FK-074 company B " + suffix)
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

            Branch cashier = saveBranch(companyA, branchType, country, branchStatus,
                    shortCode("PC", suffix), now, false, true);
            Branch vault = saveBranch(companyA, branchType, country, branchStatus,
                    shortCode("VT", suffix), now, true, true);
            Branch inactive = saveBranch(companyA, branchType, country, branchStatus,
                    shortCode("IN", suffix), now, false, false);
            Branch branchB = saveBranch(companyB, branchType, country, branchStatus,
                    shortCode("PB", suffix), now, false, true);

            return new Fixture(companyA.getId(), cashier.getId(), vault.getId(),
                    inactive.getId(), companyB.getId(), branchB.getId());
        });
    }

    private Branch saveBranch(Company company, Dictionary branchType, Dictionary country,
                              Dictionary branchStatus, String code, LocalDateTime now,
                              boolean isVault, boolean isActive) {
        return branchRepository.save(Branch.builder()
                .code(code).company(company).bankCode("FK074BANK")
                .branchType(branchType).name("Fiók " + code)
                .address("Teszt utca 1").city("Budapest").zipCode("1000")
                .country(country).branchStatus(branchStatus)
                .openingDate(LocalDate.now()).isVault(isVault).isActive(isActive)
                .createdAt(now).build());
    }

    private Currency createCurrency(String code, boolean active) {
        return transactionTemplate.execute(s -> currencyRepository.saveAndFlush(Currency.builder()
                .code(code).name("FK-074 teszt " + code).symbol("T")
                .decimalPlaces(2).displayOrder(displayOrderCounter.incrementAndGet())
                .active(active)
                .createdAt(LocalDateTime.now()).build()));
    }

    private void authenticateAs(UUID companyId, UUID branchId) {
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_ADMIN");
        auth.setDetails(new WorkerAuthenticationDetails(1L, companyId, branchId, "ADMIN"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private Optional<CashBalance> balanceOf(UUID companyId, UUID branchId, Long currencyId) {
        return transactionTemplate.execute(s -> cashBalanceRepository
                .findByBranchIdAndCurrencyIdAndCompanyId(branchId, currencyId, companyId));
    }

    private CashBalance requireBalance(UUID companyId, UUID branchId, Long currencyId) {
        return balanceOf(companyId, branchId, currencyId)
                .orElseThrow(() -> new AssertionError("Hiányzó cash_balance sor (branch=" + branchId + ")"));
    }

    private long countRowsForCurrency(Long currencyId) {
        return transactionTemplate.execute(s -> entityManager.createQuery(
                        "SELECT COUNT(cb) FROM CashBalance cb WHERE cb.currency.id = :currencyId", Long.class)
                .setParameter("currencyId", currencyId)
                .getSingleResult());
    }

    private void setBalance(UUID companyId, UUID branchId, Long currencyId, BigDecimal balance) {
        transactionTemplate.execute(s -> {
            CashBalance row = cashBalanceRepository
                    .findByBranchIdAndCurrencyIdAndCompanyId(branchId, currencyId, companyId)
                    .orElseThrow();
            row.setCurrentBalance(balance);
            return cashBalanceRepository.save(row);
        });
    }

    private void setBalanceAndLimits(UUID companyId, UUID branchId, Long currencyId,
                                     BigDecimal balance, BigDecimal min, BigDecimal max) {
        transactionTemplate.execute(s -> {
            CashBalance row = cashBalanceRepository
                    .findByBranchIdAndCurrencyIdAndCompanyId(branchId, currencyId, companyId)
                    .orElseThrow();
            row.setCurrentBalance(balance);
            row.setMinBalance(min);
            row.setMaxBalance(max);
            return cashBalanceRepository.save(row);
        });
    }

    private static String shortCode(String kind, String suffix) {
        String digits = suffix.replaceAll("[^0-9]", "");
        String tail = digits.length() <= 6 ? digits : digits.substring(digits.length() - 6);
        return kind + tail;
    }
}
