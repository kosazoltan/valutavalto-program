package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.InventoryStockAccessor;
import hu.puzzleir.valuta.service.ShipmentStockBookingService;
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
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * INVSTOCK-SHIPMENT-ROLLBACK-ONLY Szelet 1: valós PostgreSQL repro a
 * saveAndFlush + DataIntegrityViolationException-catch get-or-create minta rollback-only hibájára.
 */
@Testcontainers
@EnableJpaAuditing
@Import({InventoryStockAccessor.class, ShipmentStockBookingService.class, AuditLogService.class})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class InventoryStockRollbackOnlyPostgresIT {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private InventoryStockAccessor inventoryStockAccessor;
    @Autowired private ShipmentStockBookingService shipmentStockBookingService;
    @Autowired private TransactionTemplate transactionTemplate;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private ShipmentRequestRepository shipmentRequestRepository;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("vault get-or-create race: a vesztes szál javító könyvelése NEM veszhet el (nincs UnexpectedRollbackException)")
    void vaultGetOrCreate_loserTransactionCommitsCorrectiveBooking() throws Exception {
        Seed seed = seedVaultBranchAndCurrency();
        installAuth(seed.companyId, seed.vaultBranch.getId());
        CountDownLatch winnerInserted = new CountDownLatch(1);
        CyclicBarrier loserReady = new CyclicBarrier(2);
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Future<?> winner = executor.submit(() -> transactionTemplate.executeWithoutResult(status -> {
            jdbcTemplate.update("""
                    INSERT INTO currency_stock
                      (company_id, entity_type, entity_id, currency_code, quantity, weighted_avg_cost, last_updated)
                    VALUES (?, 'VAULT', ?, ?, 100, 380, NOW())
                    """, seed.companyId, seed.vaultEntityId, seed.currencyCode);
            winnerInserted.countDown();
            await(loserReady);
            sleepQuietly(800);
        }));

        try {
            assertThat(winnerInserted.await(10, TimeUnit.SECONDS)).isTrue();
            await(loserReady);

            transactionTemplate.executeWithoutResult(status ->
                    inventoryStockAccessor.adjust(seed.vaultBranch, seed.currency, new BigDecimal("50.00")));
        } finally {
            winner.get(20, TimeUnit.SECONDS);
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS)).isTrue();
        }

        Integer rows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM currency_stock WHERE company_id=? AND entity_type='VAULT' AND entity_id=? AND currency_code=?",
                Integer.class, seed.companyId, seed.vaultEntityId, seed.currencyCode);
        BigDecimal qty = jdbcTemplate.queryForObject(
                "SELECT quantity FROM currency_stock WHERE company_id=? AND entity_type='VAULT' AND entity_id=? AND currency_code=?",
                BigDecimal.class, seed.companyId, seed.vaultEntityId, seed.currencyCode);
        assertThat(rows).isEqualTo(1);
        assertThat(qty).as("100 (győztes) + 50 (vesztes) — a javító könyvelés nem veszhet el")
                .isEqualByComparingTo("150.00");
    }

    @Test
    @DisplayName("shipment VAULT receive race: a vesztes szál javító könyvelése NEM veszhet el")
    void shipmentVaultReceive_loserTransactionCommitsCorrectiveBooking() throws Exception {
        ShipmentSeed seed = seedShipment(true, new BigDecimal("400.00"), new BigDecimal("152000.00"));
        installAuth(seed.companyId, seed.toBranch.getId());
        CountDownLatch winnerInserted = new CountDownLatch(1);
        CyclicBarrier loserReady = new CyclicBarrier(2);
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Future<?> winner = executor.submit(() -> transactionTemplate.executeWithoutResult(status -> {
            jdbcTemplate.update("""
                    INSERT INTO currency_stock
                      (company_id, entity_type, entity_id, currency_code, quantity, weighted_avg_cost, last_updated)
                    VALUES (?, 'VAULT', ?, ?, 1000, 380, NOW())
                    """, seed.companyId, seed.vaultEntityId, seed.currencyCode);
            winnerInserted.countDown();
            await(loserReady);
            sleepQuietly(800);
        }));

        try {
            assertThat(winnerInserted.await(10, TimeUnit.SECONDS)).isTrue();
            await(loserReady);

            transactionTemplate.executeWithoutResult(status ->
                    shipmentStockBookingService.bookStockIn(seed.request, seed.companyId));
        } finally {
            winner.get(20, TimeUnit.SECONDS);
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS)).isTrue();
        }

        Integer rows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM currency_stock WHERE company_id=? AND entity_type='VAULT' AND entity_id=? AND currency_code=?",
                Integer.class, seed.companyId, seed.vaultEntityId, seed.currencyCode);
        BigDecimal qty = jdbcTemplate.queryForObject(
                "SELECT quantity FROM currency_stock WHERE company_id=? AND entity_type='VAULT' AND entity_id=? AND currency_code=?",
                BigDecimal.class, seed.companyId, seed.vaultEntityId, seed.currencyCode);
        assertThat(rows).isEqualTo(1);
        assertThat(qty).as("1000 (győztes) + 400 (vesztes shipment IN) — a javító könyvelés nem veszhet el")
                .isEqualByComparingTo("1400.00");
    }

    @Test
    @DisplayName("shipment CASH receive race: a vesztes szál javító könyvelése NEM veszhet el")
    void shipmentCashReceive_loserTransactionCommitsCorrectiveBooking() throws Exception {
        ShipmentSeed seed = seedShipment(false, new BigDecimal("400.00"), new BigDecimal("152000.00"));
        installAuth(seed.companyId, seed.toBranch.getId());
        CountDownLatch winnerInserted = new CountDownLatch(1);
        CyclicBarrier loserReady = new CyclicBarrier(2);
        ExecutorService executor = Executors.newSingleThreadExecutor();
        Future<?> winner = executor.submit(() -> transactionTemplate.executeWithoutResult(status -> {
            jdbcTemplate.update("""
                    INSERT INTO cash_balance
                      (branch_id, currency_id, company_id, current_balance, opening_balance, created_at, version)
                    VALUES (?, ?, ?, 100, 0, NOW(), 0)
                    """, seed.toBranch.getId(), seed.currency.getId(), seed.companyId);
            winnerInserted.countDown();
            await(loserReady);
            sleepQuietly(800);
        }));

        try {
            assertThat(winnerInserted.await(10, TimeUnit.SECONDS)).isTrue();
            await(loserReady);

            transactionTemplate.executeWithoutResult(status ->
                    shipmentStockBookingService.bookStockIn(seed.request, seed.companyId));
        } finally {
            winner.get(20, TimeUnit.SECONDS);
            executor.shutdownNow();
            assertThat(executor.awaitTermination(5, TimeUnit.SECONDS)).isTrue();
        }

        Integer rows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM cash_balance WHERE branch_id=? AND currency_id=?",
                Integer.class, seed.toBranch.getId(), seed.currency.getId());
        BigDecimal balance = jdbcTemplate.queryForObject(
                "SELECT current_balance FROM cash_balance WHERE branch_id=? AND currency_id=?",
                BigDecimal.class, seed.toBranch.getId(), seed.currency.getId());
        assertThat(rows).isEqualTo(1);
        assertThat(balance).as("100 (győztes) + 400 (vesztes shipment IN) — a javító könyvelés nem veszhet el")
                .isEqualByComparingTo("500.00");
    }

    private Seed seedVaultBranchAndCurrency() {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            int seq = SEQ.incrementAndGet();
            Company company = seedCompany("IVC" + seq, now);
            Branch vaultBranch = seedBranch(company, "IVB" + seq, true, 10_000 + seq, now);
            Currency currency = findOrCreateCurrency(now);
            return new Seed(company.getId(), vaultBranch, currency, vaultBranch.getVaultTerritoryId().toString(), currency.getCode());
        });
    }

    private ShipmentSeed seedShipment(boolean toVault, BigDecimal amount, BigDecimal hufValue) {
        return transactionTemplate.execute(status -> {
            LocalDateTime now = LocalDateTime.now();
            int seq = SEQ.incrementAndGet();
            Company company = seedCompany("ISC" + seq, now);
            Branch fromBranch = seedBranch(company, "ISF" + seq, !toVault, 20_000 + seq, now);
            Branch toBranch = seedBranch(company, "IST" + seq, toVault, 30_000 + seq, now);
            Currency currency = findOrCreateCurrency(now);

            ShipmentRequest request = ShipmentRequest.builder()
                    .requestNumber("INVSTOCK-" + seq)
                    .companyId(company.getId())
                    .fromBranchId(fromBranch.getId())
                    .toBranchId(toBranch.getId())
                    .transferType(toVault
                            ? ShipmentStockBookingService.TRANSFER_BRANCH_TO_VAULT
                            : ShipmentStockBookingService.TRANSFER_VAULT_TO_BRANCH)
                    .requestedById(1L)
                    .status(ShipmentRequestStatus.IN_TRANSIT)
                    .requestDate(LocalDate.now())
                    .carrierName("Teszt Futár")
                    .sealNumber("INV-" + seq)
                    .createdAt(now)
                    .items(new ArrayList<>())
                    .build();
            request.addItem(ShipmentRequestItem.builder()
                    .currencyId(currency.getId())
                    .requestedAmount(amount)
                    .hufValue(hufValue)
                    .build());
            ShipmentRequest persisted = shipmentRequestRepository.saveAndFlush(request);
            String vaultEntityId = toVault ? toBranch.getVaultTerritoryId().toString() : null;
            return new ShipmentSeed(company.getId(), toBranch, currency, persisted, vaultEntityId, currency.getCode());
        });
    }

    private Company seedCompany(String code, LocalDateTime now) {
        return companyRepository.saveAndFlush(Company.builder()
                .code(code)
                .name("Inventory rollback repro company " + code)
                .createdAt(now)
                .build());
    }

    private Branch seedBranch(Company company, String code, boolean vault, int territoryId, LocalDateTime now) {
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code(code + "T")
                .name("Inventory rollback branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code(code + "C")
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary statusDictionary = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code(code + "S")
                .name("Active")
                .createdAt(now)
                .build());

        return branchRepository.saveAndFlush(Branch.builder()
                .code(code)
                .company(company)
                .bankCode("ITBANK")
                .branchType(branchType)
                .name("Inventory rollback branch " + code)
                .address("Inventory utca 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(statusDictionary)
                .openingDate(LocalDate.now())
                .isVault(vault)
                .vaultTerritoryId(vault ? territoryId : null)
                .createdAt(now)
                .build());
    }

    private Currency findOrCreateCurrency(LocalDateTime now) {
        return currencyRepository.findByCode("EUR")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("EUR")
                        .name("Euro")
                        .symbol("EUR")
                        .decimalPlaces(2)
                        .active(true)
                        .displayOrder(2)
                        .createdAt(now)
                        .build()));
    }

    private static void installAuth(UUID companyId, UUID branchId) {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(1L, companyId, branchId, "PENZTAROS");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("t", "x", "ROLE_PENZTAROS");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private static void await(CyclicBarrier barrier) {
        try {
            barrier.await(10, TimeUnit.SECONDS);
        } catch (Exception e) {
            throw new AssertionError("Időtúllépés/megszakítás a race barrier várásánál", e);
        }
    }

    private static void sleepQuietly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new AssertionError("Megszakítva a győztes commit-késleltetésénél", e);
        }
    }

    private record Seed(
            UUID companyId,
            Branch vaultBranch,
            Currency currency,
            String vaultEntityId,
            String currencyCode) {
    }

    private record ShipmentSeed(
            UUID companyId,
            Branch toBranch,
            Currency currency,
            ShipmentRequest request,
            String vaultEntityId,
            String currencyCode) {
    }
}
