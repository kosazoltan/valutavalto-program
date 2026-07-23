package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.Dictionary;
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
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-058: a VAULT_COUNTERPARTY virtuális partner-fiókok (is_vault=false!) kizárása a
 * cash_balance és daily_session "ExcludingVault" lekérdezésekből — a FK-056-ban bevált
 * null-safe branchType-predikátummal, az isVault-feltétel (defense-in-depth) megtartása
 * mellett. Valós PostgreSQL (Testcontainers), mert a JPQL LEFT JOIN + Dictionary-kapcsolat
 * viselkedését a H2/mocking nem fedi hitelesen.
 */
@Testcontainers
@EnableJpaAuditing
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
class VaultCounterpartyExclusionPostgresIT {

    private static final LocalDate DAY = LocalDate.of(2026, 7, 20);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private CashBalanceRepository cashBalanceRepository;
    @Autowired private DailySessionRepository dailySessionRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("FK-058 FR-1/FR-3: a VAULT_COUNTERPARTY branch cash_balance sora kimarad, a normál benne marad, a vault kimarad")
    void findByCompanyIdExcludingVault_excludesVaultCounterpartyBranch() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<CashBalance> result =
                cashBalanceRepository.findByCompanyIdExcludingVault(seed.company().getId());

        assertThat(result)
                .extracting(cb -> cb.getBranch().getId())
                .contains(seed.normalBranch().getId())
                .doesNotContain(seed.counterpartyBranch().getId())
                .doesNotContain(seed.vaultBranch().getId());
    }

    @Test
    @DisplayName("FK-058 FR-2/FR-4: a VAULT_COUNTERPARTY branch daily_session sora kimarad, a normál benne marad, a vault kimarad")
    void findByDateRangeExcludingVault_excludesVaultCounterpartyBranch() {
        Seed seed = transactionTemplate.execute(status -> seed());
        assertThat(seed).isNotNull();

        List<DailySession> result = dailySessionRepository.findByDateRangeExcludingVault(
                seed.company().getId(), DAY.minusDays(1), DAY.plusDays(1));

        assertThat(result)
                .extracting(ds -> ds.getBranch().getId())
                .contains(seed.normalBranch().getId())
                .doesNotContain(seed.counterpartyBranch().getId())
                .doesNotContain(seed.vaultBranch().getId());
    }

    private Seed seed() {
        LocalDateTime now = DAY.atTime(8, 0);
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Dictionary normalType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code("FK058-BT-" + suffix)
                .name("FK-058 branch type")
                .createdAt(now)
                .build());
        Dictionary counterpartyType = dictionaryRepository
                .findByCategoryAndCode("BRANCH_TYPE", "VAULT_COUNTERPARTY")
                .orElseGet(() -> dictionaryRepository.save(Dictionary.builder()
                        .category("BRANCH_TYPE")
                        .code("VAULT_COUNTERPARTY")
                        .name("Vault counterparty")
                        .createdAt(now)
                        .build()));
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code("FK058-CO-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code("FK058-BS-" + suffix)
                .name("Active")
                .createdAt(now)
                .build());
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseGet(() -> currencyRepository.saveAndFlush(Currency.builder()
                        .code("HUF")
                        .name("Forint")
                        .symbol("Ft")
                        .decimalPlaces(0)
                        .active(true)
                        .displayOrder(1)
                        .createdAt(now)
                        .build()));

        Company company = companyRepository.save(Company.builder()
                .code("FK058-C-" + suffix)
                .name("FK-058 Company " + suffix)
                .createdAt(now)
                .build());

        // Normál pénztár: isVault=false, normál branchType → az eredményben MARAD
        Branch normalBranch = seedBranch(company, "N" + suffix, normalType, country,
                branchStatus, now, false);
        // Értéktár: isVault=true → kimarad (változatlan, korábban is kizárt viselkedés)
        Branch vaultBranch = seedBranch(company, "V" + suffix, normalType, country,
                branchStatus, now, true);
        // VAULT_COUNTERPARTY partner-fiók: isVault=FALSE, de counterparty branchType → ÚJ kizárás
        Branch counterpartyBranch = seedBranch(company, "P" + suffix, counterpartyType, country,
                branchStatus, now, false);

        saveCashBalance(company, normalBranch, huf, now);
        saveCashBalance(company, vaultBranch, huf, now);
        saveCashBalance(company, counterpartyBranch, huf, now);

        saveDailySession(company, normalBranch, now);
        saveDailySession(company, vaultBranch, now);
        saveDailySession(company, counterpartyBranch, now);

        cashBalanceRepository.flush();
        dailySessionRepository.flush();
        return new Seed(company, normalBranch, vaultBranch, counterpartyBranch);
    }

    private Branch seedBranch(
            Company company,
            String suffix,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime now,
            boolean isVault) {
        return branchRepository.save(Branch.builder()
                .code("FK058-B-" + suffix)
                .company(company)
                .bankCode("FK058BANK")
                .branchType(branchType)
                .name("FK-058 Branch " + suffix)
                .address("Test Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(isVault)
                .isActive(true)
                .openingDate(DAY)
                .createdAt(now)
                .build());
    }

    private void saveCashBalance(Company company, Branch branch, Currency huf, LocalDateTime now) {
        cashBalanceRepository.save(CashBalance.builder()
                .company(company)
                .branch(branch)
                .currency(huf)
                .currentBalance(new BigDecimal("100000.00"))
                .openingBalance(new BigDecimal("100000.00"))
                .createdAt(now)
                .build());
    }

    private void saveDailySession(Company company, Branch branch, LocalDateTime now) {
        dailySessionRepository.save(DailySession.builder()
                .company(company)
                .branch(branch)
                .sessionDate(DAY)
                .status(DailySessionStatus.OPEN)
                .openedAt(now)
                .openingBalanceHuf(new BigDecimal("100000.00"))
                .createdAt(now)
                .build());
    }

    private record Seed(
            Company company,
            Branch normalBranch,
            Branch vaultBranch,
            Branch counterpartyBranch) {}
}
